use crate::api::types::chart::Chart;

pub trait DownSample {
    fn down_sample(&self, chart:Chart, target_points_num: usize) -> Chart;
}