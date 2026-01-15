use crate::api::types::chart::{CommunicatorChart, DataType};

#[derive(Clone, Debug)]
pub enum ChartEvent {
    AddChart {
        key: String,
        chart: CommunicatorChart,
    },
    RemoveChart {
        key: String,
        data_type: DataType,
    },
    RemoveAllCharts,
}
