use std::sync::Arc;

use crate::api::{
    traits::transform::SignalTransform,
    types::{
        audio::Audio,
        chart::{Chart, DataType},
        config::Config,
        error::AppError,
    },
};

pub struct FftTransform {
    planner: rustfft::FftPlanner<f32>,
}

impl SignalTransform for FftTransform {
    fn transform(&self, data: Audio, config: Config) -> Result<Chart, AppError> {
        // Implement FFT transformation logic here
        Ok(Chart {
            data_type: DataType::Spectrum,
            points: Arc::new(vec![]),
        })
    }
}
