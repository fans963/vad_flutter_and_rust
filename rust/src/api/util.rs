use rayon::prelude::*;

pub struct DownSampleChartData {
    pub index: Vec<f64>,
    pub data: Vec<f64>,
}

pub async fn caculate_fft_parallel(input_data: Vec<f64>, frame_size: usize) -> Vec<f64> {
    // Placeholder implementation
    input_data
        .par_chunks(frame_size)
        .flat_map(|chunk| chunk.to_vec())
        .collect()
}

pub async fn down_sample_data(raw_data: Vec<f64>) -> DownSampleChartData {
    // Placeholder implementation
    DownSampleChartData {
        index: vec![],
        data: vec![],
    }
}
