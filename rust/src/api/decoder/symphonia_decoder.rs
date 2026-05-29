use std::io::Cursor;
use std::sync::Arc;

use log::error;
use symphonia::core::codecs::audio::AudioDecoderOptions;
use symphonia::core::codecs::CodecParameters;
use symphonia::core::formats::probe::Hint;

use crate::api::traits::audio_decoder::AudioDecoder;
use crate::api::types::audio::{Audio, AudioData, AudioInfo};
use crate::api::types::error::AppError;

pub struct SymphoniaDecoder {}

impl SymphoniaDecoder {
    pub fn new() -> Self {
        Self {}
    }
}

impl AudioDecoder for SymphoniaDecoder {
    fn decode(&self, format: String, data: Vec<u8>) -> Result<Audio, AppError> {
        let source = Box::new(Cursor::new(data));
        let mut hint = Hint::new();
        hint.with_extension(&format);

        let mss = symphonia::core::io::MediaSourceStream::new(source, Default::default());
        let mut format_reader = symphonia::default::get_probe()
            .probe(
                &hint,
                mss,
                symphonia::core::formats::FormatOptions::default(),
                symphonia::core::meta::MetadataOptions::default(),
            )
            .map_err(|e| AppError::Format(format!("Unsupported format: {:?}", e)))?;

        let track = format_reader
            .tracks()
            .iter()
            .find(|t| {
                matches!(&t.codec_params, Some(CodecParameters::Audio(p)) if p.sample_rate.is_some())
            })
            .ok_or_else(|| AppError::Decode("No audio track found".to_string()))?;

        let audio_params = match &track.codec_params {
            Some(CodecParameters::Audio(p)) => p.clone(),
            _ => return Err(AppError::Decode("No audio track found".to_string())),
        };

        let sample_rate = audio_params.sample_rate.unwrap();
        let channels = audio_params.channels.as_ref().map_or(1, |c| c.count() as u16);
        let track_id = track.id;

        let mut decoder = symphonia::default::get_codecs()
            .make_audio_decoder(&audio_params, &AudioDecoderOptions::default())
            .map_err(|e| AppError::Decode(format!("Decoder init failed: {:?}", e)))?;

        let mut samples_f32: Vec<f32> = Vec::new();

        loop {
            let packet = match format_reader.next_packet() {
                Ok(Some(p)) => p,
                Ok(None) => break,
                Err(symphonia::core::errors::Error::ResetRequired) => {
                    error!("RESET_REQUIRED_ERROR");
                    continue;
                }
                Err(symphonia::core::errors::Error::IoError(_)) => {
                    break;
                }
                Err(e) => {
                    return Err(AppError::Decode(format!("Packet read error: {:?}", e)));
                }
            };

            if packet.track_id != track_id {
                continue;
            }

            match decoder.decode(&packet) {
                Ok(decoded_buffer) => {
                    let mut planar: Vec<Vec<f32>> = Vec::new();
                    decoded_buffer.copy_to_vecs_planar(&mut planar);

                    for plane in planar {
                        samples_f32.extend_from_slice(&plane);
                    }
                }
                Err(e) => {
                    return Err(AppError::Decode(format!("Decode error: {:?}", e)));
                }
            }
        }

        let sample_count = samples_f32.len();
        let duration_secs = sample_count as f64 / sample_rate as f64;

        Ok(Audio {
            data: AudioData {
                samples: Arc::new(samples_f32),
            },
            info: AudioInfo {
                sample_rate,
                channels,
                format,
                duration_secs,
                sample_count,
            },
        })
    }
}
