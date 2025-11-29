use num_complex::Complex;
use rayon::prelude::*;
use rustfft::FftPlanner;

#[derive(Debug, Clone)]
pub struct ChartData {
    pub index: Vec<f64>,
    pub data: Vec<f64>,
}

pub async fn calculate_fft_parallel(input_data: Vec<f64>, frame_size: usize) -> Vec<f64> {
    let data_len = input_data.len();

    let total_process_len = (data_len / frame_size) * frame_size;

    if total_process_len == 0 {
        return Vec::new();
    }

    let data_to_process = &input_data[0..total_process_len];

    let results: Vec<f64> = data_to_process
        .par_chunks(frame_size)
        .flat_map(|real_chunk| {
            let mut complex_data: Vec<Complex<f64>> =
                real_chunk.iter().map(|&x| Complex::new(x, 0.0)).collect();

            let mut planner = FftPlanner::new();
            let fft = planner.plan_fft_forward(frame_size);

            fft.process(&mut complex_data);

            complex_data
                .into_iter()
                .take(frame_size)
                .map(|c| c.norm())
                .collect::<Vec<f64>>()
        })
        .collect();

    results
}

pub async fn perform_log10_parallel(input_data: Vec<f64>) -> Vec<f64> {
    input_data.par_iter().map(|&x| x.log10()).collect()
}

pub async fn down_sample_data(raw_data: ChartData, down_sample_factor: f64) -> ChartData {
    if down_sample_factor <= 1.0 {
        return raw_data;
    }else {
        
    }
    ChartData {
        index: vec![],
        data: vec![],
    }
}
