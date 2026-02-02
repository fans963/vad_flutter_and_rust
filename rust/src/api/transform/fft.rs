use num_complex::Complex;
use rayon::prelude::*;
use rustfft::FftPlanner;
use std::sync::Arc;

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

        let frame_size = if config.frame_size > 0 {
            config.frame_size
        } else {
            n
        };

        let output_len = frame_size / 2;
        let sample_rate = data.info.sample_rate as f32;

        let mut planner = FftPlanner::new();
        let fft = planner.plan_fft_forward(frame_size);

        let points: Vec<Point> = samples
            .par_chunks(frame_size)
            .enumerate()
            .flat_map_iter(|(chunk_index, chunk)| {
                let mut buffer: Vec<Complex<f32>> = Vec::with_capacity(frame_size);

                for &sample in chunk {
                    buffer.push(Complex {
                        re: sample,
                        im: 0.0,
                    });
                }

                if buffer.len() < frame_size {
                    buffer.resize(frame_size, Complex::new(0.0, 0.0));
                }

                fft.process(&mut buffer);

                (0..output_len).map(move |i| {
                    let magnitude = buffer[i].norm();
                    Point {
                        x: (chunk_index*frame_size+ i * 2) as f32,
                        y: magnitude,
                    }
                })
            })
            .collect();

        Ok(Chart {
            data_type: DataType::Spectrum,
            points: Arc::new(points),
        })
    }
}
