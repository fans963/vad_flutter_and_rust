use crate::api::traits::transform::SignalTransform;

pub struct ZeroCrossingRateCalculator {}

impl SignalTransform for ZeroCrossingRateCalculator {
    fn transform(
        &self,
        data: crate::api::types::audio::Audio,
        _config: crate::api::types::config::Config,
    ) -> Result<crate::api::types::chart::Chart, crate::api::types::error::AppError> {
        todo!()
    }
}
