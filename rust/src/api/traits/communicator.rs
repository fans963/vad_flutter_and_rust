use crate::api::types::chart::{Chart, DataType};

pub trait Communicator {
    fn add_chart(&self, key: String, chart: Chart);
    fn remove_chart(&self, key: String, data_type: DataType);
    fn remove_all_charts(&self);
}
