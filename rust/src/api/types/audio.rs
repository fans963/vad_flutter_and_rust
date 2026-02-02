use std::sync::Arc;

use rayon::iter::{IndexedParallelIterator, IntoParallelRefIterator, ParallelIterator};

use crate::api::types::chart::{Chart, DataType, Point};

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

impl Audio {
    pub fn audio_to_chart(&self) -> Chart {
        let points: Vec<Point> = self
            .data
            .samples
            .par_iter()
            .enumerate()
            .map(|(i, &sample)| Point {
                x: i as f32,
                y: sample,
            })
            .collect();

        Chart {
            data_type: DataType::Audio,
            points: Arc::new(points),
        }
    }
}
