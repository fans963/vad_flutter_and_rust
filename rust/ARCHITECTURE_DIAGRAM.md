# Architecture Diagram - Zero-Overhead Abstraction Design

## Current Architecture (Tightly Coupled)

```
┌────────────────────────────────────────────────────────────┐
│                   Flutter (Dart)                           │
│                    UI Layer                                │
└──────────────────────┬─────────────────────────────────────┘
                       │ Flutter Rust Bridge
                       ▼
┌────────────────────────────────────────────────────────────┐
│              AudioProcessor (Rust)                         │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  - RwLock<HashMap<String, AudioInfo>>                │ │
│  │  - frame_size: usize                                 │ │
│  │                                                       │ │
│  │  Methods:                                            │ │
│  │  - add(file_path, file_data) {                       │ │
│  │      // Directly uses Symphonia                      │ │
│  │      let decoder = symphonia::default::get_codecs()  │ │
│  │      // ... decode logic ...                         │ │
│  │      map.insert(file_path, AudioInfo { ... })        │ │
│  │  }                                                    │ │
│  │                                                       │ │
│  │  - get_audio_data(...) { ... }                       │ │
│  │  - get_fft_data(...) {                               │ │
│  │      // Directly calls util.rs                       │ │
│  │      calculate_fft_parallel(...)                     │ │
│  │  }                                                    │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  util.rs:                                                 │
│  - calculate_fft_parallel() {                             │
│      // Directly uses rustfft                             │
│      let mut planner = FftPlanner::new();                 │
│  }                                                         │
└────────────────────────────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────┴──────────────┐
        │                             │
    Symphonia                      rustfft
   (Audio Decode)                    (FFT)


PROBLEMS:
❌ Cannot replace Symphonia without modifying AudioProcessor
❌ Cannot replace HashMap storage strategy
❌ Cannot test without real audio files
❌ FFT algorithm is hardcoded
❌ No flexibility in caching strategy
❌ Vec<f64> cloning everywhere = performance loss
```

## New Architecture (Loosely Coupled, Zero-Overhead)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Flutter (Dart)                                   │
│                          UI Layer                                        │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │ Flutter Rust Bridge
                             ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                  API Layer (Facade Pattern)                              │
