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

pub struct ZeroCrossingRateCalculator {}

impl SignalTransform for ZeroCrossingRateCalculator {
    async fn transform(&self, data: Audio, config: Config) -> Result<Chart, AppError> {
        let points = data
            .data
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
            .collect::<Vec<Point>>();

        let (min_y, max_y) = get_min_max_par(&points).await;
        Ok(Chart {
            data_type: DataType::ZeroCrossingRate,
            points: Arc::new(points),
            min_y,
            max_y,
            visible: Arc::new(AtomicBool::new(true)),
        })
    }
}
