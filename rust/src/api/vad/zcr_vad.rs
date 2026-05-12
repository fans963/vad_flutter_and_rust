use flutter_rust_bridge::frb;

use crate::api::{
    traits::vad_algorithm::VadAlgorithm,
    types::vad::{VadParamDef, VadResult},
};

#[frb(ignore)]
pub struct ZeroCrossingRateVad {
    pub zcr_threshold: f32,
    pub frame_size: usize,
    pub energy_floor: f32,
}

impl Default for ZeroCrossingRateVad {
    fn default() -> Self {
        Self { zcr_threshold: 0.3, frame_size: 512, energy_floor: 0.001 }
    }
}

impl VadAlgorithm for ZeroCrossingRateVad {
    fn name(&self) -> &'static str { "zcr" }
    fn display_name(&self) -> &'static str { "ZCR-based VAD" }

    fn get_parameters(&self) -> Vec<VadParamDef> {
        vec![
            VadParamDef::float("zcr_threshold", "ZCR 阈值", self.zcr_threshold, 0.01, 1.0, 0.01),
            VadParamDef::int("frame_size", "帧大小", self.frame_size as i32, 128, 4096),
            VadParamDef::float("energy_floor", "能量下限", self.energy_floor, 0.0, 0.1, 0.001),
        ]
    }

    fn update_parameter(&mut self, key: &str, value: f32) {
        match key {
            "zcr_threshold" => self.zcr_threshold = value.clamp(0.01, 1.0),
            "frame_size" => self.frame_size = (value as usize).max(128).min(4096),
            "energy_floor" => self.energy_floor = value.clamp(0.0, 0.1),
            _ => {}
        }
    }

    fn process(&self, samples: &[f32], _sample_rate: u32) -> VadResult {
        let n_frames = samples.len() / self.frame_size;
        let mut confidence = Vec::with_capacity(n_frames.max(1));

        for chunk in samples.chunks(self.frame_size) {
            if chunk.len() < 2 {
                confidence.push(0.0);
                continue;
            }

            let energy: f32 = chunk.iter().map(|s| s * s).sum::<f32>() / chunk.len() as f32;
            if energy < self.energy_floor {
                confidence.push(0.0);
                continue;
            }

            let zcr: f32 = chunk
                .windows(2)
                .filter(|w| w[0].signum() != w[1].signum())
                .count() as f32
                / chunk.len() as f32;

            let conf = 1.0 - (zcr / self.zcr_threshold).min(1.0);
            confidence.push(conf);
        }

        VadResult { confidence, frame_size: self.frame_size as u32 }
    }
}
