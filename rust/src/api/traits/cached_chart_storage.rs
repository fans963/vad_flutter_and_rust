use crate::api::types::{
    chart::{Chart, ChartWIthKey, DataType},
    error::AppError,
};

pub trait CachedChartStorage {
    fn add(&self, key: String, chart: Chart) -> Result<(), AppError>;
    fn get(&self, key: String, data_type: DataType) -> Result<Chart, AppError>;
    fn get_all_cache(&self) -> Result<Vec<ChartWIthKey>, AppError>;
    fn remove(&self, key:  String, data_type: DataType) -> Result<(), AppError>;
}
