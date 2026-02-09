use std::sync::{Arc, atomic::AtomicBool};

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
    util::get_min_max::get_min_max_par,
};

pub struct EnergyCalculator {}

impl SignalTransform for EnergyCalculator {
    async fn transform(&self, data: Audio, config: Config) -> Result<Chart, AppError> {
        let points = data
            .data
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
            .collect::<Vec<Point>>();

        let (min_y, max_y) = get_min_max_par(&points).await;
        Ok(Chart {
            data_type: DataType::Energy,
            points: Arc::new(points),
            min_y,
            max_y,
            visible: Arc::new(AtomicBool::new(true)),
        })
    }
}