│                                                                          │
│  #[frb(opaque)]                                                          │
│  pub struct AudioProcessor {                                             │
│      engine: AudioProcessorEngine<                                       │
│          SymphoniaDecoder,    // D: AudioDecoder                         │
│          MemoryStorage,       // S: AudioStorage                         │
│          FftTransform,        // T: SignalTransform                      │
│          SmartCache,          // C: CacheStrategy                        │
│      >                                                                    │
│  }                                                                        │
│                                                                          │
│  Methods (Backward Compatible):                                          │
│  - add(file_path, file_data) → engine.load_audio(...)                   │
│  - get_audio_data(...) → engine.get_audio_slice(...)                    │
│  - get_fft_data(...) → engine.get_transform(...)                        │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      Core Domain Layer                                   │
│                                                                          │
│  AudioProcessorEngine<D, S, T, C>  (Generic, Zero-Cost)                  │
│  where                                                                   │
│      D: AudioDecoder,          // Trait abstraction                      │
│      S: AudioStorage,          // Trait abstraction                      │
│      T: SignalTransform,       // Trait abstraction                      │
│      C: CacheStrategy          // Trait abstraction                      │
│  {                                                                       │
│      decoder: D,              // Compile-time polymorphism              │
│      storage: Arc<RwLock<S>>, // Thread-safe storage                    │
│      transformer: T,          // Zero-cost transform                    │
│      cache: Arc<RwLock<C>>,   // Smart caching                          │
│      config: ProcessorConfig  // Configuration                          │
│  }                                                                       │
│                                                                          │
│  Methods:                                                                │
│  - load_audio(key, data, hint) {                                         │
│      let decoded = self.decoder.decode(data, hint)?;  // Trait call     │
│      self.storage.write().store(key, decoded)?;       // Trait call     │
│  }                                                                       │
│                                                                          │
│  - get_audio_slice(key, range) → AudioSlice<'a> {                       │
│      self.storage.read().get(key)?                    // Zero-copy      │
│  }                                                                       │
│                                                                          │
│  - get_transform(key, config) → T::Output {                             │
│      if cache.contains(key) { return cache.get(key); }                  │
│      let data = self.storage.read().get(key)?;                          │
│      let result = self.transformer.transform(data, config);             │
│      cache.set(key, result.clone());                                    │
│      result                                                              │
│  }                                                                       │
│                                                                          │
│  Builder Pattern:                                                        │
│  AudioProcessorBuilder::new()                                            │
│      .with_decoder(D)                                                    │
│      .with_storage(S)                                                    │
│      .with_transformer(T)                                                │
│      .with_cache(C)                                                      │
│      .with_config(ProcessorConfig)                                       │
│      .build() → AudioProcessorEngine<D, S, T, C>                         │
└────────────────────────────┬─────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer (Traits)                           │
│                                                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐            │
│  │ AudioDecoder   │  │ AudioStorage   │  │SignalTransform │            │
│  │    (Trait)     │  │    (Trait)     │  │    (Trait)     │            │
│  │                │  │                │  │                │            │
│  │ - decode()     │  │ - store()      │  │ - transform()  │            │
│  │ - supported_   │  │ - get()        │  │ - supports_    │            │
│  │   formats()    │  │ - remove()     │  │   streaming()  │            │
│  └───────┬────────┘  └────────┬───────┘  └────────┬───────┘            │
│          │                    │                    │                    │
│          │                    │                    │                    │
│  ┌───────────────────────────────────────────────────────────┐         │
│  │                 CacheStrategy (Trait)                      │         │
│  │  - get(key) → Option<V>                                    │         │
│  │  - set(key, value)                                         │         │
│  │  - invalidate(key)                                         │         │
│  │  - clear()                                                 │         │
│  └───────────────────────────────────────────────────────────┘         │
└──────────────────────────────┬───────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                  Concrete Implementations                                │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Symphonia   │  │   Memory     │  │  FftTransform│  │ SmartCache │ │
│  │   Decoder    │  │   Storage    │  │              │  │            │ │
│  │              │  │              │  │              │  │ - LRU      │ │
│  │ impl         │  │ impl         │  │ impl         │  │ - LFU      │ │
│  │ AudioDecoder │  │ AudioStorage │  │ Signal       │  │ - TTL      │ │
│  │              │  │              │  │ Transform    │  │            │ │
│  │ - MP3        │  │ HashMap      │  │              │  │ impl       │ │
│  │ - WAV        │  │ based        │  │ rustfft      │  │ Cache      │ │
│  │ - FLAC       │  │              │  │ + rayon      │  │ Strategy   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘ │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │   Opus       │  │     LRU      │  │     STFT     │                  │
│  │   Decoder    │  │   Storage    │  │  Transform   │                  │
│  │  (Future)    │  │  (Future)    │  │  (Future)    │                  │
│  │              │  │              │  │              │                  │
│  │ impl         │  │ impl         │  │ impl         │                  │
│  │ AudioDecoder │  │ AudioStorage │  │ Signal       │                  │
│  │              │  │              │  │ Transform    │                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                  │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐                                     │
│  │    Disk      │  │   Wavelet    │                                     │
│  │   Storage    │  │  Transform   │                                     │
│  │  (Future)    │  │  (Future)    │                                     │
│  │              │  │              │                                     │
│  │ impl         │  │ impl         │                                     │
│  │ AudioStorage │  │ Signal       │                                     │
│  │              │  │ Transform    │                                     │
│  └──────────────┘  └──────────────┘                                     │
└──────────────────────────────────────────────────────────────────────────┘


