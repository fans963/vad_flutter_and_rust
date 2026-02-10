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
    UpdateMaxIndex{
        max_index:f32,
    },
    UpdateYRange{
        min_y:f32,
        max_y:f32,
    },
}
