use crate::api::types::chart::{Chart, ChartWIthKey, DataType};

pub trait Communicator {
    fn add_chart(&self, key: String, chart: Chart);
    fn remove_chart(&self, key: String, data_type: DataType);
    fn update_all_charts(&self,charts:Vec<ChartWIthKey>);
    fn remove_all_charts(&self);
    fn update_max_index(&self, max_index: f32);
    fn update_y_range(&self, min_y: f32, max_y: f32);
}
