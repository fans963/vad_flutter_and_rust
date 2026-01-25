use crate::api::types::events::ChartEvent;
use crate::frb_generated::StreamSink;
use std::sync::OnceLock;

static CACHE_SINK: OnceLock<StreamSink<ChartEvent>> = OnceLock::new();

pub fn create_chart_event_stream(sink: StreamSink<ChartEvent>) {
    let _ = CACHE_SINK.set(sink);
}

pub fn emit_chart_event(event: ChartEvent) {
    if let Some(sink) = CACHE_SINK.get() {
        let _ = sink.add(event);
    }
}