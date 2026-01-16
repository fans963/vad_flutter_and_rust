use crate::api::types::chart::{CommunicatorChart, DataType};

#[derive(Clone, Debug)]
pub enum ChartEvent {
    AddChart {
        chart: CommunicatorChart,
    },
    RemoveChart {
        key: String,
        data_type: DataType,
    },
    UpdateAllCharts{
        charts: Vec<CommunicatorChart>,
    },
    RemoveAllCharts,
}
