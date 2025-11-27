use num_complex::Complex;
use rayon::prelude::*;
use rustfft::FftPlanner;

#[derive(Debug, Clone)]
pub struct ChartData {
    pub index: Vec<f64>,
    pub data: Vec<f64>,
}

pub async fn calculate_fft_parallel(input_data: Vec<f64>, frame_size: usize) -> Vec<f64> {
    // --- 1. 准备数据 ---
    let data_len = input_data.len();

    // 如果数据长度不是 frame_size 的倍数，截断到最近的完整帧
    let total_process_len = (data_len / frame_size) * frame_size;

    if total_process_len == 0 {
        return Vec::new(); // 数据不足一帧，返回空
    }

    // 只处理完整的帧数据
    let data_to_process = &input_data[0..total_process_len];

    // --- 2. 并行计算 FFT ---

    // 使用 par_chunks 将数据分成帧，并在 Rayon 线程池中并行处理
    let results: Vec<f64> = data_to_process
        .par_chunks(frame_size)
        .flat_map(|real_chunk| {
            // --- 2.1 帧内处理 ---

            // 1. 将实数数据 (f64) 转换为复数数据 (Complex<f64>)
            // FFT 需要复数输入，虚部初始化为 0.0
            let mut complex_data: Vec<Complex<f64>> =
                real_chunk.iter().map(|&x| Complex::new(x, 0.0)).collect();

            // 2. 创建 FFT 规划器和实例
            // 注意: FftPlanner 和 Fft 实例通常不是 Send/Sync 的。
            // 在 par_chunks 的闭包内创建它们，确保每个 Rayon 线程都拥有自己的实例，
            // 避免了复杂的线程安全问题，但会引入轻微的重复规划开销。
            let mut planner = FftPlanner::new();
            let fft = planner.plan_fft_forward(frame_size);

            // 3. 执行 FFT
            fft.process(&mut complex_data);

            // 4. 计算幅值 (Power Spectrum)
            complex_data
                .into_iter()
                .take(frame_size)
                // c.norm() 计算幅值: sqrt(real^2 + imag^2)
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
    ChartData {
        index: vec![],
        data: vec![],
    }
}
