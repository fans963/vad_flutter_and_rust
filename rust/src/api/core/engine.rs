use std::sync::Arc;

use log::info;

use crate::api::{
    communicator,
    decoder::symphonia_decoder::SymphoniaDecoder,
    player::{Player, PlaybackState},
    sampling::minmax::minmax_downsample,
    storage::{kv_audio_storage::KvAudioStorage, kv_cached_chart_storage::KvCachedChartStorage},
    traits::{
        audio_decoder::AudioDecoder, audio_storage::AudioStorage,
        cached_chart_storage::CachedChartStorage, communicator::Communicator,
        transform::SignalTransform,
    },
    transform::{
        energy::EnergyCalculator, fft::FftTransform, zero_crossing_rate::ZeroCrossingRateCalculator,
    },
    types::{
        chart::{Chart, DataType, Point},
        config::Config,
        error::AppError,
        vad::{VadParamDef, VadResult},
    },
    vad::VadEngine,
};

pub struct AudioProcessorEngine {
    config: Config,
    decoder: Box<dyn AudioDecoder + Send + Sync>,
    storage: Box<dyn AudioStorage + Send + Sync>,
    cache: Box<dyn CachedChartStorage + Send + Sync>,
    communicator: Box<dyn Communicator + Send + Sync>,
    down_sample_points_num: usize,
    index_range: (f32, f32),
    max_index: f32,
    y_range: (f32, f32),
    player: Player,
    vad: VadEngine,
}

impl AudioProcessorEngine {
    pub fn new(
        config: Config,
        decoder: Box<dyn AudioDecoder + Send + Sync>,
        storage: Box<dyn AudioStorage + Send + Sync>,
        cache: Box<dyn CachedChartStorage + Send + Sync>,
        communicator: Box<dyn Communicator + Send + Sync>,
    ) -> Self {
        Self {
            config,
            decoder,
            storage,
            cache,
            communicator,
            down_sample_points_num: 500,
            index_range: (0.0, 0.0),
            max_index: 10000.0,
            y_range: (-0.5, 0.5),
            player: Player::new(),
            vad: VadEngine::new("energy"),
        }
    }

    fn recompute_ranges(&mut self) {
        if let Ok(charts) = self.cache.get_all_cache() {
            let mut y_min = f32::MAX;
            let mut y_max = f32::MIN;
            let mut max_idx = 0.0f32;

            for (_, c) in &charts {
                if !c.visible {
                    continue;
                }
                y_min = y_min.min(c.min_y);
                y_max = y_max.max(c.max_y);
                if let Some(last) = c.points.last() {
                    max_idx = max_idx.max(last.x);
                }
            }

            if y_min <= y_max {
                self.y_range = (y_min, y_max);
                self.max_index = (max_idx / self.config.frame_size as f32).ceil()
                    * self.config.frame_size as f32;
            }
        }
    }

    fn update_all(&mut self) {
        self.recompute_ranges();
        self.communicator.update_max_index(self.max_index);
        self.communicator
            .update_y_range(self.y_range.0, self.y_range.1);

        let all_charts = self.cache.get_all_cache();
        if let Ok(charts) = all_charts {
            let visible_charts: Vec<_> = charts
                .iter()
                .filter(|(_, c)| c.visible)
                .map(|(key, c)| {
                    let visible_chart = c.get_range(self.index_range.0, self.index_range.1);
                    let downsampled = minmax_downsample(visible_chart, self.down_sample_points_num);
                    (key.clone(), downsampled)
                })
                .collect();

            if !visible_charts.is_empty() {
                self.communicator.update_all_charts(visible_charts);
            }
        }
    }

    pub async fn set_down_sample_points_num(&mut self, points_num: usize) {
        self.down_sample_points_num = points_num;
        self.update_all();
    }

    pub async fn set_index_range(&mut self, start: f32, end: f32) {
        self.index_range = (start, end);
        self.update_all();
    }

    pub async fn set_config(&mut self, config: Config) {
        self.config = config;
        self.update_all();
    }

    pub async fn add(
        &mut self,
        file_path: String,
        format: String,
        audio_data: Vec<u8>,
    ) -> Result<(), AppError> {
        info!("Adding audio file: {}, format: {}", file_path, format);
        let decoded_audio = self.decoder.decode(format, audio_data)?;

        self.storage
            .save(file_path.clone(), decoded_audio.clone())?;

        let audio_chart = decoded_audio.audio_to_chart();
        self.cache.add(file_path.clone(), audio_chart.clone())?;

        self.recompute_ranges();
        self.communicator.update_max_index(self.max_index);
        self.communicator
            .update_y_range(self.y_range.0, self.y_range.1);

        let visible_chart = audio_chart.get_range(self.index_range.0, self.index_range.1);
        let downsampled_chart = minmax_downsample(visible_chart, self.down_sample_points_num);
        self.communicator.add_chart(file_path, downsampled_chart);
        Ok(())
    }

