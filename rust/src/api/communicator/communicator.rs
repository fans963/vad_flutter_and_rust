use crate::api::{
    events::communicator_events::emit_chart_event,
    traits::communicator::Communicator,
    types::{
        chart::{Chart, CommunicatorChart, DataType},
        events::ChartEvent,
    },
};

use std::{
    sync::{Mutex, OnceLock},
    time::Instant,
};

pub struct StreamCommunicator {}

impl StreamCommunicator {
    pub fn new() -> Self {
        StreamCommunicator {}
    }
}

fn record_update_interval(now: Instant) -> Option<u128> {
    static LAST_UPDATE: OnceLock<Mutex<Option<Instant>>> = OnceLock::new();
    let storage = LAST_UPDATE.get_or_init(|| Mutex::new(None));
    let mut guard = storage.lock().unwrap();
    let interval = guard.map(|prev| now.duration_since(prev).as_millis());
    *guard = Some(now);
    interval
}

impl Communicator for StreamCommunicator {
    fn add_chart(&self, key: String, chart: Chart) {
        emit_chart_event(ChartEvent::AddChart {  chart: CommunicatorChart {
            key: key,
            data_type: chart.data_type,
            chart: (*chart.points).clone(),
        } });
    } 

    fn update_all_charts(&self,charts:Vec<crate::api::types::chart::ChartWIthKey>) {
        let now = Instant::now();
        if let Some(ms) = record_update_interval(now) {
            log::info!("UpdateAllCharts interval: {ms}ms");
        } else {
            log::info!("UpdateAllCharts first event");
        }

        let communicator_charts:Vec<CommunicatorChart> = charts.into_iter().map(|c| CommunicatorChart{
            key:c.key,
            data_type:c.chart.data_type,
            chart:(*c.chart.points).clone(),
        }).collect();
        emit_chart_event(ChartEvent::UpdateAllCharts { charts: communicator_charts });
    }

    fn remove_all_charts(&self) {
        emit_chart_event(ChartEvent::RemoveAllCharts {});
    }

    fn remove_chart(&self, key: String, data_type: DataType) {
        emit_chart_event(ChartEvent::RemoveChart { key, data_type });
    }
}
