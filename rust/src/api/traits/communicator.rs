use crate::api::types::chart::{Chart, ChartWIthKey, DataType};

pub trait Communicator {
    fn add_chart(&self, key: String, chart: Chart);
    fn remove_chart(&self, key: String, data_type: DataType);
    fn update_all_charts(&self,charts:Vec<ChartWIthKey>);
    fn remove_all_charts(&self);
}