    pub async fn remove_audio(&self, file_path: String) -> Result<(), AppError> {
        self.storage.remove(file_path)
    }

    pub async fn add_chart(
        &mut self,
        file_path: String,
        data_type: DataType,
    ) -> Result<(), AppError> {
        let target_chart = if let Ok(cached_data) = self.cache.get(file_path.clone(), data_type) {
            cached_data
        } else {
            let stored_audio = self.storage.load(file_path.clone())?;
            let chart = match data_type {
                DataType::Audio => stored_audio.audio_to_chart(),
                DataType::Spectrum => {
                    (FftTransform {})
                        .transform(stored_audio, self.config.clone())
                        .await?
                }
                DataType::Energy => {
                    (EnergyCalculator {})
                        .transform(stored_audio, self.config.clone())
                        .await?
                }
                DataType::ZeroCrossingRate => {
                    (ZeroCrossingRateCalculator {})
                        .transform(stored_audio, self.config.clone())
                        .await?
                }
                DataType::Vad => {
                    let result = self.vad.process(&stored_audio.data.samples, stored_audio.info.sample_rate);
                    let points: Vec<Point> = result.confidence.iter().enumerate()
                        .map(|(i, &c)| Point { x: (i * result.frame_size as usize) as f32, y: c })
                        .collect();
                    let (min_y, max_y) = crate::api::util::get_min_max::get_min_max_par(&points);
                    Chart {
                        data_type: DataType::Vad,
                        points: Arc::new(points),
                        min_y,
                        max_y,
                        visible: true,
                    }
                }
            };
            self.cache.add(file_path.clone(), chart.clone())?;
            info!("{:?} data length: {}", data_type, chart.points.len());
            chart
        };

        self.recompute_ranges();
        self.communicator.update_max_index(self.max_index);
        self.communicator
            .update_y_range(self.y_range.0, self.y_range.1);

        let visible_chart = target_chart.get_range(self.index_range.0, self.index_range.1);

        let downsampled_chart = minmax_downsample(visible_chart, self.down_sample_points_num);
        self.communicator.add_chart(file_path, downsampled_chart);
        Ok(())
    }

    pub async fn remove_chart(
        &mut self,
        file_path: String,
        data_type: DataType,
    ) -> Result<(), AppError> {
        self.cache.remove(file_path.clone(), data_type)?;
        self.communicator
            .remove_chart(file_path, data_type);
        self.recompute_ranges();
        self.communicator.update_max_index(self.max_index);
        self.communicator
            .update_y_range(self.y_range.0, self.y_range.1);
        Ok(())
    }

    pub async fn list_vad_algorithms(&self) -> Vec<String> {
        self.vad.list_algorithms()
    }

    pub async fn get_current_vad_name(&self) -> String {
        self.vad.current_name()
    }

    pub async fn set_vad_algorithm(&mut self, name: String) {
        self.vad.set_algorithm(&name);
    }

    pub async fn get_vad_params(&self) -> Vec<VadParamDef> {
        self.vad.get_parameters()
    }

    pub async fn set_vad_param(&mut self, key: String, value: f64) {
        self.vad.set_parameter(&key, value as f32);
    }

    pub async fn compute_vad(&mut self, file_path: String) -> Result<VadResult, AppError> {
        let stored = self.storage.load(file_path)?;
        Ok(self.vad.process(&stored.data.samples, stored.info.sample_rate))
    }

    pub async fn play_audio(&mut self, file_path: String, start_fraction: f64) -> Result<(), String> {
        if let Ok(audio) = self.storage.load(file_path) {
            let total = audio.data.samples.len() as u64;
            let start = ((total as f64 * start_fraction) as u64).min(total);
            self.player.load(audio);
            self.player.play(start)?;
        }
        Ok(())
    }

    pub async fn resume_audio(&mut self) -> Result<(), String> {
        self.player.resume()
    }

    pub async fn pause_audio(&mut self) { self.player.pause(); }
    pub async fn stop_audio(&mut self) { self.player.stop(); }

    pub async fn seek_audio(&mut self, fraction: f64) {
        if let Some(total) = self.player.total_samples() {
            self.player.seek(((total as f64 * fraction) as u64).min(total));
        }
    }

    pub async fn set_playback_speed(&mut self, multiplier: f32) {
        self.player.set_speed(multiplier);
    }

    pub async fn is_audio_loaded(&self) -> bool {
        self.player.is_loaded()
    }

    pub async fn get_playback_state(&self) -> PlaybackState {
        PlaybackState {
            is_playing: self.player.is_playing(),
            position: self.player.position_secs(),
            duration: self.player.duration_secs(),
        }
    }
}

pub async fn create_default_engine(config: Config) -> AudioProcessorEngine {
    AudioProcessorEngine::new(
        config,
        Box::new(SymphoniaDecoder::new()),
        Box::new(KvAudioStorage::new()),
        Box::new(KvCachedChartStorage::new()),
        Box::new(communicator::stream_sink_communicator::StreamCommunicator::new()),
    )
}
