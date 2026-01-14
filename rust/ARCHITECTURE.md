# Rust 架构重构 - 零成本抽象设计

## 🎯 架构目标

完全重构 Rust 代码，实现：
- **零成本抽象**：抽象不带来运行时开销
- **高度解耦**：模块化、可替换组件
- **无限扩展性**：轻松添加新图表类型

## 📁 目录结构

```
rust/src/
├── chart/          # 图表核心抽象
│   ├── types.rs    # 图表类型、数据结构、配置
│   ├── processor.rs # ChartProcessor trait 和注册表
│   ├── audio_processors.rs # 音频图表处理器实现
│   └── mod.rs
├── data/           # 数据处理层
│   ├── audio.rs    # 音频数据结构和处理 trait
│   ├── impls.rs    # 具体实现（Symphonia、RustFFT等）
│   └── mod.rs
├── storage/        # 存储和缓存层
│   ├── cache.rs    # 缓存 trait 和实现
│   └── mod.rs
├── api.rs          # 统一对外接口
├── api/            # API兼容层
│   ├── audio_processor.rs # 向后兼容枚举
│   └── util.rs     # 工具函数
└── lib.rs          # 模块导出
```

## 🔧 核心抽象设计

### 1. 图表类型系统（可扩展）

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChartType {
    AudioWaveform,    // 音频波形
    FftSpectrum,      // FFT频谱
    Spectrogram,      // 频谱图（预留扩展）
    WaveletTransform, // 小波变换（预留扩展）
    // ... 可以无限扩展
}
```

### 2. 零成本抽象 trait

```rust
// 图表处理器 - 核心抽象
pub trait ChartProcessor: Send + Sync {
    fn process(&self, request: &ChartRequest) -> Result<ChartData, Box<dyn std::error::Error>>;
    fn supported_types(&self) -> Vec<ChartType>;
}

// 数据加载器 - 可替换
pub trait AudioLoader: Send + Sync {
    type Error: std::error::Error;
    fn load_from_bytes(&self, data: &[u8], hint: &str) -> Result<AudioData, Self::Error>;
}

// FFT处理器 - 可替换
pub trait FftProcessor: Send + Sync {
    fn process_fft(&self, audio_data: &AudioData, frame_size: usize) -> Result<Vec<f32>, Box<dyn std::error::Error>>;
    fn process_fft_parallel(&self, audio_data: &AudioData, frame_size: usize) -> Result<Vec<f32>, Box<dyn std::error::Error>>;
}

// 缓存 - 可替换
pub trait Cache<Key, Value>: Send + Sync {
    fn get(&self, key: &Key) -> Option<&Value>;
    fn insert(&mut self, key: Key, value: Value) -> bool;
    fn clear(&mut self);
}
```

### 3. 注册表模式

```rust
pub struct ChartProcessorRegistry {
    processors: HashMap<ChartType, Box<dyn ChartProcessor>>,
}

impl ChartProcessorRegistry {
    pub fn register<P: ChartProcessor + 'static>(&mut self, processor: P) -> Result<(), String> {
        // 注册处理器
    }

    pub fn process(&self, request: &ChartRequest) -> Result<ChartData, Box<dyn std::error::Error>> {
        // 统一处理接口
    }
}
```

## 🚀 使用方式

### 添加新图表类型

1. **扩展 ChartType 枚举**
```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChartType {
    // ... 现有类型
    CustomChart, // 新图表类型
}
```

2. **实现 ChartProcessor**
```rust
pub struct CustomChartProcessor;

impl ChartProcessor for CustomChartProcessor {
    fn process(&self, request: &ChartRequest) -> Result<ChartData, Box<dyn std::error::Error>> {
        // 自定义处理逻辑
    }

    fn supported_types(&self) -> Vec<ChartType> {
        vec![ChartType::CustomChart]
    }
}
```

3. **注册到系统**
```rust
let mut registry = ChartProcessorRegistry::new();
registry.register(CustomChartProcessor).expect("注册失败");
```

### 替换组件实现

```rust
// 替换音频加载器
let custom_loader = CustomAudioLoader::new();
let processor = AudioWaveformProcessor::new(custom_loader, sampler);

// 替换FFT处理器
let custom_fft = CustomFftProcessor::new();
let processor = FftSpectrumProcessor::new(loader, custom_fft, cache, sampler);

// 替换缓存策略
let custom_cache = RedisCache::new(redis_client);
let processor = FftSpectrumProcessor::new(loader, fft_processor, custom_cache, sampler);
```

## ⚡ 性能特性

### 零成本抽象
- **编译时多态**：泛型在编译时就被解析，无运行时开销
- **静态分发**：避免动态 trait 对象开销（除错误处理）
- **内联优化**：trait 方法可被内联优化

### 并发安全
- 所有组件实现 `Send + Sync`
- 线程安全的缓存和存储
- 并行FFT处理支持

### 内存效率
- `Arc<Vec<f32>>` 避免不必要拷贝
- 缓存减少重复计算
- 采样优化大数据集显示

## 🔄 向后兼容

保持与现有 Flutter 代码的完全兼容：
- `AudioProcessor` 接口保持不变
- FFI 绑定自动更新
- 无需修改 Dart 代码

## 🎨 扩展示例

### 添加频谱图（Spectrogram）
```rust
// 1. 扩展类型
ChartType::Spectrogram

// 2. 实现处理器
pub struct SpectrogramProcessor<L, F, C>
where
    L: AudioLoader,
    F: FftProcessor,
    C: Cache<String, Vec<Vec<f32>>>, // 2D缓存
{
    loader: L,
    fft_processor: F,
    cache: C,
    time_window: usize,
    freq_bins: usize,
}

// 3. 注册使用
registry.register(SpectrogramProcessor::new(loader, fft, cache, 1024, 256));
```

### 添加小波变换
```rust
// 类似模式，替换FFT处理器为小波处理器
pub trait WaveletProcessor {
    fn process_wavelet(&self, data: &[f32]) -> Result<Vec<f32>, Box<dyn std::error::Error>>;
}
```

## 🏗️ 架构优势

1. **无限扩展性**：添加新图表类型只需实现 trait
2. **组件可替换**：可轻松替换加载器、处理器、缓存等
3. **类型安全**：编译时保证组件兼容性
4. **高性能**：零成本抽象 + 并发优化
5. **易维护**：清晰的模块边界和职责分离
6. **向后兼容**：无缝升级现有代码

这个架构为音频可视化工具提供了坚实的基础，可以轻松扩展到更多图表类型和数据处理需求。