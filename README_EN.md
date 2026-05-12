# VAD Flutter & Rust Audio Analysis Tool

A professional-grade **Voice Activity Detection (VAD)** and **Audio Analysis** application built with **Flutter** for the frontend and **Rust** for high-performance signal processing.

> [:cn: 中文版本](README.md)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![Rust](https://img.shields.io/badge/Rust-%23000000.svg?style=flat&logo=rust&logoColor=white)

## 🚀 Overview

Real-time interactive audio analysis with VAD. Rust handles CPU-intensive signal processing (FFT, energy, ZCR) while Flutter provides a reactive Material 3 UI with Syncfusion charting, drag-and-drop file loading, and pluggable VAD algorithms.

### Key Features

- **Multi-Algorithm VAD**: Energy-based and Zero-Crossing Rate detection, with a plugin architecture for adding new algorithms.
- **Spectral Analysis**: FFT, Energy, and Zero-Crossing Rate computation via `rustfft` + `rayon` parallelism.
- **Self-Managed Chart Series**: Full control over series visibility, color, selection, and deletion — no dependency on chart library internals.
- **Adaptive VAD Parameter UI**: Each algorithm exposes its tunable parameters; the UI renders Sliders, Switches, and Dropdowns automatically.
- **Universal Codec Support**: MP3, WAV, FLAC, AAC, etc. via the Symphonia library.
- **Smart Caching**: DashMap key-value storage + MinMax downsampling; only visible charts are processed on view changes.

---

## 🏗️ Architecture

### System Overview

```mermaid
graph TB
    subgraph Flutter["Flutter (Dart)"]
        UI["Widget Tree<br/>(main.dart → ChartWidget → ToolPlate)"]
        SIG["Signals Layer<br/>(chart_control, chart_series, vad_signal)"]
        EVT["Event Stream<br/>(ChartEvent via StreamSink)"]
    end

    subgraph Bridge["flutter_rust_bridge v2"]
        FRB["FFI + Codegen<br/>(type-safe async calls)"]
    end

    subgraph Rust["Rust Backend"]
        ENG["AudioProcessorEngine<br/>(orchestrator)"]
        DEC["SymphoniaDecoder<br/>(all formats → f32 PCM)"]
        CACHE["KvCachedChartStorage<br/>(DashMap)"]
        DWN["MinMax Downsampling<br/>(rayon parallel)"]
        VAD["VAD Engine<br/>(OnceLock + Mutex)"]
        XFRM["Transforms<br/>(FFT, Energy, ZCR)"]
    end

    UI -->|"signal read / Watch rebuild"| SIG
    UI -->|"listen"| EVT
    SIG -->|"async call"| FRB
    FRB -->|"invoke"| ENG
    ENG --> DEC
    ENG --> CACHE
    ENG --> DWN
    ENG --> VAD
    ENG --> XFRM
    EVT -->|"StreamSink push"| FRB
```

### Rust Module Hierarchy

```mermaid
graph LR
    subgraph api
        core[core/engine.rs] --> types
        core --> traits
        core --> decoder
        core --> storage
        core --> sampling
        core --> transform
        core --> communicator
        core --> vad

        types[types/] --> audio.rs
        types --> chart.rs
        types --> vad.rs
        types --> events.rs

        traits[traits/] --> audio_decoder
        traits --> audio_storage
        traits --> cached_chart_storage
        traits --> down_sample
        traits --> transform
        traits --> communicator
        traits --> vad_algorithm

        decoder --> symphonia_decoder
        storage --> kv_audio_storage
        storage --> kv_cached_chart_storage
        sampling --> minmax
        sampling --> equal_step
        transform --> fft
        transform --> energy
        transform --> zero_crossing_rate
        communicator --> stream_sink_communicator

        vad[vad/] --> energy_vad
        vad --> zcr_vad
    end
```

### Data Pipeline

```mermaid
sequenceDiagram
    participant User
    participant Flutter
    participant Rust
    participant Cache

    User->>Flutter: drag & drop audio file
    Flutter->>Rust: engine.add(filePath, bytes)
    Rust->>Rust: SymphoniaDecoder → f32 PCM
    Rust->>Cache: store raw audio
    Rust->>Rust: audio_to_chart() → Chart points
    Rust->>Cache: cache chart
    Rust->>Rust: MinMax.down_sample(chart, target)
    Rust-->>Flutter: StreamSink → ChartEvent.AddChart

    Flutter->>Rust: engine.addChart(filePath, DataType.spectrum)
    Rust->>Cache: load raw audio
    Rust->>Rust: FftTransform → Chart
    Rust->>Cache: cache chart
    Rust-->>Flutter: StreamSink → ChartEvent.UpdateAllCharts

    User->>Flutter: drag slider
    Flutter->>Rust: engine.setIndexRange(start, end) [debounced 50ms]
    Rust->>Rust: for visible charts: get_range() → MinMax.down_sample()
    Rust-->>Flutter: StreamSink → ChartEvent.UpdateAllCharts
    Flutter->>Flutter: Watch detects signal change → ChartWidget rebuilds
```

### Flutter Widget Tree

```mermaid
graph TD
    M[main.dart] --> SCAFFOLD[Scaffold]
    SCAFFOLD --> DROP[DropRegion<br/>drag & drop area]
    DROP --> COL[Column]
    COL --> TITLE[TitleBar<br/>desktop only]
    COL --> CHART[ChartWidget<br/>SfCartesianChart]
    COL --> TOOL[ToolPlate]

    TOOL --> DRAG[GenericDragHandle<br/>resize]
    TOOL --> PV[PageView]

    PV --> HOME[HomePanel]
    PV --> INFO[InfoPanel]
    PV --> CTRL[ControlPanel<br/>4 sliders + series selector]
    PV --> VADPANEL[VadControlPanel<br/>algorithm + adaptive params]

    SCAFFOLD --> FAB[PickFileButton]
    SCAFFOLD --> NAV[NavigationBar<br/>4 tabs]

    CHART -->|"reads"| SIGS[Signals:<br/>xViewMin/Max,<br/>yViewMin/Max,<br/>_dataVersion,<br/>vadVersion,<br/>chartSeriesManager]
```

### VAD Plugin Architecture

```mermaid
graph TB
    subgraph "Rust Trait"
        TRAIT["VadAlgorithm trait<br/>┌─ name()<br/>├─ display_name()<br/>├─ get_parameters() → Vec&lt;VadParamDef&gt;<br/>├─ update_parameter(key, value)<br/>└─ process(samples) → VadResult"]
    end

    subgraph "Implementations"
        EVAD["EnergyVad<br/>params: threshold, frame_size, hangover"]
        ZVAD["ZCRVad<br/>params: zcr_threshold, frame_size, energy_floor"]
        FUTURE["CustomVad<br/>(your algorithm here)"]
    end

    subgraph "Flutter UI"
        SEL["Algorithm Dropdown"]
        DYN["Dynamic Parameter Controls<br/>(float→Slider, int→Slider, bool→Switch)"]
        BTN["Run VAD Button"]
    end

    subgraph "Visualization"
        OVERLAY["AreaSeries overlay<br/>(green, semi-transparent)<br/>on audio waveform"]
    end

    TRAIT --> EVAD
    TRAIT --> ZVAD
    TRAIT --> FUTURE

    SEL -->|"set_vad_algorithm()"| TRAIT
    TRAIT -->|"get_parameters()"| DYN
    DYN -->|"set_vad_param()"| TRAIT
    BTN -->|"compute_vad()"| TRAIT
    TRAIT -->|"VadResult"| OVERLAY
```

### Chart Series State Machine

```mermaid
stateDiagram-v2
    [*] --> Loaded: audio file added
    Loaded --> Visible: default
    Visible --> Selected: dropdown select
    Selected --> Visible: deselect
    Visible --> Hidden: toggle visibility
    Hidden --> Visible: toggle visibility
    Selected --> Deleted: delete button
    Deleted --> [*]

    note right of Selected
        Operations available:
        • Color picker
        • Visibility toggle
        • Delete (Rust cache + Flutter state)
    end note
```

---

## 🛠️ Getting Started

### Prerequisites

- **Flutter SDK**: `^3.9.4`
- **Rust Toolchain**: Stable
- **FVM** (optional): Flutter version management

### Installation

```bash
git clone https://github.com/fans963/vad_flutter_and_rust.git
cd vad_flutter_and_rust

# Install dependencies
flutter pub get

# Generate Rust-Flutter bridge code (required after Rust changes)
flutter_rust_bridge_codegen generate

# Run
flutter run
```

---

## 📂 Project Structure

```
vad_flutter_and_rust/
├── lib/                          # Flutter source
│   ├── main.dart                 # Entry, window/tray, drag-drop
│   └── src/
│       ├── signals/              # Reactive state (signals package)
│       │   ├── audio_processor_signal.dart
│       │   ├── chart_control_signal.dart
│       │   ├── chart_series_signal.dart   # Per-series metadata manager
│       │   ├── page_controller_signal.dart
│       │   ├── support_audio_format_signal.dart
│       │   └── vad_signal.dart
│       ├── ui/                   # Widgets
│       │   ├── chart_widget.dart
│       │   ├── pick_file_button.dart
│       │   ├── title_bar.dart
│       │   ├── tool_plate.dart   # Bottom panel: sliders + series selector
│       │   └── vad_control_panel.dart
│       ├── util/
│       │   ├── drag_handler.dart
│       │   └── util.dart
│       └── rust/api/             # Generated FRB bindings
├── rust/                         # Rust source
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── frb_generated.rs      # Auto-generated FFI glue
│       └── api/
│           ├── core/engine.rs    # AudioProcessorEngine
│           ├── traits/           # 7 traits (decoder, storage, transform, ...)
│           ├── types/            # Data structures
│           ├── decoder/          # Symphonia decoder
│           ├── storage/          # KV audio/chart storage
│           ├── sampling/         # MinMax + EqualStep downsampling
│           ├── transform/        # FFT, Energy, ZCR
│           ├── communicator/     # StreamSink event emission
│           ├── events/           # Global StreamSink singleton
│           └── vad/              # Pluggable VAD algorithms
├── assets/                       # Images, fonts
└── pubspec.yaml
```

---

## 🤝 Contributing

Contributions are welcome:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Adding a New VAD Algorithm

1. Create `rust/src/api/vad/my_vad.rs` implementing `VadAlgorithm` trait
2. Register in `rust/src/api/vad/mod.rs` → `create_vad()` and `list_algorithm_names()`
3. Run `flutter_rust_bridge_codegen generate`
4. The UI automatically renders parameters from `get_parameters()` — no Flutter changes needed

---

## 👥 Developers

- **fans963**
- **🐂津哥**

## 📄 License

MIT. See `LICENSE` for details.
