use std::sync::atomic;

use log::info;
use rayon::iter::{IntoParallelRefIterator, ParallelIterator};

use crate::api::{
    communicator,
    decoder::symphonia_decoder::SymphoniaDecoder,
    sampling::minmax::{self, Minmax},
    storage::{kv_audio_storage::KvAudioStorage, kv_cached_chart_storage::KvCachedChartStorage},
    traits::{
        audio_decoder::AudioDecoder, audio_storage::AudioStorage,
        cached_chart_storage::CachedChartStorage, communicator::Communicator,
        down_sample::DownSample, transform::SignalTransform,
    },
    transform::{
        energy::EnergyCalculator, fft::FftTransform, zero_crossing_rate::ZeroCrossingRateCalculator,
    },
    types::{
        chart::{Chart, ChartWIthKey, DataType},
        config::Config,
        error::AppError,
    },
};

pub struct AudioProcessorEngine {
    config: Config,
    decoder: Box<dyn AudioDecoder + Send + Sync>,
    storage: Box<dyn AudioStorage + Send + Sync>,
    cache: Box<dyn CachedChartStorage + Send + Sync>,
    communicator: Box<dyn Communicator + Send + Sync>,
    down_sample_points_num: usize,
    index_range: (f32, f32),
    selected_audio: Option<String>,
    max_index: f32,
    y_range: (f32, f32),
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
            selected_audio: None,
            max_index: 10000.0,
            y_range: (-0.5, 0.5),
        }
    }

    fn update_all(&mut self) {
        let all_charts = self.cache.get_all_cache();
        self.y_range = (-0.5, 0.5);
        self.max_index = 10000.0;
        if let Ok(charts) = all_charts {
            let visible_charts: Vec<ChartWIthKey> = charts
                .iter()
                .map(|c| {
                    if c.chart.visible.load(atomic::Ordering::Relaxed) {
                        self.y_range = (
                            self.y_range.0.min(c.chart.min_y),
                            self.y_range.1.max(c.chart.max_y),
                        );

                        self.update_max_index(&c.chart);
                    }
                    let visible_chart = c.chart.get_range(self.index_range.0, self.index_range.1);
                    let downsampled_chart =
                        Minmax {}.down_sample(visible_chart, self.down_sample_points_num);
                    ChartWIthKey {
                        key: c.key.clone(),
                        chart: downsampled_chart,
                    }
                })
                .collect();

            self.communicator.update_all_charts(visible_charts);
            self.communicator
                .update_max_index(self.max_index);
            self.communicator
                .update_y_range(self.y_range.0, self.y_range.1);
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

        let audio_chart = decoded_audio.audio_to_chart().await;
        self.y_range = (
            self.y_range.0.min(audio_chart.min_y),
            self.y_range.1.max(audio_chart.max_y),
        );
        self.update_max_index(&audio_chart);
        self.communicator
            .update_max_index(self.max_index);
        self.communicator
            .update_y_range(self.y_range.0, self.y_range.1);

        self.cache.add(file_path.clone(), audio_chart.clone())?;

        let visible_chart = audio_chart.get_range(self.index_range.0, self.index_range.1);

        let downsampled_chart = Minmax {}.down_sample(visible_chart, self.down_sample_points_num);
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
                DataType::Audio => stored_audio.audio_to_chart().await,
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
            };
            self.cache.add(file_path.clone(), chart.clone())?;
            info!("{:?} data length: {}", data_type, chart.points.len());
            chart
        };
        self.update_max_index(&target_chart);
        self.communicator
            .update_max_index(self.max_index);
        self.communicator
            .update_y_range(self.y_range.0, self.y_range.1);
        let visible_chart = target_chart.get_range(self.index_range.0, self.index_range.1);

        let downsampled_chart = Minmax {}.down_sample(visible_chart, self.down_sample_points_num);
        self.communicator.add_chart(file_path, downsampled_chart);
        Ok(())
    }

    pub async fn remove_chart(
        &self,
        file_path: String,
        data_type: DataType,
    ) -> Result<(), AppError> {
        self.cache.remove(file_path, data_type)
    }

    pub async fn set_selected_audio(&mut self, chart_name: Option<String>) {
        self.selected_audio = chart_name;
    }

    fn update_max_index(&mut self, chart: &Chart) {
        chart.points.last().map(|p| {
            if p.x > self.max_index {
                self.max_index =
                    (p.x / self.config.frame_size as f32).ceil() * self.config.frame_size as f32;
            }
        });
    }

    pub async fn reserve_visible(&mut self, chart_name: String) -> Result<(), AppError> {
        let (file_path, data_part) = chart_name.rsplit_once(' ').unwrap_or(("", &chart_name));

        let data_type = match data_part {
            "audio" => DataType::Audio,
            "spectrum" => DataType::Spectrum,
            "energy" => DataType::Energy,
            "zeroCrossingRate" => DataType::ZeroCrossingRate,
            _ => return Err(AppError::InvalidChartName(chart_name)),
        };

        let chart = self.cache.get(file_path.to_string(), data_type)?;
        chart.visible.store(
            !chart.visible.load(atomic::Ordering::Relaxed),
            atomic::Ordering::Relaxed,
        );
        info!(
            "Set visible: {}, {}, {}",
            file_path,
            data_part,
            chart.visible.load(atomic::Ordering::Relaxed)
        );
        self.update_all();
        Ok(())
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