BENEFITS:
✅ Easy to replace any component (just implement trait)
✅ Zero runtime overhead (generics → monomorphization)
✅ Fully testable (mock any component)
✅ Highly extensible (add new implementations)
✅ Backward compatible (existing API unchanged)
✅ Type-safe (compiler enforces correctness)
✅ Performance optimized (zero-copy, caching, parallelism)
```

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                      1. Load Audio                               │
└──────────────────────────────────────────────────────────────────┘

Flutter
   │
   │ add(file_path, file_data)
   ▼
AudioProcessor (Facade)
   │
   │ engine.load_audio(key, data, hint)
   ▼
AudioProcessorEngine<D, S, T, C>
   │
   │ decoder.decode(data, hint)
   ▼
D: AudioDecoder (e.g., SymphoniaDecoder)
   │
   │ Return DecodedAudio<'a>
   ▼
AudioProcessorEngine
   │
   │ storage.store(key, audio_data)
   ▼
S: AudioStorage (e.g., MemoryStorage)
   │
   │ Store in HashMap
   ▼
Stored ✓

┌──────────────────────────────────────────────────────────────────┐
│                   2. Get Audio Data (Zero-Copy)                  │
└──────────────────────────────────────────────────────────────────┘

Flutter
   │
   │ get_audio_data(file_path, offset, index)
   ▼
AudioProcessor (Facade)
   │
   │ engine.get_audio_slice(key, range)
   ▼
AudioProcessorEngine
   │
   │ storage.get(key) → &[f64]  (Zero-copy reference!)
   ▼
Return AudioSlice<'a> {
    data: &[f64],        // No cloning!
    metadata: &Metadata
}

┌──────────────────────────────────────────────────────────────────┐
│               3. Get Transform (with Caching)                    │
└──────────────────────────────────────────────────────────────────┘

Flutter
   │
   │ get_fft_data(file_path, offset, index)
   ▼
AudioProcessor (Facade)
   │
   │ engine.get_transform(key, config)
   ▼
AudioProcessorEngine
   │
   │ Check cache
   ├─ Cache hit? ──────────────┐
   │                            │
   ▼ No                         │ Yes
   │                            │
   │ storage.get(key)           │
   ▼                            │
Get audio data                  │
   │                            │
   │ transformer.transform()    │
   ▼                            ▼
T: SignalTransform         Return cached
(e.g., FftTransform)       result
   │
   │ rustfft + rayon
   ▼
Compute FFT result
   │
   │ cache.set(key, result)
   ▼
C: CacheStrategy
(e.g., SmartCache)
   │
   │ Store with eviction policy
   ▼
Return result
```

## Compilation Process (Zero-Overhead)

```
┌──────────────────────────────────────────────────────────────────┐
│                      Source Code (Generic)                       │
└──────────────────────────────────────────────────────────────────┘

pub struct AudioProcessorEngine<D, S, T, C>
where
    D: AudioDecoder,
    S: AudioStorage,
    T: SignalTransform,
    C: CacheStrategy,
{
    decoder: D,
    storage: S,
    transformer: T,
    cache: C,
}

impl<D, S, T, C> AudioProcessorEngine<D, S, T, C> {
    fn load_audio(&self, ...) {
        self.decoder.decode(...);    // Generic trait call
        self.storage.store(...);     // Generic trait call
    }
}

                    │
                    │ Rust Compiler (Monomorphization)
                    ▼

┌──────────────────────────────────────────────────────────────────┐
│            Generated Machine Code (Specialized)                  │
└──────────────────────────────────────────────────────────────────┘

// Compiler generates SPECIFIC code for EACH type combination

AudioProcessorEngine_SymphoniaDecoder_MemoryStorage_FftTransform_SmartCache {
    decoder: SymphoniaDecoder,      // Concrete type
    storage: MemoryStorage,         // Concrete type
    transformer: FftTransform,      // Concrete type
    cache: SmartCache,              // Concrete type
}

impl AudioProcessorEngine_SymphoniaDecoder_MemoryStorage_FftTransform_SmartCache {
    fn load_audio(&self, ...) {
        // Direct function call (NO virtual dispatch!)
        SymphoniaDecoder::decode(&self.decoder, ...);
        MemoryStorage::store(&self.storage, ...);
    }
    // Functions are inlined if small enough
}

RESULT:
✅ Zero runtime overhead
✅ No virtual function table (vtable)
✅ Inlining opportunities
✅ Maximum optimization
```

