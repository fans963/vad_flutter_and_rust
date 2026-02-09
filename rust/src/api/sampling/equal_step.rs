use rayon::{iter::ParallelIterator, slice::ParallelSlice};

use crate::api::{traits::down_sample::DownSample, types::chart::Chart};
use std::sync::Arc;

pub struct EqualStep {}

impl DownSample for EqualStep {
    fn down_sample(&self, chart: Chart, target_points_num: usize) -> Chart {
        let original_points = &chart.points;
        let n = original_points.len();

        if n <= target_points_num || target_points_num < 2 {
            return chart;
        }

        let mut sampled_points: Vec<_> = original_points
            .par_chunks(n / target_points_num)
            .map(|chunk| chunk[0])
            .collect();

        if let Some(last_origin) = original_points.last() {
            if sampled_points.last() != Some(last_origin) {
                sampled_points.push(*last_origin);
            }
        }

        Chart {
            data_type: chart.data_type,
            points: Arc::new(sampled_points),
            min_y: chart.min_y,
            max_y: chart.max_y,
            visible: chart.visible,
        }
    }
}
