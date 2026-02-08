use std::sync::Arc;

use rayon::{
    iter::{IndexedParallelIterator, ParallelIterator},
    slice::ParallelSlice,
};

use crate::api::{
    traits::transform::SignalTransform,
    types::{
        audio::Audio,
        chart::{Chart, DataType, Point},
        config::Config,
        error::AppError,
    },
};

pub struct ZeroCrossingRateCalculator {}

impl SignalTransform for ZeroCrossingRateCalculator {
    fn transform(&self, data: Audio, config: Config) -> Result<Chart, AppError> {
        Ok(Chart {
            data_type: DataType::ZeroCrossingRate,
            points: Arc::new(
                data.data
                    .samples
                    .par_chunks(config.frame_size)
                    .enumerate()
                    .map(|(index, chunk)| {
                        let mut zero_crossings = 0;
                        for i in 1..chunk.len() {
                            if (chunk[i - 1] >= 0.0 && chunk[i] < 0.0)
                                || (chunk[i - 1] < 0.0 && chunk[i] >= 0.0)
                            {
                                zero_crossings += 1;
                            }
                        }
                        Point {
                            x: (index * config.frame_size) as f32,
                            y: zero_crossings as f32,
                        }
                    })
                    .collect::<Vec<Point>>(),
            ),
        })
    }
}
