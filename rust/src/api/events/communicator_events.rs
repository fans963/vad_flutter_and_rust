use crate::api::types::events::ChartEvent;
use crate::frb_generated::StreamSink;
use std::sync::Mutex;

static CACHE_SINK: Mutex<Option<StreamSink<ChartEvent>>> = Mutex::new(None);

pub fn create_chart_event_stream(sink: StreamSink<ChartEvent>) {
    let mut guard = CACHE_SINK.lock().unwrap();
    *guard = Some(sink);
}

pub fn emit_chart_event(event: ChartEvent) {
    if let Some(sink) = CACHE_SINK.lock().unwrap().as_ref() {
        let _ = sink.add(event);
    }
}
