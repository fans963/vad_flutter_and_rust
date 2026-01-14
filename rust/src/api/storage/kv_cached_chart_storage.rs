use dashmap::DashMap;

use crate::api::{
    events::cache_events::emit_cache_event,
    traits::cached_chart_storage::CachedChartStorage,
    types::{
        chart::{Chart, DataType},
        config::Config,
        error::AppError,
        events::CacheEvent,
    },
};

pub struct KvCachedChartStorage {
    pub config: Config,
    dashmap: DashMap<String, Vec<Chart>>,
}

impl KvCachedChartStorage {
    pub fn new() -> Self {
        Self {
            config: Config::default(),
            dashmap: DashMap::new(),
        }
    }
}

impl CachedChartStorage for KvCachedChartStorage {
    fn add(&self, key: String, chart: Chart) -> Result<(), AppError> {
        let event_chart = chart.clone();
        let event_key = key.clone();

        if let Some(mut cached_charts) = self.dashmap.get_mut(&key) {
            if let Some(existing) = cached_charts
                .iter_mut()
                .find(|c| c.data_type == chart.data_type)
            {
                *existing = chart;
            } else {
                cached_charts.push(chart);
            }
        } else {
            self.dashmap.insert(key, vec![chart]);
        }

        emit_cache_event(CacheEvent::ChartUpdated {
            key: event_key,
            chart: event_chart,
        });
        Ok(())
    }

    fn get(&self, key: String) -> Result<Chart, AppError> {
        if let Some(cached_charts) = self.dashmap.get(&key) {
            if let Some(chart) = cached_charts.first() {
                Ok(chart.clone())
            } else {
                Err(AppError::NotFound(
                    "No charts available for the given key".to_string(),
                ))
            }
        } else {
            Err(AppError::NotFound(format!("Chart key not found: {}", key)))
        }
    }

    fn remove(
        &self,
        key: String,
        data_type: crate::api::types::chart::DataType,
    ) -> Result<(), AppError> {
        if let Some(mut cached_charts) = self.dashmap.get_mut(&key) {
            cached_charts.retain(|c| c.data_type != data_type);
            emit_cache_event(CacheEvent::ChartRemoved { key, data_type });
            Ok(())
        } else {
            Err(AppError::NotFound(format!(
                "Key not found when trying to remove chart: {}",
                key
            )))
        }
    }
}
