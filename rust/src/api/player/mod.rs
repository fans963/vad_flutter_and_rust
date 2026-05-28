use std::sync::atomic::{AtomicBool, AtomicU32, AtomicU64, Ordering};
use std::sync::Arc;

use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};

use crate::api::types::audio::Audio;
use crate::api::types::events::ChartEvent;
use crate::api::events::communicator_events::emit_chart_event;

#[derive(Clone, Debug)]
#[frb]
pub struct PlaybackState {
    pub is_playing: bool,
    pub position: f64,
    pub duration: f64,
}

/// Player state shared with the audio callback thread.
struct SharedState {
    samples: Arc<Vec<f32>>,
    sample_rate: u32,
    channels: u16,
    /// Current position in source samples, fixed-point x1024 for sub-sample accuracy.
    position: AtomicU64,
    is_playing: AtomicBool,
    speed: AtomicU32, // fixed-point x1000, 1000 = 1.0x
}

/// Fixed-point multiplier for source position (provides sub-sample accuracy).
const POS_FRAC: u64 = 1024;

use flutter_rust_bridge::frb;

#[frb(opaque)]
pub struct Player {
    state: Option<Arc<SharedState>>,
    stream: Option<cpal::Stream>,
}

impl Player {
    pub fn new() -> Self {
        Self { state: None, stream: None }
    }

    pub fn is_playing(&self) -> bool {
        self.state.as_ref().map_or(false, |s| s.is_playing.load(Ordering::Relaxed))
    }

    pub fn is_loaded(&self) -> bool {
        self.state.is_some()
    }

    pub fn position_fraction(&self) -> f64 {
        let state = match &self.state {
            Some(s) => s,
            None => return 0.0,
        };
        let total = state.samples.len() as u64;
        if total == 0 { return 0.0; }
        let pos_fp = state.position.load(Ordering::Relaxed);
        let pos = (pos_fp / POS_FRAC).min(total);
        pos as f64 / total as f64
    }

    pub fn duration_secs(&self) -> f64 {
        let state = match &self.state {
            Some(s) => s,
            None => return 0.0,
        };
        state.samples.len() as f64 / state.sample_rate as f64
    }

    pub fn total_samples(&self) -> Option<u64> {
        self.state.as_ref().map(|s| s.samples.len() as u64)
    }

    pub fn position_secs(&self) -> f64 {
        let state = match &self.state {
            Some(s) => s,
            None => return 0.0,
        };
        let pos_fp = state.position.load(Ordering::Relaxed);
        let pos = (pos_fp / POS_FRAC) as f64;
        pos / state.sample_rate as f64
    }

    /// Load audio data for playback. Stops any current playback first.
    pub fn load(&mut self, audio: Audio) {
        self.stop();
        let sample_rate = audio.info.sample_rate;
        let channels = 1u16;
        let samples = audio.data.samples;
        self.state = Some(Arc::new(SharedState {
            samples,
            sample_rate,
            channels,
            position: AtomicU64::new(0),
            is_playing: AtomicBool::new(false),
            speed: AtomicU32::new(1000),
        }));
    }

    /// Start playback from a specific source sample position.
    /// Creates a new output stream.
    pub fn play(&mut self, start_sample: u64) -> Result<(), String> {
        let state = match &self.state {
            Some(s) => s.clone(),
            None => return Ok(()),
        };
        let total = state.samples.len() as u64;
        let start = start_sample.min(total);
        state.position.store(start * POS_FRAC, Ordering::Relaxed);
        state.is_playing.store(true, Ordering::Relaxed);
        self.start_stream(state)
    }

    /// Resume playback from current position without reloading.
    /// If no stream exists, creates one.
    pub fn resume(&mut self) -> Result<(), String> {
        let state = match &self.state {
            Some(s) => s.clone(),
            None => return Ok(()),
        };
        state.is_playing.store(true, Ordering::Relaxed);
        if self.stream.is_none() {
            self.start_stream(state)?;
        }
        Ok(())
    }

    /// Pause playback. Keeps the stream alive (outputs silence).
    pub fn pause(&mut self) {
        if let Some(ref s) = self.state {
            s.is_playing.store(false, Ordering::Relaxed);
        }
    }

