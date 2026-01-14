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
