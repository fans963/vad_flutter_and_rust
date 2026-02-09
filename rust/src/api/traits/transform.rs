use crate::api::types::{audio::Audio, chart::Chart, config::Config, error::AppError};

pub trait SignalTransform {
    async  fn transform(&self, data: Audio, config: Config) -> Result<Chart, AppError>;
}
