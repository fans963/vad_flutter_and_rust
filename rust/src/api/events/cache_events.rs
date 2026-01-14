use crate::api::types::events::CacheEvent;
use crate::frb_generated::StreamSink;
use std::sync::Mutex;

static CACHE_SINK: Mutex<Option<StreamSink<CacheEvent>>> = Mutex::new(None);

pub fn create_cache_event_stream(sink: StreamSink<CacheEvent>) {
    let mut guard = CACHE_SINK.lock().unwrap();
    *guard = Some(sink);
}

pub fn emit_cache_event(event: CacheEvent) {
    if let Some(sink) = CACHE_SINK.lock().unwrap().as_ref() {
        let _ = sink.add(event);
    }
}
