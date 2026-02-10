use crate::api::{
    events::communicator_events::emit_chart_event,
    traits::communicator::Communicator,
    types::{
        chart::{Chart, ChartWIthKey, CommunicatorChart, DataType},
        events::ChartEvent,
    },
};

use std::sync::{Arc, Mutex, OnceLock};

pub struct StreamCommunicator {}

impl StreamCommunicator {
    pub fn new() -> Self {
        StreamCommunicator {}
    }
}

impl Communicator for StreamCommunicator {
    fn add_chart(&self, key: String, chart: Chart) {
        emit_chart_event(ChartEvent::AddChart {
            chart: CommunicatorChart {
                key,
                data_type: chart.data_type,
                chart: Arc::try_unwrap(chart.points).unwrap_or_else(|v| (*v).clone()),
            },
        });
    }

    fn update_all_charts(&self, charts: Vec<crate::api::types::chart::ChartWIthKey>) {
        let communicator_charts: Vec<CommunicatorChart> = charts
            .into_iter()
            .map(|c| CommunicatorChart {
                key: c.key,
                data_type: c.chart.data_type,
                chart: Arc::try_unwrap(c.chart.points).unwrap_or_else(|v| (*v).clone()),
            })
            .collect();
        emit_chart_event(ChartEvent::UpdateAllCharts {
            charts: communicator_charts,
        });
    }

    fn remove_all_charts(&self) {
        emit_chart_event(ChartEvent::RemoveAllCharts {});
    }

    fn remove_chart(&self, key: String, data_type: DataType) {
        emit_chart_event(ChartEvent::RemoveChart { key, data_type });
    }

    fn update_max_index(&self, max_index: f32) {
        emit_chart_event(ChartEvent::UpdateMaxIndex { max_index });
    }
    
    fn update_y_range(&self, min_y: f32, max_y: f32) {
        emit_chart_event(ChartEvent::UpdateYRange { min_y, max_y });
    }
}
