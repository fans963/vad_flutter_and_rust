use std::sync::Arc;
use num_complex::Complex;
use rayon::prelude::*;
use rustfft::FftPlanner;

use crate::api::{
    traits::transform::SignalTransform,
    types::{
        audio::Audio,
        chart::{Chart, DataType, Point},
        config::Config,
        error::AppError,
    },
};

pub struct FftTransform {}

impl SignalTransform for FftTransform {
    fn transform(&self, data: Audio, config: Config) -> Result<Chart, AppError> {
        let samples = &data.data.samples;
        let n = samples.len();

        if n == 0 {
            return Ok(Chart {
                data_type: DataType::Spectrum,
                points: Arc::new(vec![]),
            });
        }

        // 1. Determine frame size
        // If config.frame_size is set, use it. Otherwise, treat the whole data as one frame.
        let frame_size = if config.frame_size > 0 {
            config.frame_size
        } else {
            n
        };
        
        let output_len = frame_size / 2;
        let sample_rate = data.info.sample_rate as f32;

        // 2. Prepare FFT Planner
        // Create the plan once and share input across threads.
        let mut planner = FftPlanner::new();
        let fft = planner.plan_fft_forward(frame_size);

        // 3. Parallel Compute: Process each frame independently
        // No reduction/summing. We return the spectrum for every frame sequentially.
        let points: Vec<Point> = samples
            .par_chunks(frame_size)
            .flat_map_iter(|chunk| {
                // Initialize buffer with data from chunk
                let mut buffer: Vec<Complex<f32>> = Vec::with_capacity(frame_size);
                
                for &sample in chunk {
                    buffer.push(Complex { re: sample, im: 0.0 });
                }
                
                // Zero padding if chunk is smaller than frame_size
                if buffer.len() < frame_size {
                    buffer.resize(frame_size, Complex::new(0.0, 0.0));
                }

                // Execute FFT
                // Uses the shared FFT plan instance
                fft.process(&mut buffer);

                // Compute Magnitude and map to Points
                // Only take the first half (0 to Nyquist)
                let norm_factor = 2.0 / frame_size as f32; // Normalize per frame
                
                // We must collect to Vec here to return from flat_map efficiently or use iterator
                // Using iterator inside flat_map is better for memory if possible, but calculating freq needs index
                (0..output_len).map(move |i| {
                    // let freq = i as f32 * sample_rate / frame_size as f32;
                    let magnitude = buffer[i].norm() * norm_factor;
                    Point { x: i as f32 * 2.0, y: magnitude }
                })
            })
            .collect();

        Ok(Chart {
            data_type: DataType::Spectrum,
            points: Arc::new(points),
        })
    }
}
