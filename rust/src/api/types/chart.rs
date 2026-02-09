use std::sync::atomic::{self, AtomicBool};
use std::sync::Arc;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Point {
    pub x: f32,
    pub y: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum DataType {
    Audio,
    Spectrum,
    Energy,
    ZeroCrossingRate,
}

#[derive(Clone, Debug)]
pub struct Chart {
    pub data_type: DataType,
    pub points: Arc<Vec<Point>>,
    pub min_y: f32,
    pub max_y: f32,
    pub visible: Arc<AtomicBool>,
}

// impl PartialEq for Chart {
//     fn eq(&self, other: &Self) -> bool {
//         self.data_type == other.data_type
//             && self.points == other.points
//             && self.min_y == other.min_y
//             && self.max_y == other.max_y
//             && self
//                 .visible
//                 .load(atomic::Ordering::Relaxed)
//                 == other
//                     .visible
//                     .load(atomic::Ordering::Relaxed)
//     }
// }

#[derive(Clone, Debug, PartialEq)]
pub struct CommunicatorChart {
    pub key: String,
    pub data_type: DataType,
    pub chart: Vec<Point>,
}

impl Chart {
    pub fn get_range(&self, start_x: f32, end_x: f32) -> Self {
        use rayon::iter::{IndexedParallelIterator, IntoParallelRefIterator};

        let start = self
            .points
            .par_iter()
            .position_first(|p| p.x >= start_x)
            .unwrap_or(0);
        let end = self
            .points
            .par_iter()
            .position_last(|p| p.x <= end_x)
            .map(|i| i + 1)
            .unwrap_or(self.points.len());

        let start = start.min(self.points.len());
        let end = end.clamp(start, self.points.len());

        Self {
            data_type: self.data_type,
            points: Arc::new(self.points[start..end].to_vec()),
            min_y: self.min_y,
            max_y: self.max_y,
            visible: Arc::clone(&self.visible),
        }
    }
}

// impl Default for Chart {
//     fn default() -> Self {
//         Self {
//             data_type: DataType::Audio,
//             points: Arc::new(vec![]),
//             min_y: 0.0,
//             max_y: 0.0,
//             visible: Arc::new(AtomicBool::new(true)),
//         }
//     }
// }

#[derive(Clone)]
pub struct ChartWIthKey {
    pub key: String,
    pub chart: Chart,
}
