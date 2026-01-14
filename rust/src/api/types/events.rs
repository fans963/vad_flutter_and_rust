use crate::api::types::chart::Chart;

#[derive(Clone, Debug)]
pub enum CacheEvent {
    ChartUpdated {
        key: String,
        chart: Chart,
    },
    ChartRemoved {
        key: String,
        data_type: crate::api::types::chart::DataType,
    },
}
