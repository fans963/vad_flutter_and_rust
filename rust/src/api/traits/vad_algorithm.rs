use crate::api::types::vad::{VadParamDef, VadResult};

/// Abstraction for pluggable Voice Activity Detection algorithms.
/// Each implementation defines its own tunable parameters and processing logic.
pub trait VadAlgorithm: Send + Sync {
    /// Unique short name (e.g. "energy", "zcr").
    fn name(&self) -> &'static str;

    /// Human-readable display name (e.g. "Energy-based VAD").
    fn display_name(&self) -> &'static str;

    /// Returns the current parameters with their metadata (min/max/step).
    fn get_parameters(&self) -> Vec<VadParamDef>;

    /// Updates one parameter by key. Value is f32 for simplicity
    /// (bool params: 0.0/1.0, int params cast from f32).
    fn update_parameter(&mut self, key: &str, value: f32);

    /// Run VAD on raw PCM samples, returning per-frame confidence scores.
    fn process(&self, samples: &[f32], sample_rate: u32) -> VadResult;
}
