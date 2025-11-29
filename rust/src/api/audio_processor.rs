use rayon::prelude::*;
use std::io::Cursor;
use std::ops::Index;
use std::sync::RwLock;
use symphonia::core::audio::{self, Signal};
use symphonia::core::formats::util;
use symphonia::core::probe::Hint;

use crate::api::util::{calculate_fft_parallel, ChartData};

pub struct AudioInfo {
    audio_data: Vec<f64>,
    cached_fft_data: Option<(usize, Vec<f64>)>,
    sample_rate: u32,
}

#[frb(opaque)]
pub struct AudioProcessor {
    audio_info_map: RwLock<std::collections::HashMap<String, AudioInfo>>,
    frame_size: usize,
}

impl AudioProcessor {
    pub async fn new() -> Self {
        AudioProcessor {
            audio_info_map: RwLock::new(std::collections::HashMap::new()),
            frame_size: 512,
        }
    }

    pub async fn add(&mut self, file_path: String, file_data: Vec<u8>) {
        let source = Box::new(Cursor::new(file_data));

        let mut hint = Hint::new();
        if let Some(ext) = file_path.rfind('.').map(|i| &file_path[i + 1..]) {
            hint.with_extension(ext);
        }

        let mss = symphonia::core::io::MediaSourceStream::new(source, Default::default());
        let probed = symphonia::default::get_probe()
            .format(
                &hint,
                mss, 
                &symphonia::core::formats::FormatOptions::default(),
                &symphonia::core::meta::MetadataOptions::default(),
            )
            .expect("UNSUPPORTED_AUDIO_FORMAT");
        let mut format_reader = probed.format;

        let track = format_reader
            .tracks()
            .iter()
            .find(|t| t.codec_params.sample_rate.is_some())
            .expect("NO_AUDIO_TRACK_FOUND");

        let sample_rate = track.codec_params.sample_rate.unwrap();
        let track_id = track.id;

        println!("Audio sample rate: {}", sample_rate);
        let mut decoder = symphonia::default::get_codecs()
            .make(
                &track.codec_params,
                &symphonia::core::codecs::DecoderOptions::default(),
            )
            .expect("DECODER_INIT_FAILED");

        let mut samples_f64: Vec<f64> = Vec::new();

        loop {
            let packet = match format_reader.next_packet() {
                Ok(p) => p,
                Err(symphonia::core::errors::Error::ResetRequired) => {
                    continue;
                }
                Err(symphonia::core::errors::Error::IoError(_)) => {
                    break;
                }
                Err(e) => panic!("PACKET_READ_ERROR: {:?}", e),
            };

            if packet.track_id() != track_id {
                continue;
            }

            match decoder.decode(&packet) {
                Ok(decoded_buffer) => {
                    let spec = decoded_buffer.spec();
                    let duration = decoded_buffer.capacity();

                    let mut audio_buffer: symphonia::core::audio::AudioBuffer<f64> =
                        symphonia::core::audio::AudioBuffer::new(duration as u64, *spec);
                    decoded_buffer.convert(&mut audio_buffer);

                    for channel in 0..spec.channels.count() {
                        for sample_i32 in audio_buffer.chan(channel) {
                            samples_f64.push(*sample_i32);
                        }
                    }
                }
                Err(e) => {
                    eprintln!("DECODE_ERROR: {:?}", e);
                }
            }
        }

        {
            let mut map = self.audio_info_map.write().unwrap();
            map.insert(
                file_path.clone(),
                AudioInfo {
                    audio_data: samples_f64,
                    cached_fft_data: None,
                    sample_rate,
                },
            );
        }
    }

    async fn get_offset_visible_data(
        &self,
        offset: (f64, f64),
        index: (usize, usize),
        data: &Vec<f64>,
    ) -> ChartData {
        let index_data = if index.0 >= index.1 {
            println!("Invalid index range: start {} >= end {}", index.0, index.1);
            Vec::new()
        } else {
            (index.0..index.1.min(data.len()))
                .into_par_iter()
                .map(|i| i as f64 + offset.0)
                .collect()
        };

        let plot_data = if index.0 >= data.len() || index.0 >= index.1 {
            println!("Index out of bounds or invalid range: start {}", index.0);
            Vec::new()
        } else {
            let end = (index.1).min(data.len());
            data[index.0..end].to_vec()
        };

        ChartData {
            index: index_data,
            data: plot_data,
        }
    }

    pub async fn get_audio_data(
        &self,
        file_path: String,
        offset: (f64, f64),
        index: (usize, usize),
    ) -> ChartData {
        let audio_data = {
            let map = self.audio_info_map.read().unwrap();
            if let Some(audio_info) = map.get(&file_path) {
                audio_info.audio_data.clone()
            } else {
                println!("File not found: {}", file_path);
                return ChartData {
                    index: vec![],
                    data: vec![],
                };
            }
        };
        self.get_offset_visible_data(offset, index, &audio_data)
            .await
    }

    pub async fn get_down_sampled_data(
        &self,
        file_path: String,
        offset: (f64, f64),
        index: (usize, usize),
        down_sample_factor: f64,
    ) -> ChartData {
        crate::api::util::down_sample_data(
            self.get_audio_data(file_path, offset, index).await,
            down_sample_factor,
        )
        .await
    }

    pub fn get_frame_size(&self, file_path: String) -> usize {
        self.frame_size
    }

    pub fn set_frame_size(&mut self, frame_size: usize) {
        self.frame_size = frame_size;
    }

    pub async fn get_fft_data(
        &self,
        file_path: String,
        offset: (f64, f64),
        index: (usize, usize),
    ) -> ChartData {
        // 首先检查缓存
        let (audio_data, needs_update) = {
            let map = self.audio_info_map.read().unwrap();
            if let Some(audio_info) = map.get(&file_path) {
                let needs_update = match &audio_info.cached_fft_data {
                    Some((cached_frame_size, _)) if *cached_frame_size == self.frame_size => false,
                    _ => true,
                };

                if !needs_update {
                    // 返回缓存的数据
                    if let Some((_, cached_data)) = &audio_info.cached_fft_data {
                        return ChartData {
                            index: vec![], // TODO: populate with proper frequency bins
                            data: cached_data.clone(),
                        };
                    }
                }

                (audio_info.audio_data.clone(), needs_update)
            } else {
                return ChartData {
                    index: vec![],
                    data: vec![],
                };
            }
        };

        // 如果需要更新缓存，先计算FFT
        let fft_data = calculate_fft_parallel(audio_data, self.frame_size).await;

        // 更新缓存
        {
            let mut map = self.audio_info_map.write().unwrap();
            if let Some(audio_info) = map.get_mut(&file_path) {
                audio_info.cached_fft_data = Some((self.frame_size, fft_data.clone()));
            }
        }

        ChartData {
            index: vec![], // TODO: populate with proper frequency bins
            data: fft_data,
        }
    }

    pub fn audio_data_len(&self, file_path: String) -> usize {
        let map = self.audio_info_map.read().unwrap();
        if let Some(audio_info) = map.get(&file_path) {
            audio_info.audio_data.len()
        } else {
            0
        }
    }

    pub fn get_sample_rate(&self, file_path: String) -> u32 {
        let map = self.audio_info_map.read().unwrap();
        if let Some(audio_info) = map.get(&file_path) {
            audio_info.sample_rate
        } else {
            0
        }
    }
}
