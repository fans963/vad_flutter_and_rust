use crate::api::types::{audio::Audio, chart::Chart, config::Config, error::AppError};

pub trait SignalTransform {
    fn transform(&self, data: Audio, config: Config) -> impl std::future::Future<Output = Result<Chart, AppError>> + Send;
}