## Extension Examples

```
┌──────────────────────────────────────────────────────────────────┐
│              Example 1: Add Opus Decoder Support                 │
└──────────────────────────────────────────────────────────────────┘

1. Define new decoder:
   pub struct OpusDecoder { ... }

2. Implement trait:
   impl AudioDecoder for OpusDecoder {
       fn decode(...) { /* opus decoding logic */ }
   }

3. Use it:
   let engine = AudioProcessorBuilder::new()
       .with_decoder(OpusDecoder::new())  // Just swap it!
       .with_storage(MemoryStorage::new())
       .with_transformer(FftTransform::new())
       .with_cache(SmartCache::new(...))
       .build();

┌──────────────────────────────────────────────────────────────────┐
│            Example 2: Add Disk Storage Support                   │
└──────────────────────────────────────────────────────────────────┘

1. Define new storage:
   pub struct DiskStorage { base_path: PathBuf }

2. Implement trait:
   impl AudioStorage for DiskStorage {
       fn store(...) { /* write to disk */ }
       fn get(...) { /* read from disk (mmap) */ }
   }

3. Use it:
   let engine = AudioProcessorBuilder::new()
       .with_decoder(SymphoniaDecoder::new())
       .with_storage(DiskStorage::new("/tmp/cache"))  // Disk!
       .with_transformer(FftTransform::new())
       .with_cache(SmartCache::new(...))
       .build();

┌──────────────────────────────────────────────────────────────────┐
│              Example 3: Compose Multiple Transforms              │
└──────────────────────────────────────────────────────────────────┘

1. Define pipeline transform:
   pub struct PipelineTransform<T1, T2> {
       stage1: T1,
       stage2: T2,
   }

2. Implement trait:
   impl<T1, T2> SignalTransform for PipelineTransform<T1, T2>
   where T1: SignalTransform, T2: SignalTransform {
       fn transform(...) {
           let temp = self.stage1.transform(...);
           self.stage2.transform(&temp, ...)
       }
   }

3. Use it:
   let pipeline = PipelineTransform::new(
       FftTransform::new(),     // First: FFT
       Log10Transform::new(),   // Then: Log10
   );

   let engine = AudioProcessorBuilder::new()
       .with_transformer(pipeline)  // Composed transform!
       .build();
```

## Key Principles Illustrated

```
┌─────────────────────────────────────────────────────────────┐
│  1. Dependency Inversion Principle                          │
└─────────────────────────────────────────────────────────────┘

        High-level Module                Low-level Module
              │                                 │
              │  depends on                     │  implements
              ▼                                 ▼
         Trait (Interface)  ◄─────────────  Implementation
    (e.g., AudioDecoder)            (e.g., SymphoniaDecoder)

    ✅ High-level doesn't depend on low-level
    ✅ Both depend on abstraction (trait)

┌─────────────────────────────────────────────────────────────┐
│  2. Open-Closed Principle                                   │
└─────────────────────────────────────────────────────────────┘

    AudioProcessorEngine is:
    - OPEN for extension (add new implementations)
    - CLOSED for modification (no need to change engine code)

    Example:
    Add STFT? → Implement SignalTransform trait ✓
    No changes to engine code required!

┌─────────────────────────────────────────────────────────────┐
│  3. Zero-Cost Abstraction                                   │
└─────────────────────────────────────────────────────────────┘

    Generics + Traits = Zero Runtime Overhead

    trait Foo { fn bar(&self); }
    fn use_foo<T: Foo>(x: &T) { x.bar(); }

    Compiler generates specialized code:
    fn use_foo_ConcreteType(x: &ConcreteType) {
        ConcreteType::bar(x);  // Direct call!
    }

    ✅ No vtable lookup
    ✅ No dynamic dispatch
    ✅ Inlining possible
    ✅ Same as hand-written code
```

---

**Summary**: This architecture provides maximum flexibility with zero performance cost by leveraging Rust's trait system and compile-time code generation (monomorphization).
