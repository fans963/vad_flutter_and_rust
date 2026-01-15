use crate::api::{
    events::communicator_events::emit_chart_event,
    traits::communicator::Communicator,
    types::{
        chart::{Chart, DataType},
        events::ChartEvent,
    },
};

pub struct StreamCommunicator {}

impl StreamCommunicator {
    pub fn new() -> Self {
        StreamCommunicator {}
    }
}

impl Communicator for StreamCommunicator {
    fn add_chart(&self, key: String, chart: Chart) {
        emit_chart_event(ChartEvent::AddChart { key, chart });
    }

    fn remove_all_charts(&self) {
        emit_chart_event(ChartEvent::RemoveAllCharts {});
    }

    fn remove_chart(&self, key: String, data_type: DataType) {
        emit_chart_event(ChartEvent::RemoveChart { key, data_type });
    }
}
