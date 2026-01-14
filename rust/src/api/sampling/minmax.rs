use rayon::{iter::ParallelIterator, slice::ParallelSlice};

use crate::api::{traits::down_sample::DownSample, types::chart::Chart};
use std::sync::Arc;

pub struct Minmax {}

impl DownSample for Minmax {
    fn down_sample(&self, chart: Chart, target_points_num: usize) -> Chart {
         let original_points = &chart.points;
        let n = original_points.len();

        if n <= target_points_num || target_points_num < 2 {
            return chart;
        }

        let num_buckets = target_points_num / 2;
        let bucket_size = (n / num_buckets).max(1);

        let mut mid_points: Vec<_> = original_points
            .par_chunks(bucket_size) // 并行切分
            .flat_map(|chunk| {
                if chunk.is_empty() {
                    return vec![];
                }

                let mut min_idx = 0;
                let mut max_idx = 0;

                for (idx, p) in chunk.iter().enumerate() {
                    if p.y < chunk[min_idx].y {
                        min_idx = idx;
                    }
                    if p.y > chunk[max_idx].y {
                        max_idx = idx;
                    }
                }

                if min_idx < max_idx {
                    vec![chunk[min_idx], chunk[max_idx]]
                } else if min_idx > max_idx {
                    vec![chunk[max_idx], chunk[min_idx]]
                } else {
                    vec![chunk[min_idx]]
                }
            })
            .collect();

        let mut final_points = Vec::with_capacity(mid_points.len() + 2);
        final_points.push(original_points[0]);
        final_points.append(&mut mid_points);
        final_points.push(original_points[n - 1]);

        Chart {
            data_type: chart.data_type,
            points: Arc::new(final_points),
        }
    }
}
