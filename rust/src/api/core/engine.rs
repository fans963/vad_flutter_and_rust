use std::sync::Arc;

use rayon::iter::{IndexedParallelIterator, IntoParallelRefIterator, ParallelIterator};

use crate::api::{
    decoder::symphonia_decoder::SymphoniaDecoder,
    sampling::minmax::Minmax,
    storage::{kv_audio_storage::KvAudioStorage, kv_cached_chart_storage::KvCachedChartStorage},
    traits::{
        audio_decoder::AudioDecoder, audio_storage::AudioStorage,
        cached_chart_storage::CachedChartStorage, down_sample::DownSample,
    },
    types::{
        chart::{Chart, DataType, Point},
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
    down_sample_points_num: usize,
    index_range: (f32, f32),
}

impl AudioProcessorEngine {
    pub fn new(
        config: Config,
        decoder: Box<dyn AudioDecoder + Send + Sync>,
        storage: Box<dyn AudioStorage + Send + Sync>,
        cache: Box<dyn CachedChartStorage + Send + Sync>,
    ) -> Self {
        Self {
            config,
            decoder,
            storage,
            cache,
            down_sample_points_num: 500,
            index_range: (0.0, 0.0),
        }
    }

    pub fn set_down_sample_points_num(&mut self, points_num: usize) {
        self.down_sample_points_num = points_num;
    }

    pub fn set_index_range(&mut self, start: f32, end: f32) {
        self.index_range = (start, end);
    }

    pub fn add(&self, file_path: String, audio_data: Vec<u8>) -> Result<(), AppError> {
        let format = (SimpleFormatGetter {}).get_format(file_path.clone())?;
        let decoded_audio = self.decoder.decode(format, audio_data)?;

        self.storage
            .save(file_path.clone(), decoded_audio.clone())?;

        let points: Vec<Point> = decoded_audio
            .data
            .samples
            .par_iter()
            .enumerate()
            .map(|(i, &sample)| Point {
                x: i as f32,
                y: sample,
            })
            .collect();

        let audio_chart = Chart {
            data_type: DataType::Audio,
            points: Arc::new(points),
        };

        // Using Minmax downsampler to reduce points for UI performance
        let minmax = Minmax {};
        let downsampled_chart = minmax.down_sample(audio_chart, self.down_sample_points_num);

        self.cache.add(file_path, downsampled_chart)?;
        Ok(())
    }

    pub fn remove_audio(&self, file_path: String) -> Result<(), AppError> {
        self.storage.remove(file_path)
    }

    pub fn remove_chart(&self, file_path: String, data_type: DataType) -> Result<(), AppError> {
        self.cache.remove(file_path, data_type)
    }
}

pub fn create_default_engine(config: Config) -> AudioProcessorEngine {
    AudioProcessorEngine::new(
        config,
        Box::new(SymphoniaDecoder::new()),
        Box::new(KvAudioStorage::new()),
        Box::new(KvCachedChartStorage::new()),
    )
}
