# 运行时切换 SignalTransform 实现指南
# Runtime Switching Guide for SignalTransform Implementations

## 问题 / Problem

用户需求：**不只是做 FFT**，需要在运行时动态切换不同的信号变换算法（FFT、STFT、小波变换等）。

原架构设计使用泛型，虽然零开销，但在编译时确定类型，**无法运行时切换**。

---

## 解决方案 / Solutions

### 方案 1: 使用 Trait Object (动态分发)

最直接的方案：使用 `Box<dyn SignalTransform>` 实现运行时多态。

#### 优点
- ✅ 运行时灵活切换算法
- ✅ 实现简单直观
- ✅ 支持动态加载插件

#### 缺点
- ⚠️ 有轻微运行时开销（虚函数表查找）
- ⚠️ 需要 trait object 安全的设计

#### 实现代码

```rust
// 1. 确保 SignalTransform 是 object-safe
pub trait SignalTransform: Send + Sync {
    /// 变换配置（使用 Box<dyn Any> 或枚举）
    fn transform(&self, input: &[f64], config: &TransformConfig) -> Vec<f64>;
    
    /// 算法名称
    fn name(&self) -> &str;
    
    /// 是否支持流式处理
    fn supports_streaming(&self) -> bool {
        false
    }
}

/// 统一的变换配置（支持所有算法）
#[derive(Debug, Clone)]
pub enum TransformConfig {
    Fft { frame_size: usize, window: Option<WindowFunction> },
    Stft { frame_size: usize, hop_size: usize, window: WindowFunction },
    Wavelet { wavelet_type: WaveletType, level: usize },
    Spectrogram { frame_size: usize, hop_size: usize },
}

// 2. FFT 实现
pub struct FftTransform {
    planner: Arc<Mutex<FftPlanner<f64>>>,
}

impl SignalTransform for FftTransform {
    fn transform(&self, input: &[f64], config: &TransformConfig) -> Vec<f64> {
        if let TransformConfig::Fft { frame_size, window } = config {
            // FFT 实现逻辑
            // ...
        } else {
            panic!("Invalid config for FftTransform");
        }
    }
    
    fn name(&self) -> &str {
        "FFT"
    }
}

// 3. STFT 实现
pub struct StftTransform;

impl SignalTransform for StftTransform {
    fn transform(&self, input: &[f64], config: &TransformConfig) -> Vec<f64> {
        if let TransformConfig::Stft { frame_size, hop_size, window } = config {
            // STFT 实现逻辑
            // ...
        } else {
            panic!("Invalid config for StftTransform");
        }
    }
    
    fn name(&self) -> &str {
        "STFT"
    }
    
    fn supports_streaming(&self) -> bool {
        true
    }
}

// 4. 小波变换实现
pub struct WaveletTransform;

impl SignalTransform for WaveletTransform {
    fn transform(&self, input: &[f64], config: &TransformConfig) -> Vec<f64> {
        if let TransformConfig::Wavelet { wavelet_type, level } = config {
            // 小波变换实现逻辑
            // ...
        } else {
            panic!("Invalid config for WaveletTransform");
        }
    }
    
    fn name(&self) -> &str {
        "Wavelet"
    }
}

// 5. 动态处理引擎（使用 trait object）
pub struct DynamicAudioProcessor {
    decoder: Box<dyn AudioDecoder>,
    storage: Arc<RwLock<Box<dyn AudioStorage>>>,
    transformer: Arc<RwLock<Box<dyn SignalTransform>>>,  // 可运行时切换
    cache: Arc<RwLock<HashMap<String, Vec<f64>>>>,
}

impl DynamicAudioProcessor {
    /// 创建新的动态处理器
    pub fn new() -> Self {
        Self {
            decoder: Box::new(SymphoniaDecoder::new()),
            storage: Arc::new(RwLock::new(Box::new(MemoryStorage::new()))),
            transformer: Arc::new(RwLock::new(Box::new(FftTransform::new()))),
            cache: Arc::new(RwLock::new(HashMap::new())),
        }
    }
    
    /// 运行时切换变换算法 ⭐
    pub fn set_transformer(&self, transformer: Box<dyn SignalTransform>) {
        let mut t = self.transformer.write().unwrap();
        *t = transformer;
        
        // 清空缓存（因为算法变了）
        self.cache.write().unwrap().clear();
    }
    
    /// 获取当前变换算法名称
    pub fn get_transformer_name(&self) -> String {
        let t = self.transformer.read().unwrap();
        t.name().to_string()
    }
    
    /// 执行变换
    pub async fn transform(&self, key: String, config: TransformConfig) -> Option<Vec<f64>> {
        // 检查缓存
        let cache_key = format!("{}_{:?}", key, config);
        {
            let cache = self.cache.read().unwrap();
            if let Some(cached) = cache.get(&cache_key) {
                return Some(cached.clone());
            }
        }
        
        // 获取数据
        let storage = self.storage.read().unwrap();
        let data = storage.get(&key)?;
        
        // 执行变换
        let transformer = self.transformer.read().unwrap();
        let result = transformer.transform(data.as_ref(), &config);
        
        // 更新缓存
        {
            let mut cache = self.cache.write().unwrap();
            cache.insert(cache_key, result.clone());
        }
        
        Some(result)
    }
}
```

