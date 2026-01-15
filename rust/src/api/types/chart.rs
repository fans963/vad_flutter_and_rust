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

#[derive(Clone, Debug, PartialEq)]
pub struct Chart {
    pub data_type: DataType,
    pub points: Arc<Vec<Point>>,
}

impl Chart {
    pub fn get_range(&self, start_x: f32, end_x: f32) -> Self {
        use rayon::iter::{IndexedParallelIterator, IntoParallelRefIterator, ParallelIterator};

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
        }
    }
}
