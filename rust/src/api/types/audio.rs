use std::sync::{Arc, atomic::AtomicBool};

use rayon::iter::{IndexedParallelIterator, IntoParallelRefIterator, ParallelIterator};

use crate::api::{types::chart::{Chart, DataType, Point}, util::get_min_max::{self, get_min_max_par}};

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
    pub async fn audio_to_chart(&self) -> Chart {
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
        let (min_y, max_y) =  get_min_max_par(&points).await;
        Chart {
            data_type: DataType::Audio,
            points: Arc::new(points),
            min_y,
            max_y,
            visible: Arc::new(AtomicBool::new(true)),
        }
    }
}
