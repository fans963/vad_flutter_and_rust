use crate::api::types::chart::{Chart, DataType};

#[derive(Clone, Debug)]
pub enum ChartEvent {
    AddChart { key: String, chart: Chart },
    RemoveChart { key: String, data_type: DataType },
    RemoveAllCharts {},
}
