use rayon::iter::{IntoParallelRefIterator, ParallelIterator};

use crate::api::types::chart::Point;

pub async fn get_min_max_par(points: &Vec<Point>) -> (f32, f32) {
    points
        .par_iter()
        .fold(
            || (f32::MAX, f32::MIN),
            |(min, max), &v| (min.min(v.y), max.max(v.y)),
        )
        .reduce(
            || (f32::MAX, f32::MIN),
            |(a_min, a_max), (b_min, b_max)| (a_min.min(b_min), a_max.max(b_max)),
        )
}
