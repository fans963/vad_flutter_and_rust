# 零开销抽象架构 - 实施指南

## 目录

1. [快速开始](#快速开始)
2. [第一步：创建基础结构](#第一步创建基础结构)
3. [第二步：定义核心Trait](#第二步定义核心trait)
4. [第三步：实现具体组件](#第三步实现具体组件)
5. [第四步：构建核心引擎](#第四步构建核心引擎)
6. [第五步：迁移现有代码](#第五步迁移现有代码)
7. [测试策略](#测试策略)
8. [性能验证](#性能验证)

---

## 快速开始

### 阅读顺序

1. **首先阅读**: `ARCHITECTURE_SUMMARY.md` - 快速了解架构思路（5分钟）
2. **然后阅读**: `ARCHITECTURE_DIAGRAM.md` - 理解架构图和数据流（10分钟）
3. **详细阅读**: `ARCHITECTURE_DESIGN.md` - 完整的设计文档（30-60分钟）
4. **实施参考**: 本文档 `IMPLEMENTATION_GUIDE.md` - 实施步骤指南

### 为什么需要这个重构？

当前问题：
```rust
// ❌ 问题1：解码器硬编码
let probed = symphonia::default::get_probe().format(...);
// → 无法替换为其他解码器，无法mock测试

// ❌ 问题2：存储方式固定
audio_info_map: RwLock<HashMap<String, AudioInfo>>
// → 无法切换到LRU缓存或磁盘存储

// ❌ 问题3：FFT算法耦合
pub async fn calculate_fft_parallel(...)
// → 无法替换为STFT或其他变换

// ❌ 问题4：数据频繁克隆
audio_info.audio_data.clone()
// → 性能损失
```

新架构解决方案：
```rust
// ✅ 解决1：解码器抽象
trait AudioDecoder {
    fn decode(...) -> Result<DecodedAudio, Error>;
}
// → 可以实现多种解码器，可以mock测试

// ✅ 解决2：存储抽象
trait AudioStorage {
    fn store(...);
    fn get(...) -> &[f64];  // 零拷贝
}
// → 可以切换不同存储策略

// ✅ 解决3：变换抽象
trait SignalTransform {
    fn transform(...) -> Output;
}
// → 可以实现多种变换算法

// ✅ 解决4：零拷贝设计
pub struct DecodedAudio<'a> {
    samples: Cow<'a, [f64]>,  // 按需拷贝
}
```

---

## 第一步：创建基础结构

### 1.1 创建目录

```bash
cd rust/src
mkdir -p core decoder storage transform cache sampling
```

### 1.2 创建模块文件

```bash
# 核心模块
touch core/mod.rs core/engine.rs core/builder.rs core/types.rs

# 解码器模块
touch decoder/mod.rs decoder/traits.rs decoder/symphonia.rs decoder/mock.rs

# 存储模块
touch storage/mod.rs storage/traits.rs storage/memory.rs storage/lru.rs

# 变换模块
touch transform/mod.rs transform/traits.rs transform/fft.rs

# 缓存模块
touch cache/mod.rs cache/traits.rs cache/smart_cache.rs

# 采样模块
touch sampling/mod.rs sampling/traits.rs sampling/strategies.rs
```

### 1.3 更新 lib.rs

```rust
// rust/src/lib.rs

#[macro_use]
extern crate flutter_rust_bridge;

// 现有模块（保持向后兼容）
pub mod api;
mod frb_generated;

// 新架构模块
pub mod core;
pub mod decoder;
pub mod storage;
pub mod transform;
pub mod cache;
pub mod sampling;
```

---

## 第二步：定义核心Trait

### 2.1 解码器Trait (decoder/traits.rs)

```rust
// rust/src/decoder/traits.rs

use std::borrow::Cow;

/// 解码后的音频数据
#[derive(Debug, Clone)]
pub struct DecodedAudio<'a> {
    /// 音频样本（使用Cow实现按需拷贝）
    pub samples: Cow<'a, [f64]>,
    /// 采样率
    pub sample_rate: u32,
    /// 声道数
    pub channels: u16,
}

/// 音频解码错误
#[derive(Debug, thiserror::Error)]
pub enum DecodeError {
    #[error("Unsupported format: {0}")]
    UnsupportedFormat(String),
    
    #[error("Decode failed: {0}")]
    DecodeFailed(String),
    
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
}

/// 音频解码器trait
pub trait AudioDecoder {
    /// 解码音频数据
    /// 
    /// # 参数
    /// - `data`: 原始音频数据
    /// - `hint`: 格式提示（如"mp3", "wav"等）
    /// 
    /// # 返回
    /// - `Ok(DecodedAudio)`: 解码成功
    /// - `Err(DecodeError)`: 解码失败
    fn decode<'a>(
        &self, 
        data: &'a [u8], 
        hint: Option<&str>
    ) -> Result<DecodedAudio<'a>, DecodeError>;
    
    /// 获取支持的格式列表
    fn supported_formats(&self) -> &[&str];
}
```

**关键点**：
- 使用 `Cow<'a, [f64]>` 实现按需拷贝
- 生命周期参数 `'a` 允许零拷贝返回
- 使用 `thiserror` 简化错误处理

### 2.2 存储Trait (storage/traits.rs)

```rust
// rust/src/storage/traits.rs

use std::collections::HashMap;

/// 音频元数据
#[derive(Debug, Clone)]
pub struct AudioMetadata {
    pub sample_rate: u32,
    pub channels: u16,
    pub duration_samples: usize,
}

/// 音频数据
#[derive(Debug, Clone)]
pub struct AudioData {
    pub samples: Vec<f64>,
    pub metadata: AudioMetadata,
}

/// 存储错误
#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    #[error("Key not found: {0}")]
    KeyNotFound(String),
    
    #[error("Storage full")]
    StorageFull,
    
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
}

/// 音频存储trait
/// 
/// 类型参数K是键的类型（默认为String）
pub trait AudioStorage<K = String> {
    /// 数据引用类型（必须可以转换为&[f64]）
    type DataRef<'a>: AsRef<[f64]> where Self: 'a;
    
    /// 存储音频数据
    fn store(&mut self, key: K, audio: AudioData) -> Result<(), StorageError>;
    
    /// 获取音频数据引用（零拷贝）
    fn get<'a>(&'a self, key: &K) -> Option<Self::DataRef<'a>>;
    
    /// 获取元数据
    fn get_metadata(&self, key: &K) -> Option<&AudioMetadata>;
    
    /// 删除数据
    fn remove(&mut self, key: &K) -> Option<AudioData>;
    
    /// 检查键是否存在
    fn contains(&self, key: &K) -> bool;
    
    /// 获取存储的数据数量
    fn len(&self) -> usize;
    
    /// 检查是否为空
    fn is_empty(&self) -> bool {
        self.len() == 0
    }
}
```

**关键点**：
- 关联类型 `DataRef<'a>` 允许不同的引用类型
- `AsRef<[f64]>` 确保可以转换为切片
- 泛型键类型 `K` 提供灵活性

### 2.3 变换Trait (transform/traits.rs)

```rust
// rust/src/transform/traits.rs

/// 信号变换trait
pub trait SignalTransform {
    /// 变换配置类型
    type Config;
    
    /// 输出类型
    type Output;
    
    /// 执行信号变换
    /// 
    /// # 参数
    /// - `input`: 输入信号
    /// - `config`: 变换配置
    /// 
    /// # 返回
    /// 变换结果
    fn transform(&self, input: &[f64], config: &Self::Config) -> Self::Output;
    
    /// 是否支持流式处理
    fn supports_streaming(&self) -> bool {
        false
    }
}
```

**关键点**：
- 关联类型提供灵活性
- 简单的接口易于实现
- 默认方法减少样板代码

### 2.4 缓存Trait (cache/traits.rs)

```rust
// rust/src/cache/traits.rs

use std::hash::Hash;

/// 缓存策略trait
pub trait CacheStrategy<K, V> {
    /// 获取缓存值
    fn get(&self, key: &K) -> Option<&V>;
    
    /// 获取可变缓存值
    fn get_mut(&mut self, key: &K) -> Option<&mut V>;
    
    /// 设置缓存值
    fn set(&mut self, key: K, value: V);
    
    /// 使缓存失效
    fn invalidate(&mut self, key: &K);
    
    /// 清空所有缓存
    fn clear(&mut self);
    
    /// 缓存大小
    fn len(&self) -> usize;
    
    /// 是否为空
    fn is_empty(&self) -> bool {
        self.len() == 0
    }
}
```

---

## 第三步：实现具体组件

### 3.1 Symphonia解码器实现

```rust
// rust/src/decoder/symphonia.rs

use super::traits::{AudioDecoder, DecodeError, DecodedAudio};
use std::borrow::Cow;
use std::io::Cursor;
use symphonia::core::audio::Signal;
use symphonia::core::codecs::DecoderOptions;
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

/// Symphonia解码器配置
#[derive(Debug, Clone)]
pub struct SymphoniaConfig {
    /// 是否验证校验和
    pub verify_checksum: bool,
}

impl Default for SymphoniaConfig {
    fn default() -> Self {
        Self {
            verify_checksum: false,
        }
    }
}

/// 基于Symphonia的音频解码器
pub struct SymphoniaDecoder {
    config: SymphoniaConfig,
}

impl SymphoniaDecoder {
    /// 创建新的Symphonia解码器
    pub fn new() -> Self {
        Self {
            config: SymphoniaConfig::default(),
        }
    }
    
    /// 使用自定义配置创建
    pub fn with_config(config: SymphoniaConfig) -> Self {
        Self { config }
    }
}

impl AudioDecoder for SymphoniaDecoder {
    fn decode<'a>(
        &self,
        data: &'a [u8],
        hint: Option<&str>,
    ) -> Result<DecodedAudio<'a>, DecodeError> {
        // 创建媒体源
        let cursor = Cursor::new(data);
        let source = Box::new(cursor);
        let mss = MediaSourceStream::new(source, Default::default());
        
        // 设置格式提示
        let mut hint_obj = Hint::new();
        if let Some(ext) = hint {
            hint_obj.with_extension(ext);
        }
        
        // 探测格式
        let probed = symphonia::default::get_probe()
            .format(
                &hint_obj,
                mss,
                &FormatOptions::default(),
                &MetadataOptions::default(),
            )
            .map_err(|e| DecodeError::DecodeFailed(format!("Probe failed: {}", e)))?;
        
        let mut format_reader = probed.format;
        
        // 查找音频轨道
        let track = format_reader
            .tracks()
            .iter()
            .find(|t| t.codec_params.sample_rate.is_some())
            .ok_or_else(|| DecodeError::DecodeFailed("No audio track found".to_string()))?;
        
        let sample_rate = track.codec_params.sample_rate.unwrap();
        let channels = track.codec_params.channels.map(|c| c.count() as u16).unwrap_or(1);
        let track_id = track.id;
        
        // 创建解码器
        let mut decoder = symphonia::default::get_codecs()
            .make(&track.codec_params, &DecoderOptions::default())
            .map_err(|e| DecodeError::DecodeFailed(format!("Decoder init failed: {}", e)))?;
        
        // 解码所有数据
        let mut samples = Vec::new();
        
        loop {
            // 读取数据包
            let packet = match format_reader.next_packet() {
                Ok(p) => p,
                Err(symphonia::core::errors::Error::ResetRequired) => continue,
                Err(symphonia::core::errors::Error::IoError(ref e))
                    if e.kind() == std::io::ErrorKind::UnexpectedEof =>
                {
                    break;
                }
                Err(e) => {
                    return Err(DecodeError::DecodeFailed(format!("Packet read error: {}", e)))
                }
            };
            
            // 跳过非目标轨道
            if packet.track_id() != track_id {
                continue;
            }
            
            // 解码数据包
            match decoder.decode(&packet) {
                Ok(decoded) => {
                    let spec = decoded.spec();
                    let duration = decoded.capacity();
                    
                    // 转换为f64
                    let mut audio_buffer: symphonia::core::audio::AudioBuffer<f64> =
                        symphonia::core::audio::AudioBuffer::new(duration as u64, *spec);
                    decoded.convert(&mut audio_buffer);
                    
                    // 提取样本
                    for channel_idx in 0..spec.channels.count() {
                        for &sample in audio_buffer.chan(channel_idx) {
                            samples.push(sample);
                        }
                    }
                }
                Err(e) => {
                    eprintln!("Decode error: {:?}", e);
                    // 继续处理其他数据包
                }
            }
        }
        
        Ok(DecodedAudio {
            samples: Cow::Owned(samples),
            sample_rate,
            channels,
        })
    }
    
    fn supported_formats(&self) -> &[&str] {
        &["mp3", "wav", "flac", "ogg", "aac", "m4a"]
    }
}

impl Default for SymphoniaDecoder {
    fn default() -> Self {
        Self::new()
    }
}
```

### 3.2 内存存储实现

```rust
// rust/src/storage/memory.rs

use super::traits::{AudioData, AudioMetadata, AudioStorage, StorageError};
use std::collections::HashMap;

/// 基于HashMap的内存存储
pub struct MemoryStorage {
    data: HashMap<String, AudioData>,
}

impl MemoryStorage {
    /// 创建新的内存存储
    pub fn new() -> Self {
        Self {
            data: HashMap::new(),
        }
    }
    
    /// 使用指定容量创建
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            data: HashMap::with_capacity(capacity),
        }
    }
}

impl AudioStorage for MemoryStorage {
    type DataRef<'a> = &'a [f64];
    
    fn store(&mut self, key: String, audio: AudioData) -> Result<(), StorageError> {
        self.data.insert(key, audio);
        Ok(())
    }
    
    fn get<'a>(&'a self, key: &String) -> Option<Self::DataRef<'a>> {
        self.data.get(key).map(|d| d.samples.as_slice())
    }
    
    fn get_metadata(&self, key: &String) -> Option<&AudioMetadata> {
        self.data.get(key).map(|d| &d.metadata)
    }
    
    fn remove(&mut self, key: &String) -> Option<AudioData> {
        self.data.remove(key)
    }
    
    fn contains(&self, key: &String) -> bool {
        self.data.contains_key(key)
    }
    
    fn len(&self) -> usize {
        self.data.len()
    }
}

impl Default for MemoryStorage {
    fn default() -> Self {
        Self::new()
    }
}
```

### 3.3 FFT变换实现

```rust
// rust/src/transform/fft.rs

use super::traits::SignalTransform;
use num_complex::Complex;
use rayon::prelude::*;
use rustfft::FftPlanner;
use std::sync::{Arc, Mutex};

/// FFT配置
#[derive(Debug, Clone)]
pub struct FftConfig {
    /// 帧大小（必须是2的幂）
    pub frame_size: usize,
    /// 窗函数（可选）
    pub window: Option<WindowFunction>,
}

/// 窗函数类型
#[derive(Debug, Clone, Copy)]
pub enum WindowFunction {
    Hamming,
    Hanning,
    Blackman,
}

impl WindowFunction {
    /// 应用窗函数
    pub fn apply(&self, data: &[f64]) -> Vec<f64> {
        let n = data.len();
        match self {
            WindowFunction::Hamming => data
                .iter()
                .enumerate()
                .map(|(i, &x)| x * (0.54 - 0.46 * (2.0 * std::f64::consts::PI * i as f64 / n as f64).cos()))
                .collect(),
            WindowFunction::Hanning => data
                .iter()
                .enumerate()
                .map(|(i, &x)| x * (0.5 - 0.5 * (2.0 * std::f64::consts::PI * i as f64 / n as f64).cos()))
                .collect(),
            WindowFunction::Blackman => data
                .iter()
                .enumerate()
                .map(|(i, &x)| {
                    x * (0.42 - 0.5 * (2.0 * std::f64::consts::PI * i as f64 / n as f64).cos()
                        + 0.08 * (4.0 * std::f64::consts::PI * i as f64 / n as f64).cos())
                })
                .collect(),
        }
    }
}

/// FFT变换器
pub struct FftTransform {
    planner: Arc<Mutex<FftPlanner<f64>>>,
}

impl FftTransform {
    /// 创建新的FFT变换器
    pub fn new() -> Self {
        Self {
            planner: Arc::new(Mutex::new(FftPlanner::new())),
        }
    }
}

impl SignalTransform for FftTransform {
    type Config = FftConfig;
    type Output = Vec<f64>;
    
    fn transform(&self, input: &[f64], config: &Self::Config) -> Self::Output {
        let frame_size = config.frame_size;
        let total_process_len = (input.len() / frame_size) * frame_size;
        
        if total_process_len == 0 {
            return Vec::new();
        }
        
        let data_to_process = &input[0..total_process_len];
        
        // 并行处理每一帧
        let results: Vec<f64> = data_to_process
            .par_chunks(frame_size)
            .flat_map(|chunk| {
                // 应用窗函数（如果有）
                let windowed = if let Some(window) = &config.window {
                    window.apply(chunk)
                } else {
                    chunk.to_vec()
                };
                
                // 转换为复数
                let mut complex_data: Vec<Complex<f64>> = windowed
                    .iter()
                    .map(|&x| Complex::new(x, 0.0))
                    .collect();
                
                // 执行FFT
                let planner = self.planner.lock().unwrap();
                let fft = planner.plan_fft_forward(frame_size);
                drop(planner);  // 释放锁
                
                fft.process(&mut complex_data);
                
                // 计算幅度谱
                complex_data
                    .into_iter()
                    .take(frame_size)
                    .map(|c| c.norm())
                    .collect::<Vec<f64>>()
            })
            .collect();
        
        results
    }
}

impl Default for FftTransform {
    fn default() -> Self {
        Self::new()
    }
}
```

### 3.4 智能缓存实现

```rust
// rust/src/cache/smart_cache.rs

use super::traits::CacheStrategy;
use std::collections::HashMap;
use std::hash::Hash;
use std::time::Instant;

/// 缓存驱逐策略
#[derive(Debug, Clone, Copy)]
pub enum EvictionStrategy {
    /// 最近最少使用
    Lru,
    /// 最不经常使用
    Lfu,
    /// 先进先出
    Fifo,
}

/// 缓存条目
struct CacheEntry<V> {
    value: V,
    access_count: usize,
    last_access: Instant,
    insert_time: Instant,
}

/// 智能缓存
pub struct SmartCache<K, V> {
    cache: HashMap<K, CacheEntry<V>>,
    max_size: usize,
    strategy: EvictionStrategy,
}

impl<K: Eq + Hash + Clone, V> SmartCache<K, V> {
    /// 创建新的智能缓存
    pub fn new(max_size: usize, strategy: EvictionStrategy) -> Self {
        Self {
            cache: HashMap::with_capacity(max_size),
            max_size,
            strategy,
        }
    }
    
    /// 驱逐一个条目
    fn evict_one(&mut self) {
        if self.cache.is_empty() {
            return;
        }
        
        let key_to_remove = match self.strategy {
            EvictionStrategy::Lru => {
                // 找到最久未访问的
                self.cache
                    .iter()
                    .min_by_key(|(_, entry)| entry.last_access)
                    .map(|(k, _)| k.clone())
            }
            EvictionStrategy::Lfu => {
                // 找到访问次数最少的
                self.cache
                    .iter()
                    .min_by_key(|(_, entry)| entry.access_count)
                    .map(|(k, _)| k.clone())
            }
            EvictionStrategy::Fifo => {
                // 找到最早插入的
                self.cache
                    .iter()
                    .min_by_key(|(_, entry)| entry.insert_time)
                    .map(|(k, _)| k.clone())
            }
        };
        
        if let Some(key) = key_to_remove {
            self.cache.remove(&key);
        }
    }
}

impl<K: Eq + Hash + Clone, V> CacheStrategy<K, V> for SmartCache<K, V> {
    fn get(&self, key: &K) -> Option<&V> {
        self.cache.get(key).map(|entry| &entry.value)
    }
    
    fn get_mut(&mut self, key: &K) -> Option<&mut V> {
        self.cache.get_mut(key).map(|entry| {
            entry.access_count += 1;
            entry.last_access = Instant::now();
            &mut entry.value
        })
    }
    
    fn set(&mut self, key: K, value: V) {
        // 如果已存在，更新
        if self.cache.contains_key(&key) {
            if let Some(entry) = self.cache.get_mut(&key) {
                entry.value = value;
                entry.access_count += 1;
                entry.last_access = Instant::now();
                return;
            }
        }
        
        // 如果缓存满了，驱逐一个
        if self.cache.len() >= self.max_size {
            self.evict_one();
        }
        
        // 插入新条目
        let now = Instant::now();
        self.cache.insert(
            key,
            CacheEntry {
                value,
                access_count: 1,
                last_access: now,
                insert_time: now,
            },
        );
    }
    
    fn invalidate(&mut self, key: &K) {
        self.cache.remove(key);
    }
    
    fn clear(&mut self) {
        self.cache.clear();
    }
    
    fn len(&self) -> usize {
        self.cache.len()
    }
}
```

---

## 第四步：构建核心引擎

### 4.1 核心类型定义 (core/types.rs)

```rust
// rust/src/core/types.rs

/// 图表数据（与Flutter端兼容）
#[derive(Debug, Clone)]
pub struct ChartData {
    pub index: Vec<f64>,
    pub data: Vec<f64>,
}

/// 处理器配置
#[derive(Debug, Clone)]
pub struct ProcessorConfig {
    /// 是否启用缓存
    pub enable_cache: bool,
    /// 并行处理阈值（样本数）
    pub parallel_threshold: usize,
}

impl Default for ProcessorConfig {
    fn default() -> Self {
        Self {
            enable_cache: true,
            parallel_threshold: 10000,
        }
    }
}
```

### 4.2 核心引擎 (core/engine.rs)

```rust
// rust/src/core/engine.rs

use crate::cache::traits::CacheStrategy;
use crate::core::types::{ChartData, ProcessorConfig};
use crate::decoder::traits::{AudioDecoder, DecodeError};
use crate::storage::traits::{AudioData, AudioMetadata, AudioStorage, StorageError};
use crate::transform::traits::SignalTransform;
use std::sync::{Arc, RwLock};

/// 音频处理引擎（泛型，零开销）
pub struct AudioProcessorEngine<D, S, T, C>
where
    D: AudioDecoder,
    S: AudioStorage,
    T: SignalTransform,
    C: CacheStrategy<String, T::Output>,
{
    decoder: D,
    storage: Arc<RwLock<S>>,
    transformer: T,
    cache: Arc<RwLock<C>>,
    config: ProcessorConfig,
}

impl<D, S, T, C> AudioProcessorEngine<D, S, T, C>
where
    D: AudioDecoder + Send + Sync,
    S: AudioStorage + Send + Sync,
    T: SignalTransform + Send + Sync,
    C: CacheStrategy<String, T::Output> + Send + Sync,
    T::Output: Clone,
{
    /// 创建新引擎
    pub fn new(
        decoder: D,
        storage: S,
        transformer: T,
        cache: C,
        config: ProcessorConfig,
    ) -> Self {
        Self {
            decoder,
            storage: Arc::new(RwLock::new(storage)),
            transformer,
            cache: Arc::new(RwLock::new(cache)),
            config,
        }
    }
    
    /// 加载音频文件
    pub async fn load_audio(
        &self,
        key: String,
        data: &[u8],
        hint: Option<&str>,
    ) -> Result<(), String> {
        // 解码
        let decoded = self.decoder.decode(data, hint)
            .map_err(|e| format!("Decode error: {}", e))?;
        
        // 构造音频数据
        let audio_data = AudioData {
            samples: decoded.samples.into_owned(),
            metadata: AudioMetadata {
                sample_rate: decoded.sample_rate,
                channels: decoded.channels,
                duration_samples: decoded.samples.len(),
            },
        };
        
        // 存储
        let mut storage = self.storage.write().unwrap();
        storage.store(key, audio_data)
            .map_err(|e| format!("Storage error: {}", e))?;
        
        Ok(())
    }
    
    /// 获取音频数据切片
    pub fn get_audio_data_len(&self, key: &str) -> usize {
        let storage = self.storage.read().unwrap();
        storage.get(&key.to_string())
            .map(|data| data.as_ref().len())
            .unwrap_or(0)
    }
    
    /// 获取采样率
    pub fn get_sample_rate(&self, key: &str) -> u32 {
        let storage = self.storage.read().unwrap();
        storage.get_metadata(&key.to_string())
            .map(|meta| meta.sample_rate)
            .unwrap_or(0)
    }
    
    /// 获取变换结果（带缓存）
    pub async fn get_transform(
        &self,
        key: String,
        config: T::Config,
    ) -> Option<T::Output> {
        // 检查缓存
        if self.config.enable_cache {
            let cache = self.cache.read().unwrap();
            if let Some(cached) = cache.get(&key) {
                return Some(cached.clone());
            }
        }
        
        // 获取数据
        let storage = self.storage.read().unwrap();
        let data = storage.get(&key)?;
        let data_slice = data.as_ref();
        
        // 执行变换
        let result = self.transformer.transform(data_slice, &config);
        
        // 更新缓存
        if self.config.enable_cache {
            let mut cache = self.cache.write().unwrap();
            cache.set(key, result.clone());
        }
        
        Some(result)
    }
    
    /// 检查是否包含某个键
    pub fn contains(&self, key: &str) -> bool {
        let storage = self.storage.read().unwrap();
        storage.contains(&key.to_string())
    }
}
```

### 4.3 构建器 (core/builder.rs)

```rust
// rust/src/core/builder.rs

use super::engine::AudioProcessorEngine;
use super::types::ProcessorConfig;
use crate::cache::traits::CacheStrategy;
use crate::decoder::traits::AudioDecoder;
use crate::storage::traits::AudioStorage;
use crate::transform::traits::SignalTransform;

/// 音频处理器构建器
pub struct AudioProcessorBuilder<D = (), S = (), T = (), C = ()> {
    decoder: D,
    storage: S,
    transformer: T,
    cache: C,
    config: ProcessorConfig,
}

impl AudioProcessorBuilder {
    pub fn new() -> AudioProcessorBuilder<(), (), (), ()> {
        AudioProcessorBuilder {
            decoder: (),
            storage: (),
            transformer: (),
            cache: (),
            config: ProcessorConfig::default(),
        }
    }
}

impl<S, T, C> AudioProcessorBuilder<(), S, T, C> {
    pub fn with_decoder<D: AudioDecoder>(
        self,
        decoder: D,
    ) -> AudioProcessorBuilder<D, S, T, C> {
        AudioProcessorBuilder {
            decoder,
            storage: self.storage,
            transformer: self.transformer,
            cache: self.cache,
            config: self.config,
        }
    }
}

impl<D, T, C> AudioProcessorBuilder<D, (), T, C> {
    pub fn with_storage<S: AudioStorage>(
        self,
        storage: S,
    ) -> AudioProcessorBuilder<D, S, T, C> {
        AudioProcessorBuilder {
            decoder: self.decoder,
            storage,
            transformer: self.transformer,
            cache: self.cache,
            config: self.config,
        }
    }
}

impl<D, S, C> AudioProcessorBuilder<D, S, (), C> {
    pub fn with_transformer<T: SignalTransform>(
        self,
        transformer: T,
    ) -> AudioProcessorBuilder<D, S, T, C> {
        AudioProcessorBuilder {
            decoder: self.decoder,
            storage: self.storage,
            transformer,
            cache: self.cache,
            config: self.config,
        }
    }
}

impl<D, S, T> AudioProcessorBuilder<D, S, T, ()> {
    pub fn with_cache<C: CacheStrategy<String, T::Output>>(
        self,
        cache: C,
    ) -> AudioProcessorBuilder<D, S, T, C> {
        AudioProcessorBuilder {
            decoder: self.decoder,
            storage: self.storage,
            transformer: self.transformer,
            cache,
            config: self.config,
        }
    }
}

impl<D, S, T, C> AudioProcessorBuilder<D, S, T, C> {
    pub fn with_config(mut self, config: ProcessorConfig) -> Self {
        self.config = config;
        self
    }
}

impl<D, S, T, C> AudioProcessorBuilder<D, S, T, C>
where
    D: AudioDecoder + Send + Sync,
    S: AudioStorage + Send + Sync,
    T: SignalTransform + Send + Sync,
    C: CacheStrategy<String, T::Output> + Send + Sync,
    T::Output: Clone,
{
    pub fn build(self) -> AudioProcessorEngine<D, S, T, C> {
        AudioProcessorEngine::new(
            self.decoder,
            self.storage,
            self.transformer,
            self.cache,
            self.config,
        )
    }
}
```

---

## 第五步：迁移现有代码

### 5.1 更新API层 (api/audio_processor.rs)

```rust
// rust/src/api/audio_processor.rs

use crate::cache::smart_cache::{EvictionStrategy, SmartCache};
use crate::core::builder::AudioProcessorBuilder;
use crate::core::engine::AudioProcessorEngine;
use crate::core::types::{ChartData, ProcessorConfig};
use crate::decoder::symphonia::SymphoniaDecoder;
use crate::storage::memory::MemoryStorage;
use crate::transform::fft::{FftConfig, FftTransform};

// 类型别名
type DefaultEngine = AudioProcessorEngine<
    SymphoniaDecoder,
    MemoryStorage,
    FftTransform,
    SmartCache<String, Vec<f64>>,
>;

/// AudioProcessor - Flutter Bridge 适配层
#[frb(opaque)]
pub struct AudioProcessor {
    engine: DefaultEngine,
    frame_size: usize,
}

impl AudioProcessor {
    /// 创建新的处理器（默认配置）
    pub async fn new() -> Self {
        let engine = AudioProcessorBuilder::new()
            .with_decoder(SymphoniaDecoder::new())
            .with_storage(MemoryStorage::new())
            .with_transformer(FftTransform::new())
            .with_cache(SmartCache::new(100, EvictionStrategy::Lru))
            .with_config(ProcessorConfig {
                enable_cache: true,
                parallel_threshold: 10000,
            })
            .build();
        
        Self {
            engine,
            frame_size: 512,
        }
    }
    
    /// 添加音频文件
    pub async fn add(&mut self, file_path: String, file_data: Vec<u8>) {
        let hint = file_path
            .rfind('.')
            .map(|i| &file_path[i + 1..]);
        
        if let Err(e) = self.engine.load_audio(file_path, &file_data, hint).await {
            eprintln!("Failed to load audio: {}", e);
        }
    }
    
    /// 获取音频数据长度
    pub fn audio_data_len(&self, file_path: String) -> usize {
        self.engine.get_audio_data_len(&file_path)
    }
    
    /// 获取采样率
    pub fn get_sample_rate(&self, file_path: String) -> u32 {
        self.engine.get_sample_rate(&file_path)
    }
    
    /// 获取帧大小
    pub fn get_frame_size(&self, _file_path: String) -> usize {
        self.frame_size
    }
    
    /// 设置帧大小
    pub fn set_frame_size(&mut self, frame_size: usize) {
        self.frame_size = frame_size;
    }
    
    /// 获取FFT数据
    pub async fn get_fft_data(
        &self,
        file_path: String,
        _offset: (f64, f64),
        _index: (usize, usize),
    ) -> ChartData {
        let config = FftConfig {
            frame_size: self.frame_size,
            window: None,
        };
        
        if let Some(result) = self.engine.get_transform(file_path, config).await {
            ChartData {
                index: vec![],
                data: result,
            }
        } else {
            ChartData {
                index: vec![],
                data: vec![],
            }
        }
    }
    
    // 其他方法...
}
```

---

## 测试策略

### Mock解码器用于测试

```rust
// rust/src/decoder/mock.rs

use super::traits::{AudioDecoder, DecodeError, DecodedAudio};
use std::borrow::Cow;

pub struct MockDecoder {
    test_data: Vec<f64>,
}

impl MockDecoder {
    pub fn new() -> Self {
        Self {
            test_data: vec![1.0, 2.0, 3.0, 4.0, 5.0],
        }
    }
    
    pub fn with_data(test_data: Vec<f64>) -> Self {
        Self { test_data }
    }
}

impl AudioDecoder for MockDecoder {
    fn decode<'a>(
        &self,
        _data: &'a [u8],
        _hint: Option<&str>,
    ) -> Result<DecodedAudio<'a>, DecodeError> {
        Ok(DecodedAudio {
            samples: Cow::Owned(self.test_data.clone()),
            sample_rate: 44100,
            channels: 1,
        })
    }
    
    fn supported_formats(&self) -> &[&str] {
        &["mock"]
    }
}
```

---

## 性能验证

### 添加依赖到Cargo.toml

```toml
[dev-dependencies]
criterion = "0.5"
```

### 基准测试

```rust
// benches/audio_processing.rs

use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_decode(c: &mut Criterion) {
    // 基准测试代码
}

criterion_group!(benches, benchmark_decode);
criterion_main!(benches);
```

---

## 总结

这个实施指南提供了：
1. ✅ 清晰的目录结构
2. ✅ 完整的代码实现示例
3. ✅ 测试策略
4. ✅ 性能验证方法

**下一步**：按照这个指南逐步实施，每实施一个模块就进行测试和验证。