#### 使用示例

```rust
// 创建处理器（默认使用 FFT）
let processor = DynamicAudioProcessor::new();

// 加载音频
processor.load_audio("file1.mp3", &audio_data).await;

// 使用 FFT
let fft_result = processor.transform(
    "file1.mp3".to_string(),
    TransformConfig::Fft { frame_size: 512, window: None }
).await;

// 运行时切换到 STFT ⭐
processor.set_transformer(Box::new(StftTransform));

// 现在使用 STFT
let stft_result = processor.transform(
    "file1.mp3".to_string(),
    TransformConfig::Stft { 
        frame_size: 512, 
        hop_size: 256, 
        window: WindowFunction::Hanning 
    }
).await;

// 再切换到小波变换 ⭐
processor.set_transformer(Box::new(WaveletTransform));

let wavelet_result = processor.transform(
    "file1.mp3".to_string(),
    TransformConfig::Wavelet { 
        wavelet_type: WaveletType::Daubechies4, 
        level: 3 
    }
).await;
```

---

### 方案 2: 枚举变换类型（零开销 + 运行时切换）

如果变换类型是已知且有限的，可以使用枚举实现零开销的运行时切换。

#### 优点
- ✅ 零运行时开销（编译器优化为分支）
- ✅ 运行时切换算法
- ✅ 类型安全

#### 缺点
- ⚠️ 添加新算法需要修改枚举
- ⚠️ 不支持动态插件

#### 实现代码

