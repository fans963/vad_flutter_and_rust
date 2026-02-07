use std::sync::Arc;

use env_logger::Target;
use log::info;
use rayon::iter::{IndexedParallelIterator, IntoParallelRefIterator, ParallelIterator};

use crate::api::{
    communicator,
    decoder::symphonia_decoder::SymphoniaDecoder,
    sampling::{equal_step::EqualStep, minmax::Minmax},
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
        chart::{Chart, ChartWIthKey, CommunicatorChart, DataType, Point},
        config::Config,
        error::AppError,
    },
    util::format_getter::{FormatGetter, SimpleFormatGetter},
};

pub struct AudioProcessorEngine {
    config: Config,
    decoder: Box<dyn AudioDecoder + Send + Sync>,
    storage: Box<dyn AudioStorage + Send + Sync>,
    cache: Box<dyn CachedChartStorage + Send + Sync>,
    down_sampler: Box<dyn DownSample + Send + Sync>,
    communicator: Box<dyn Communicator + Send + Sync>,
    down_sample_points_num: usize,
    index_range: (f32, f32),
    selected_audio: Option<String>,
}

impl AudioProcessorEngine {
    pub fn new(
        config: Config,
        decoder: Box<dyn AudioDecoder + Send + Sync>,
        storage: Box<dyn AudioStorage + Send + Sync>,
        cache: Box<dyn CachedChartStorage + Send + Sync>,
        down_sampler: Box<dyn DownSample + Send + Sync>,
        communicator: Box<dyn Communicator + Send + Sync>,
    ) -> Self {
        Self {
            config,
            decoder,
            storage,
            cache,
            down_sampler,
            communicator,
            down_sample_points_num: 500,
            index_range: (0.0, 0.0),
            selected_audio: None,
        }
    }

    fn update_all(&mut self) {
        let all_charts = self.cache.get_all_cache();

        if let Ok(charts) = all_charts {
            let visable_charts: Vec<ChartWIthKey> = charts
                .par_iter()
                .map(|c| {
                    let visable_chart = c.chart.get_range(self.index_range.0, self.index_range.1);
                    let downsampled_chart = self
                        .down_sampler
                        .down_sample(visable_chart, self.down_sample_points_num);
                    ChartWIthKey {
                        key: c.key.clone(),
                        chart: downsampled_chart,
                    }
                })
                .collect();

            self.communicator.update_all_charts(visable_charts);
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

    pub async fn add(&self, file_path: String, audio_data: Vec<u8>) -> Result<(), AppError> {
        info!("Adding audio file: {}", file_path);
        let format = (SimpleFormatGetter {}).get_format(file_path.clone())?;
        let decoded_audio = self.decoder.decode(format, audio_data)?;

        self.storage
            .save(file_path.clone(), decoded_audio.clone())?;

        let audio_chart = decoded_audio.audio_to_chart();

        self.cache.add(file_path.clone(), audio_chart.clone())?;

        let visible_chart = audio_chart.get_range(self.index_range.0, self.index_range.1);

        let downsampled_chart = self
            .down_sampler
            .down_sample(visible_chart, self.down_sample_points_num);
        self.communicator.add_chart(file_path, downsampled_chart);
        Ok(())
    }

    pub async fn remove_audio(&self, file_path: String) -> Result<(), AppError> {
        self.storage.remove(file_path)
    }

    pub async fn add_chart(&self, file_path: String, data_type: DataType) -> Result<(), AppError> {
        let target_chart = if let Ok(cached_data) = self.cache.get(file_path.clone(), data_type) {
            cached_data
        } else {
            let stored_audio = self.storage.load(file_path.clone())?;
            let chart = match data_type {
                DataType::Audio => stored_audio.audio_to_chart(),
                DataType::Spectrum => {
                    (FftTransform {}).transform(stored_audio, self.config.clone())?
                }
                DataType::Energy => {
                    (EnergyCalculator {}).transform(stored_audio, self.config.clone())?
                }
                DataType::ZeroCrossingRate => {
                    (ZeroCrossingRateCalculator {}).transform(stored_audio, self.config.clone())?
                }
            };
            self.cache.add(file_path.clone(), chart.clone())?;
            info!("{:?} data length: {}", data_type, chart.points.len());
            chart
        };

        let visible_chart = target_chart.get_range(self.index_range.0, self.index_range.1);

        let downsampled_chart = self
            .down_sampler
            .down_sample(visible_chart, self.down_sample_points_num);
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

    pub async fn set_selected_audio(&mut self, file_path: Option<String>) {
        self.selected_audio = file_path;
    }
}

pub async fn create_default_engine(config: Config) -> AudioProcessorEngine {
    AudioProcessorEngine::new(
        config,
        Box::new(SymphoniaDecoder::new()),
        Box::new(KvAudioStorage::new()),
        Box::new(KvCachedChartStorage::new()),
        Box::new(Minmax {}),
        Box::new(communicator::stream_sink_communicator::StreamCommunicator::new()),
    )
}
