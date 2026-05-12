use burn::backend::flex::FlexDevice;
use burn::backend::Flex;
use burn::prelude::*;
use burn::tensor::ops::PadMode;
use flutter_rust_bridge::frb;

use crate::api::{
    traits::vad_algorithm::VadAlgorithm,
    types::vad::{VadParamDef, VadResult},
};

mod silero_model {
    include!(concat!(env!("OUT_DIR"), "/models/silero_vad_op18_ifless.rs"));
}

type B = Flex<f32>;

struct PredictState {
    context_size: usize,
    context: Tensor<B, 2>,
    state: Tensor<B, 3>,
}

impl PredictState {
    fn new(device: &Device<B>, batch_size: usize, context_size: usize) -> Self {
        Self {
            context_size,
            context: Tensor::zeros([batch_size, context_size], device),
            state: Tensor::zeros([2, batch_size, 128], device),
        }
    }

    fn default(device: &Device<B>) -> Self {
        Self::new(device, 1, 64)
    }
}

#[frb(ignore)]
pub struct SileroVad {
    pub threshold: f32,
    pub min_speech_frames: usize,
    pub min_silence_frames: usize,
}

impl Default for SileroVad {
    fn default() -> Self {
        Self { threshold: 0.5, min_speech_frames: 3, min_silence_frames: 10 }
    }
}

impl VadAlgorithm for SileroVad {
    fn name(&self) -> &'static str { "silero" }
    fn display_name(&self) -> &'static str { "Silero VAD (ONNX via Burn)" }

    fn get_parameters(&self) -> Vec<VadParamDef> {
        vec![
            VadParamDef::float("threshold", "语音阈值", self.threshold, 0.1, 0.9, 0.05),
            VadParamDef::int("min_speech_frames", "最少语音帧", self.min_speech_frames as i32, 1, 20),
            VadParamDef::int("min_silence_frames", "最少静音帧", self.min_silence_frames as i32, 1, 50),
        ]
    }

    fn update_parameter(&mut self, key: &str, value: f32) {
        match key {
            "threshold" => self.threshold = value.clamp(0.1, 0.9),
            "min_speech_frames" => self.min_speech_frames = (value as usize).clamp(1, 20),
            "min_silence_frames" => self.min_silence_frames = (value as usize).clamp(1, 50),
            _ => {}
        }
    }

    fn process(&self, samples: &[f32], _sample_rate: u32) -> VadResult {
        const CHUNK_SIZE: usize = 512;
        const WEIGHTS: &[u8] = include_bytes!("../../../models/silero_vad_op18_ifless.bpk");

        let device = FlexDevice::default();
        let model = silero_model::Model::<B>::from_bytes(
            burn::tensor::Bytes::from_bytes_vec(WEIGHTS.to_vec()),
            &device,
        );

        let mut state = PredictState::default(&device);
        let n_frames = samples.len() / CHUNK_SIZE;
        let mut raw_probs = Vec::with_capacity(n_frames.max(1));

        for chunk in samples.chunks(CHUNK_SIZE) {
            if chunk.len() < CHUNK_SIZE {
                raw_probs.push(0.0);
                continue;
            }
            let input = Tensor::<B, 1>::from_data(chunk, &device).unsqueeze();
            let (new_state, output) = predict(&model, state, input, CHUNK_SIZE);
            state = new_state;
            let output_data = output.into_data().to_vec::<f32>().unwrap_or_default();
            raw_probs.push(*output_data.first().unwrap_or(&0.0));
        }

        let mut confidence = vec![0.0f32; raw_probs.len()];
        let mut speech_counter = 0usize;
        let mut silence_counter = self.min_silence_frames;
        for (i, &prob) in raw_probs.iter().enumerate() {
            if prob > self.threshold {
                speech_counter += 1;
                silence_counter = 0;
            } else {
                silence_counter += 1;
            }
            if speech_counter >= self.min_speech_frames {
                confidence[i] = prob;
            } else if silence_counter < self.min_silence_frames && i > 0 && confidence[i - 1] > 0.0 {
                confidence[i] = prob;
            }
        }
        VadResult { confidence, frame_size: CHUNK_SIZE as u32 }
    }
}

fn predict(
    model: &silero_model::Model<B>,
    state: PredictState,
    mut input: Tensor<B, 2>,
    input_size: usize,
) -> (PredictState, Tensor<B, 2>) {
    if input.shape()[1] < input_size {
        let pad_size = input_size - input.shape()[1];
        input = input.pad((0, pad_size, 0, 0), PadMode::Constant(0.0));
    }
    let PredictState { context_size, context, state: prev_state } = state;
    let input_data = Tensor::cat(vec![context, input], 1);
    let context = input_data.clone().slice(s![.., -(context_size as i32)..]).clone();
    let (out, new_state) = model.forward(input_data, 16000, prev_state);
    (PredictState { context_size, context, state: new_state }, out)
}
