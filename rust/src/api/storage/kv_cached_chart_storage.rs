use dashmap::DashMap;

use crate::api::{
    traits::cached_chart_storage::CachedChartStorage,
    types::{
        chart::{Chart, ChartWIthKey, DataType},
        config::Config,
        error::AppError,
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

        Ok(())
    }

    fn get(&self, key: String, data_type:DataType) -> Result<Chart, AppError> {
        if let Some(cached_charts) = self.dashmap.get(&key) {
            if let Some(chart) = cached_charts
                .iter()
                .find(|c| c.data_type == data_type)
            {
                Ok(chart.clone())
            } else {
                Err(AppError::NotFound(format!(
                    "Chart with specified data type not found for key: {}",
                    key
                )))
            }
        } else {
            Err(AppError::NotFound(format!("Chart key not found: {}", key)))
        }
    }

    fn get_all_cache(&self) -> Result<Vec<ChartWIthKey>, AppError> {
        let mut all_charts = Vec::new();

        for entry in self.dashmap.iter() {
            let key = entry.key().clone();
            for chart in entry.value().iter() {
                all_charts.push(ChartWIthKey {
                    key: key.clone(),
                    chart: chart.clone(),
                });
            }
        }

        Ok(all_charts)
    }

    fn remove(
        &self,
        key: String,
        data_type: crate::api::types::chart::DataType,
    ) -> Result<(), AppError> {
        if let Some(mut cached_charts) = self.dashmap.get_mut(&key) {
            cached_charts.retain(|c| c.data_type != data_type);
            Ok(())
        } else {
            Err(AppError::NotFound(format!(
                "Key not found when trying to remove chart: {}",
                key
            )))
        }
    }
}
