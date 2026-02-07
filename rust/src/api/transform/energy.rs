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

pub struct EnergyCalculator {}

impl SignalTransform for EnergyCalculator {
    fn transform(&self, data: Audio, config: Config) -> Result<Chart, AppError> {
        Ok(Chart {
            data_type: DataType::Energy,
            points: Arc::new(
                data.data
                    .samples
                    .par_chunks(config.frame_size)
                    .enumerate()
                    .map(|(index, chunk)| {
                        let energy: f32 = chunk.iter().map(|&sample| sample * sample).sum();
                        Point {
                            x: (index * config.frame_size) as f32,
                            y: energy,
                        }
                    })
                    .collect::<Vec<Point>>(),
            ),
        })
    }
}