```rust
// 1. 枚举所有变换类型
pub enum Transform {
    Fft(FftTransform),
    Stft(StftTransform),
    Wavelet(WaveletTransform),
    Spectrogram(SpectrogramTransform),
}

impl Transform {
    /// 执行变换（根据类型分发）
    pub fn transform(&self, input: &[f64], config: &TransformConfig) -> Vec<f64> {
        match self {
            Transform::Fft(t) => t.transform(input, config),
            Transform::Stft(t) => t.transform(input, config),
            Transform::Wavelet(t) => t.transform(input, config),
            Transform::Spectrogram(t) => t.transform(input, config),
        }
    }
    
    pub fn name(&self) -> &str {
        match self {
            Transform::Fft(_) => "FFT",
            Transform::Stft(_) => "STFT",
            Transform::Wavelet(_) => "Wavelet",
            Transform::Spectrogram(_) => "Spectrogram",
        }
    }
}

// 2. 零开销处理引擎
pub struct ZeroCostAudioProcessor<D, S>
where
    D: AudioDecoder,
    S: AudioStorage,
{
    decoder: D,
    storage: Arc<RwLock<S>>,
    transformer: Arc<RwLock<Transform>>,  // 枚举类型，零开销
    cache: Arc<RwLock<HashMap<String, Vec<f64>>>>,
}

impl<D, S> ZeroCostAudioProcessor<D, S>
where
    D: AudioDecoder + Send + Sync,
    S: AudioStorage + Send + Sync,
{
    pub fn new(decoder: D, storage: S) -> Self {
        Self {
            decoder,
            storage: Arc::new(RwLock::new(storage)),
            transformer: Arc::new(RwLock::new(Transform::Fft(FftTransform::new()))),
            cache: Arc::new(RwLock::new(HashMap::new())),
        }
    }
    
    /// 运行时切换变换算法（零开销）⭐
    pub fn set_transformer(&self, transformer: Transform) {
        let mut t = self.transformer.write().unwrap();
        *t = transformer;
        self.cache.write().unwrap().clear();
    }
    
    /// 执行变换
    pub async fn transform(&self, key: String, config: TransformConfig) -> Option<Vec<f64>> {
        let storage = self.storage.read().unwrap();
        let data = storage.get(&key)?;
        
        let transformer = self.transformer.read().unwrap();
        let result = transformer.transform(data.as_ref(), &config);
        
        Some(result)
    }
}
```

#### 使用示例

```rust
let processor = ZeroCostAudioProcessor::new(
    SymphoniaDecoder::new(),
    MemoryStorage::new(),
);

// 运行时切换到 STFT（零开销）⭐
processor.set_transformer(Transform::Stft(StftTransform::new()));

// 运行时切换到小波变换（零开销）⭐
processor.set_transformer(Transform::Wavelet(WaveletTransform::new()));
```

---

### 方案 3: 混合方案（推荐）

结合泛型和 trait object 的优势。

#### 架构

```rust
// 1. 核心引擎仍使用泛型（零开销，编译时确定）
pub struct AudioProcessorEngine<D, S, T, C>
where
    D: AudioDecoder,
    S: AudioStorage,
    T: TransformManager,  // 变换管理器（可以是泛型或 trait object）
    C: CacheStrategy,
{ ... }

// 2. 变换管理器 trait
pub trait TransformManager: Send + Sync {
    fn transform(&self, input: &[f64], config: &TransformConfig) -> Vec<f64>;
    fn get_current(&self) -> String;
    fn set_current(&mut self, name: &str) -> Result<(), String>;
}

// 3. 动态变换管理器实现
pub struct DynamicTransformManager {
    transformers: HashMap<String, Box<dyn SignalTransform>>,
    current: String,
}

impl DynamicTransformManager {
    pub fn new() -> Self {
        let mut manager = Self {
            transformers: HashMap::new(),
            current: "fft".to_string(),
        };
        
        // 注册所有变换
        manager.register("fft", Box::new(FftTransform::new()));
        manager.register("stft", Box::new(StftTransform::new()));
        manager.register("wavelet", Box::new(WaveletTransform::new()));
        
        manager
    }
    
    pub fn register(&mut self, name: &str, transformer: Box<dyn SignalTransform>) {
        self.transformers.insert(name.to_string(), transformer);
    }
}

impl TransformManager for DynamicTransformManager {
    fn transform(&self, input: &[f64], config: &TransformConfig) -> Vec<f64> {
        let transformer = self.transformers.get(&self.current).unwrap();
        transformer.transform(input, config)
    }
    
    fn get_current(&self) -> String {
        self.current.clone()
    }
    
    fn set_current(&mut self, name: &str) -> Result<(), String> {
        if self.transformers.contains_key(name) {
            self.current = name.to_string();
            Ok(())
        } else {
            Err(format!("Transform '{}' not found", name))
        }
    }
}

// 4. 静态变换管理器（零开销）
pub struct StaticTransformManager {
    current: Transform,  // 枚举
}

impl TransformManager for StaticTransformManager {
    fn transform(&self, input: &[f64], config: &TransformConfig) -> Vec<f64> {
        self.current.transform(input, config)
    }
    
    fn get_current(&self) -> String {
        self.current.name().to_string()
    }
    
    fn set_current(&mut self, name: &str) -> Result<(), String> {
        self.current = match name {
            "fft" => Transform::Fft(FftTransform::new()),
            "stft" => Transform::Stft(StftTransform::new()),
            "wavelet" => Transform::Wavelet(WaveletTransform::new()),
            _ => return Err(format!("Unknown transform: {}", name)),
        };
        Ok(())
    }
}
```

