use std::io::Cursor;
use std::sync::Arc;

use log::{debug, error};
use symphonia::core::probe::Hint;

use crate::api::traits::audio_decoder::AudioDecoder;
use crate::api::types::audio::{Audio, AudioData, AudioInfo};
use crate::api::types::error::AppError;
use symphonia::core::audio::Signal;

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
        let probed = symphonia::default::get_probe()
            .format(
                &hint,
                mss,
                &symphonia::core::formats::FormatOptions::default(),
                &symphonia::core::meta::MetadataOptions::default(),
            )
            .map_err(|e| AppError::Format(format!("Unsupported format: {:?}", e)))?;

        let mut format_reader = probed.format;

        let track = format_reader
            .tracks()
            .iter()
            .find(|t| t.codec_params.sample_rate.is_some())
            .ok_or_else(|| AppError::Decode("No audio track found".to_string()))?;

        let sample_rate = track.codec_params.sample_rate.unwrap();
        let track_id = track.id;

        let mut decoder = symphonia::default::get_codecs()
            .make(
                &track.codec_params,
                &symphonia::core::codecs::DecoderOptions::default(),
            )
            .map_err(|e| AppError::Decode(format!("Decoder init failed: {:?}", e)))?;

        let mut samples_f32: Vec<f32> = Vec::new();

        loop {
            let packet = match format_reader.next_packet() {
                Ok(p) => p,
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

            if packet.track_id() != track_id {
                continue;
            }

            match decoder.decode(&packet) {
                Ok(decoded_buffer) => {
                    let spec = decoded_buffer.spec();
                    let duration = decoded_buffer.capacity();

                    let mut audio_buffer: symphonia::core::audio::AudioBuffer<f32> =
                        symphonia::core::audio::AudioBuffer::new(duration as u64, *spec);
                    decoded_buffer.convert(&mut audio_buffer);

                    for channel in 0..spec.channels.count() {
                        for sample in audio_buffer.chan(channel) {
                            samples_f32.push(*sample);
                        }
                    }
                }
                Err(e) => {
                    return Err(AppError::Decode(format!("Decode error: {:?}", e)));
                }
            }
        }

        Ok(Audio {
            data: AudioData {
                samples: Arc::new(samples_f32),
            },
            info: AudioInfo { sample_rate },
        })
    }
}
