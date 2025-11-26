use std::io::Cursor;
use rayon::option;
use symphonia::core::audio::Signal;
use symphonia::core::probe::Hint;

#[frb(opaque)]
pub struct AudioProcessor {
    file_path: String,
    audio_data: Vec<f64>,
    cached_fft_data: Option<(usize, Vec<f64>)>,
    sample_rate: u32,
    frame_size: usize,
}

impl AudioProcessor {
    pub async fn new(file_path: String, file_data: Vec<u8>) -> Self {
        // 1. 设置 Symohonia 读入源 (使用 Cursor 模拟文件读取)
        let source = Box::new(Cursor::new(file_data));

        // 2. 尝试识别文件类型（Hint可以根据文件名/扩展名提供提示）
        let mut hint = Hint::new();
        if let Some(ext) = file_path.rfind('.').map(|i| &file_path[i + 1..]) {
            hint.with_extension(ext);
        }

        // 3. 获取 FormatReader
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

        // 4. 选择第一个音频轨道并获取其参数
        let track = format_reader
            .tracks()
            .iter()
            .find(|t| t.codec_params.sample_rate.is_some())
            .expect("NO_AUDIO_TRACK_FOUND");

        let sample_rate = track.codec_params.sample_rate.unwrap();
        let track_id = track.id;

        println!("Audio sample rate: {}", sample_rate);
        // 5. 初始化解码器
        let mut decoder = symphonia::default::get_codecs()
            .make(
                &track.codec_params,
                &symphonia::core::codecs::DecoderOptions::default(),
            )
            .expect("DECODER_INIT_FAILED");

        let mut samples_f64: Vec<f64> = Vec::new();

        // 6. 循环解码音频包
        loop {
            // 获取下一个音频包
            let packet = match format_reader.next_packet() {
                Ok(p) => p,
                Err(symphonia::core::errors::Error::ResetRequired) => {
                    // 解码器需要重置，通常是因为格式变化
                    continue;
                }
                Err(symphonia::core::errors::Error::IoError(_)) => {
                    // 读到文件末尾或 I/O 错误
                    break;
                }
                Err(e) => panic!("PACKET_READ_ERROR: {:?}", e),
            };

            if packet.track_id() != track_id {
                continue;
            }

            // 解码包
            match decoder.decode(&packet) {
                Ok(decoded_buffer) => {
                    // 7. 将解码后的样本转换为 f32 并添加到 Vec 中
                    let spec = decoded_buffer.spec();
                    let duration = decoded_buffer.capacity();

                    // 创建一个 AudioBuffer，用于统一处理不同格式
                    let mut audio_buffer: symphonia::core::audio::AudioBuffer<f64> =
                        symphonia::core::audio::AudioBuffer::new(duration as u64, *spec);
                    decoded_buffer.convert(&mut audio_buffer);

                    // 遍历所有通道，将样本转换为 f64
                    for channel in 0..spec.channels.count() {
                        for sample_i32 in audio_buffer.chan(channel) {
                            // IntoSample trait 帮助将 i16, i32, f64 等转换为 f64
                            samples_f64.push(*sample_i32);
                        }
                    }
                }
                Err(e) => {
                    eprintln!("DECODE_ERROR: {:?}", e);
                }
            }
        }

        AudioProcessor {
            file_path,
            audio_data: samples_f64,
            cached_fft_data: None,
            frame_size: 512,
            sample_rate,
        }
    }

    pub fn get_file_path(&self) -> &str {
        &self.file_path
    }

    pub async fn get_audio_data(&self) -> Vec<f64> {
        self.audio_data.clone()
    }

    pub fn get_frame_size(&self) -> usize {
        self.frame_size
    }

    pub fn set_frame_size(&mut self, frame_size: usize) {
        if frame_size.is_power_of_two() {
            self.frame_size = frame_size;
        } else {
            println!("Frame size must be a power of two.");
        }
    }

    pub async fn fft(&self) -> Vec<f64> {
        if let Some(cached_data)=&self.cached_fft_data {
            if cached_data.0==self.frame_size {
                return cached_data.1.clone();
            }else {
                
            }
        }

        vec![]
    }

    // pub
}