#### 使用示例

```rust
// 选项 1: 使用动态管理器（灵活，支持插件）
let processor = AudioProcessorBuilder::new()
    .with_decoder(SymphoniaDecoder::new())
    .with_storage(MemoryStorage::new())
    .with_transformer(DynamicTransformManager::new())  // 动态
    .with_cache(SmartCache::new(100, Lru))
    .build();

// 运行时切换
processor.set_transformer("stft")?;
processor.set_transformer("wavelet")?;

// 选项 2: 使用静态管理器（零开销）
let processor = AudioProcessorBuilder::new()
    .with_decoder(SymphoniaDecoder::new())
    .with_storage(MemoryStorage::new())
    .with_transformer(StaticTransformManager::new())  // 静态
    .with_cache(SmartCache::new(100, Lru))
    .build();

// 运行时切换（零开销）
processor.set_transformer("stft")?;
```

---

## Flutter Bridge 适配

### 暴露给 Flutter 的 API

```rust
#[frb(opaque)]
pub struct AudioProcessor {
    engine: DynamicAudioProcessor,  // 或 ZeroCostAudioProcessor
}

impl AudioProcessor {
    pub async fn new() -> Self {
        Self {
            engine: DynamicAudioProcessor::new(),
        }
    }
    
    /// 设置变换算法 ⭐
    pub fn set_transform_type(&mut self, transform_type: String) -> Result<(), String> {
        match transform_type.as_str() {
            "fft" => {
                self.engine.set_transformer(Box::new(FftTransform::new()));
                Ok(())
            }
            "stft" => {
                self.engine.set_transformer(Box::new(StftTransform::new()));
                Ok(())
            }
            "wavelet" => {
                self.engine.set_transformer(Box::new(WaveletTransform::new()));
                Ok(())
            }
            "spectrogram" => {
                self.engine.set_transformer(Box::new(SpectrogramTransform::new()));
                Ok(())
            }
            _ => Err(format!("Unknown transform type: {}", transform_type)),
        }
    }
    
    /// 获取当前变换类型
    pub fn get_transform_type(&self) -> String {
        self.engine.get_transformer_name()
    }
    
    /// 获取支持的变换类型列表
    pub fn get_supported_transforms(&self) -> Vec<String> {
        vec![
            "fft".to_string(),
            "stft".to_string(),
            "wavelet".to_string(),
            "spectrogram".to_string(),
        ]
    }
    
    /// 执行变换（统一接口）
    pub async fn transform_audio(
        &self,
        file_path: String,
        config: TransformConfigDto,  // 从 Flutter 传来的配置
    ) -> ChartData {
        let config = config.into_transform_config();  // 转换为 Rust 配置
        
        if let Some(result) = self.engine.transform(file_path, config).await {
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
}

/// 从 Flutter 传递的配置 DTO
#[derive(Debug, Clone)]
pub struct TransformConfigDto {
    pub transform_type: String,
    pub frame_size: usize,
    pub hop_size: Option<usize>,
    pub window_type: Option<String>,
    pub level: Option<usize>,
}

impl TransformConfigDto {
    fn into_transform_config(self) -> TransformConfig {
        match self.transform_type.as_str() {
            "fft" => TransformConfig::Fft {
                frame_size: self.frame_size,
                window: self.window_type.map(|w| parse_window(&w)),
            },
            "stft" => TransformConfig::Stft {
                frame_size: self.frame_size,
                hop_size: self.hop_size.unwrap_or(self.frame_size / 2),
                window: parse_window(&self.window_type.unwrap_or("hanning".to_string())),
            },
            "wavelet" => TransformConfig::Wavelet {
                wavelet_type: WaveletType::Daubechies4,
                level: self.level.unwrap_or(3),
            },
            _ => TransformConfig::Fft {
                frame_size: self.frame_size,
                window: None,
            },
        }
    }
}
```

