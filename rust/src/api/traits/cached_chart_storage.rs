use crate::api::types::{
    chart::{Chart, DataType},
    error::AppError,
};

pub trait CachedChartStorage {
    fn add(&self, key: String, chart: Chart) -> Result<(), AppError>;
    fn get(&self, key: String, data_type: DataType) -> Result<Chart, AppError>;
    fn get_all_cache(&self) -> Result<Vec<(String, Chart)>, AppError>;
    fn remove(&self, key: String, data_type: DataType) -> Result<(), AppError>;
}
