use flutter_rust_bridge::frb;

use crate::api::{
    traits::vad_algorithm::VadAlgorithm,
    types::vad::{VadParamDef, VadResult},
};

#[frb(ignore)]
pub struct EnergyVad {
    pub threshold: f32,
    pub frame_size: usize,
    pub hangover_frames: usize,
}

impl Default for EnergyVad {
    fn default() -> Self {
        Self { threshold: 0.05, frame_size: 512, hangover_frames: 8 }
    }
}

impl VadAlgorithm for EnergyVad {
    fn name(&self) -> &'static str { "energy" }
    fn display_name(&self) -> &'static str { "Energy-based VAD" }

    fn get_parameters(&self) -> Vec<VadParamDef> {
        vec![
            VadParamDef::float("threshold", "能量阈值", self.threshold, 0.001, 1.0, 0.001),
            VadParamDef::int("frame_size", "帧大小", self.frame_size as i32, 128, 4096),
            VadParamDef::int("hangover_frames", "挂起帧数", self.hangover_frames as i32, 0, 50),
        ]
    }

    fn update_parameter(&mut self, key: &str, value: f32) {
        match key {
            "threshold" => self.threshold = value.clamp(0.001, 1.0),
            "frame_size" => self.frame_size = (value as usize).max(128).min(4096),
            "hangover_frames" => self.hangover_frames = (value as usize).min(50),
            _ => {}
        }
    }

    fn process(&self, samples: &[f32], _sample_rate: u32) -> VadResult {
        let n_frames = samples.len() / self.frame_size;
        let mut confidence = Vec::with_capacity(n_frames.max(1));
        let mut hangover = 0usize;

        for chunk in samples.chunks(self.frame_size) {
            let energy: f32 = chunk.iter().map(|s| s * s).sum::<f32>() / chunk.len() as f32;
            let voice = energy > self.threshold;

            if voice {
                hangover = self.hangover_frames;
            } else if hangover > 0 {
                hangover -= 1;
            }

            let conf: f32 = if hangover > 0 || voice { 1.0 } else { 0.0 };
            confidence.push(conf);
        }

        VadResult { confidence, frame_size: self.frame_size as u32 }
    }
}