### Flutter 端使用示例

```dart
// 创建处理器
final processor = await AudioProcessor.new();

// 加载音频
await processor.add('audio.mp3', fileData);

// 查看支持的变换类型
final transforms = processor.getSupportedTransforms();
print('Supported: $transforms');  // [fft, stft, wavelet, spectrogram]

// 切换到 STFT ⭐
await processor.setTransformType('stft');

// 执行 STFT 变换
final stftResult = await processor.transformAudio(
  'audio.mp3',
  TransformConfigDto(
    transformType: 'stft',
    frameSize: 512,
    hopSize: 256,
    windowType: 'hanning',
  ),
);

// 切换到小波变换 ⭐
await processor.setTransformType('wavelet');

// 执行小波变换
final waveletResult = await processor.transformAudio(
  'audio.mp3',
  TransformConfigDto(
    transformType: 'wavelet',
    frameSize: 512,
    level: 3,
  ),
);

// 切换回 FFT
await processor.setTransformType('fft');
```

---

## 性能对比

| 方案 | 运行时开销 | 灵活性 | 插件支持 | 推荐场景 |
|------|-----------|--------|---------|---------|
| **方案1: Trait Object** | ~5-10% | 非常高 | ✅ 支持 | 需要动态插件、算法数量不确定 |
| **方案2: 枚举** | ~0% | 中等 | ❌ 不支持 | 算法固定、追求极致性能 |
| **方案3: 混合** | 可选 | 高 | ✅ 支持 | 推荐：平衡性能和灵活性 |

---

## 实施建议

### 阶段 1: 基础实现（建议采用方案1或3）

1. 定义统一的 `TransformConfig` 枚举
2. 确保 `SignalTransform` trait 是 object-safe
3. 实现 `DynamicAudioProcessor` 或 `DynamicTransformManager`
4. 实现基本的变换类型：FFT、STFT

### 阶段 2: 扩展算法

1. 实现更多变换类型：
   - Spectrogram（频谱图）
   - Mel-Spectrogram（梅尔频谱）
   - MFCC（梅尔倒谱系数）
   - Wavelet Transform（小波变换）
   - Constant-Q Transform（常数Q变换）

### 阶段 3: 优化

1. 添加缓存策略（按变换类型+配置缓存）
2. 性能基准测试
3. 可选：实现插件系统动态加载

---

## 总结

**推荐方案**：**方案3（混合方案）**
- 提供 `DynamicTransformManager`（灵活）和 `StaticTransformManager`（零开销）
- 用户可以根据需求选择
- API 统一，易于切换

**关键代码**：
```rust
// 运行时切换（只需一行）
processor.set_transformer(Box::new(StftTransform::new()));

// 或使用名称切换
processor.set_transform_type("stft")?;
```

这样就可以在运行时动态切换任意信号变换算法，不仅限于 FFT！

---

**相关文档**：
- 完整实现代码见 `IMPLEMENTATION_GUIDE.md`
- 架构设计见 `ARCHITECTURE_DESIGN.md` 第3.3节
- 扩展示例见 `ARCHITECTURE_DESIGN.md` 扩展示例3