    /// Stop playback and reset position to 0.
    pub fn stop(&mut self) {
        self.stream = None;
        if let Some(ref s) = self.state {
            s.is_playing.store(false, Ordering::Relaxed);
            s.position.store(0, Ordering::Relaxed);
        }
    }

    /// Seek to a specific source sample position.
    pub fn seek(&mut self, sample: u64) {
        if let Some(ref s) = self.state {
            let total = s.samples.len() as u64;
            s.position.store(sample.min(total) * POS_FRAC, Ordering::Relaxed);
        }
    }

    /// Set playback speed multiplier (1.0 = normal, 2.0 = double speed).
    pub fn set_speed(&mut self, multiplier: f32) {
        if let Some(ref s) = self.state {
            s.speed.store((multiplier * 1000.0) as u32, Ordering::Relaxed);
        }
    }

    fn start_stream(&mut self, state: Arc<SharedState>) -> Result<(), String> {
        let host = cpal::default_host();
        let device = host.default_output_device().ok_or("no output device")?;
        let config = device.default_output_config().map_err(|e| format!("no default config: {e}"))?;
        let channels = state.channels as usize;

        let stream_config: cpal::StreamConfig = config.clone().into();
        let stream_rate = stream_config.sample_rate;

        let stream = match config.sample_format() {
            cpal::SampleFormat::F32 => {
                device.build_output_stream(
                    &stream_config,
                    move |data: &mut [f32], _: &cpal::OutputCallbackInfo| {
                        fill_buffer::<f32>(&state, data, channels, stream_rate);
                    },
                    |err| log::error!("audio stream error: {err}"),
                    None,
                )
            }
            _ => return Err("unsupported sample format".into()),
        };

        match stream {
            Ok(s) => {
                s.play().ok();
                self.stream = Some(s);
                Ok(())
            }
            Err(e) => Err(format!("failed to build audio stream: {e}")),
        }
    }
}

fn fill_buffer<T: cpal::Sample + From<f32>>(
    state: &SharedState,
    data: &mut [T],
    channels: usize,
    output_rate: u32,
) {
    let samples = &state.samples;
    let speed = state.speed.load(Ordering::Relaxed) as f64 / 1000.0;
    let input_rate = state.sample_rate as f64;
    let output_rate = output_rate as f64;

    // Source samples to advance per output frame (fixed-point).
    let advance_fp = (input_rate / output_rate * speed * POS_FRAC as f64) as u64;

    let mut src_pos_fp = state.position.load(Ordering::Relaxed);
    let playing = state.is_playing.load(Ordering::Relaxed);
    let total = samples.len() as u64;
    let total_fp = total * POS_FRAC;

    let mut reached_end = false;
    let frames_out = data.len() / channels;

    for frame in data.chunks_mut(channels) {
        let sample = if playing && src_pos_fp < total_fp {
            let src_idx = (src_pos_fp / POS_FRAC) as usize;
            let val = samples.get(src_idx).copied().unwrap_or(0.0);
            src_pos_fp += advance_fp;
            val
        } else {
            if playing && src_pos_fp >= total_fp {
                reached_end = true;
            }
            0.0
        };
        for ch in frame.iter_mut() {
            *ch = T::from(sample);
        }
    }

    state.position.store(src_pos_fp, Ordering::Relaxed);

    if reached_end {
        state.position.store(total_fp, Ordering::Relaxed);
        state.is_playing.store(false, Ordering::Relaxed);
    }

    // Emit playback state based on position change (~100ms of source audio).
    let pos_samples = (src_pos_fp / POS_FRAC).min(total);
    let emit_interval = (input_rate * 0.1) as u64;
    let frames_out = frames_out as u64;
    let prev_pos = pos_samples.saturating_sub(
        ((advance_fp * frames_out) / POS_FRAC).max(1),
    );
    if emit_interval > 0 && (pos_samples / emit_interval) != (prev_pos / emit_interval) {
        let playing = state.is_playing.load(Ordering::Relaxed);
        let position = pos_samples as f64 / input_rate;
        let duration = total as f64 / input_rate;
        emit_chart_event(ChartEvent::UpdatePlaybackState {
            is_playing: playing,
            position,
            duration,
        });
    }
}
