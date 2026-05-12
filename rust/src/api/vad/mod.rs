pub mod energy_vad;
pub mod zcr_vad;

use std::sync::{Mutex, OnceLock};

use crate::api::traits::vad_algorithm::VadAlgorithm;
use energy_vad::EnergyVad;
use zcr_vad::ZeroCrossingRateVad;

type VadBox = Box<dyn VadAlgorithm + Send>;

static VAD_INSTANCE: OnceLock<Mutex<VadBox>> = OnceLock::new();

fn vad_lock() -> &'static Mutex<VadBox> {
    VAD_INSTANCE.get_or_init(|| Mutex::new(Box::new(EnergyVad::default())))
}

pub fn list_algorithm_names() -> Vec<String> {
    vec!["energy".into(), "zcr".into()]
}

pub fn current_algorithm_name() -> String {
    vad_lock().lock().unwrap().name().to_string()
}

pub fn set_algorithm(name: &str) {
    if let Some(algo) = create_vad(name) {
        *vad_lock().lock().unwrap() = algo;
    }
}

pub fn get_parameters() -> Vec<crate::api::types::vad::VadParamDef> {
    vad_lock().lock().unwrap().get_parameters()
}

pub fn set_parameter(key: &str, value: f32) {
    vad_lock().lock().unwrap().update_parameter(key, value);
}

pub fn process(samples: &[f32], sample_rate: u32) -> crate::api::types::vad::VadResult {
    vad_lock().lock().unwrap().process(samples, sample_rate)
}

fn create_vad(name: &str) -> Option<VadBox> {
    match name {
        "energy" => Some(Box::new(EnergyVad::default())),
        "zcr" => Some(Box::new(ZeroCrossingRateVad::default())),
        _ => None,
    }
}
