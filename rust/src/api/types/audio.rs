use std::sync::Arc;

#[derive(Clone)]
pub struct AudioData {
    pub samples: Arc<Vec<f32>>,
}

#[derive(Clone)]
pub struct AudioInfo {
    pub sample_rate: u32,
}

#[derive(Clone)]
pub struct Audio {
    pub data: AudioData,
    pub info: AudioInfo,
}
