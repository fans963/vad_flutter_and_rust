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
    position: AtomicU64,
    is_playing: AtomicBool,
    speed: AtomicU32, // fixed-point ×1000, 1000 = 1.0×
}

/// Commands sent from the engine to the player.
pub enum PlayerCommand {
    Play { start_sample: u64 },
    Pause,
    Stop,
    Seek { sample: u64 },
    SetSpeed { multiplier: f32 },
}

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

    pub fn position_fraction(&self) -> f64 {
        let state = match &self.state {
            Some(s) => s,
            None => return 0.0,
        };
        let total = state.samples.len() as u64;
        if total == 0 { return 0.0; }
        state.position.load(Ordering::Relaxed) as f64 / total as f64
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
        self.duration_secs() * self.position_fraction()
    }

    pub fn load(&mut self, audio: Audio) {
        self.stop();
        let sample_rate = audio.info.sample_rate;
        let channels = 1;
        let samples = audio.data.samples;
        self.state = Some(Arc::new(SharedState {
            samples,
            sample_rate,
            channels: channels as u16,
            position: AtomicU64::new(0),
            is_playing: AtomicBool::new(false),
            speed: AtomicU32::new(1000),
        }));
    }

    pub fn play(&mut self, start_sample: u64) {
        let state = match &self.state {
            Some(s) => s.clone(),
            None => return,
        };
        state.position.store(start_sample, Ordering::Relaxed);
        state.is_playing.store(true, Ordering::Relaxed);
        self.start_stream(state);
    }

    pub fn pause(&mut self) {
        if let Some(ref s) = self.state {
            s.is_playing.store(false, Ordering::Relaxed);
        }
        // Keep stream alive; it outputs silence when paused
    }

    pub fn stop(&mut self) {
        self.stream = None;
        if let Some(ref s) = self.state {
            s.is_playing.store(false, Ordering::Relaxed);
            s.position.store(0, Ordering::Relaxed);
        }
    }

    pub fn seek(&mut self, sample: u64) {
        if let Some(ref s) = self.state {
            s.position.store(sample, Ordering::Relaxed);
        }
    }

    pub fn set_speed(&mut self, multiplier: f32) {
        if let Some(ref s) = self.state {
            s.speed.store((multiplier * 1000.0) as u32, Ordering::Relaxed);
        }
    }

    fn start_stream(&mut self, state: Arc<SharedState>) {
        let host = cpal::default_host();
        let device = host.default_output_device().expect("no output device");
        let config = device.default_output_config().expect("no default config");
        let channels = state.channels as usize;

        // Resample if needed
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
            _ => panic!("unsupported sample format"),
        };

        match stream {
            Ok(s) => {
                s.play().ok();
                self.stream = Some(s);
            }
            Err(e) => log::error!("failed to build audio stream: {e}"),
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
    let speed = state.speed.load(Ordering::Relaxed) as f32 / 1000.0;
    let input_rate = state.sample_rate;
    let rate_ratio = input_rate as f64 / output_rate as f64 * speed as f64;

    let mut pos = state.position.load(Ordering::Relaxed);
    let playing = state.is_playing.load(Ordering::Relaxed);
    let total = samples.len();

    for frame in data.chunks_mut(channels) {
        let sample = if playing && (pos as usize) < total {
            let src_idx = (pos as f64 * rate_ratio) as usize;
            let val = samples.get(src_idx).copied().unwrap_or(0.0);
            pos += 1;
            val
        } else {
            0.0
        };
        for ch in frame.iter_mut() {
            *ch = T::from(sample);
        }
    }

    state.position.store(pos, Ordering::Relaxed);

    if playing && pos as usize >= total {
        state.is_playing.store(false, Ordering::Relaxed);
    }

    // Emit playback state every ~100ms (at ~44100Hz, every ~4410 samples)
    if pos % 4410 == 0 {
        let playing = state.is_playing.load(Ordering::Relaxed);
        let position = pos as f64 / state.sample_rate as f64;
        let duration = total as f64 / state.sample_rate as f64;
        emit_chart_event(ChartEvent::UpdatePlaybackState {
            is_playing: playing,
            position,
            duration,
        });
    }
}
