pub mod energy_vad;
pub mod zcr_vad;
pub mod silero_vad;

use crate::api::traits::vad_algorithm::VadAlgorithm;
use crate::api::types::vad::{VadParamDef, VadResult};
use energy_vad::EnergyVad;
use zcr_vad::ZeroCrossingRateVad;
use silero_vad::SileroVad;

type VadBox = Box<dyn VadAlgorithm + Send>;

pub struct VadEngine {
    inner: VadBox,
}

impl VadEngine {
    pub fn new(name: &str) -> Self {
        Self {
            inner: Self::create(name),
        }
    }

    fn create(name: &str) -> VadBox {
        match name {
            "energy" => Box::new(EnergyVad::default()),
            "zcr" => Box::new(ZeroCrossingRateVad::default()),
            "silero" => Box::new(SileroVad::default()),
            _ => Box::new(EnergyVad::default()),
        }
    }

    pub fn list_algorithms(&self) -> Vec<String> {
        vec!["energy".into(), "zcr".into(), "silero".into()]
    }

    pub fn current_name(&self) -> String {
        self.inner.name().to_string()
    }

    pub fn set_algorithm(&mut self, name: &str) {
        self.inner = Self::create(name);
    }

    pub fn get_parameters(&self) -> Vec<VadParamDef> {
        self.inner.get_parameters()
    }

    pub fn set_parameter(&mut self, key: &str, value: f32) {
        self.inner.update_parameter(key, value);
    }

    pub fn process(&self, samples: &[f32], sample_rate: u32) -> VadResult {
        self.inner.process(samples, sample_rate)
    }
}
