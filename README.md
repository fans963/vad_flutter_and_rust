# VAD Flutter & Rust 音频分析工具

基于 **Flutter** 前端 + **Rust** 后端的高性能**语音活动检测 (VAD)** 与**音频分析**应用。

> [:us: English Version](README_EN.md)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![Rust](https://img.shields.io/badge/Rust-%23000000.svg?style=flat&logo=rust&logoColor=white)

## 🚀 概述

实时交互式音频分析与 VAD。Rust 处理 CPU 密集型信号处理（FFT、能量、ZCR），Flutter 提供响应式 Material 3 界面，支持 Syncfusion 图表、拖放加载文件和可插拔 VAD 算法。

### 核心特性

- **多算法 VAD**：内置能量法和过零率法，插件架构支持扩展新算法。
- **频谱分析**：FFT、能量、过零率计算，基于 `rustfft` + `rayon` 并行加速。
- **线粒度自管理**：颜色、显隐、选中、删除全部由 `ChartSeriesManager` 统一管理，不依赖图表库内部状态。
- **自适应 VAD 参数 UI**：每个算法通过 trait 暴露可调参数，UI 自动渲染 Slider、Switch、Dropdown。
- **通用编解码**：Symphonia 支持 MP3、WAV、FLAC、AAC 等格式。
- **智能缓存**：DashMap 键值存储 + MinMax 降采样，视图变化时仅处理可见曲线。

---

## 🏗️ 架构

### 系统总览

```mermaid
graph TB
    subgraph Flutter["Flutter (Dart)"]
        UI["组件树<br/>(main.dart → ChartWidget → ToolPlate)"]
        SIG["Signals 响应层<br/>(chart_control, chart_series, vad_signal)"]
        EVT["事件流<br/>(ChartEvent via StreamSink)"]
    end

    subgraph Bridge["flutter_rust_bridge v2"]
        FRB["FFI + 代码生成<br/>(类型安全异步调用)"]
    end

    subgraph Rust["Rust 后端"]
        ENG["AudioProcessorEngine<br/>(调度中心)"]
        DEC["SymphoniaDecoder<br/>(全格式 → f32 PCM)"]
        CACHE["KvCachedChartStorage<br/>(DashMap)"]
        DWN["MinMax 降采样<br/>(rayon 并行)"]
        VAD["VAD 引擎<br/>(OnceLock + Mutex)"]
        XFRM["信号变换<br/>(FFT, 能量, ZCR)"]
    end

    UI -->|"signal 读取 / Watch 重建"| SIG
    UI -->|"监听"| EVT
    SIG -->|"异步调用"| FRB
    FRB -->|"调用"| ENG
    ENG --> DEC
    ENG --> CACHE
    ENG --> DWN
    ENG --> VAD
    ENG --> XFRM
    EVT -->|"StreamSink 推送"| FRB
```

### Rust 模块层次

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

### 数据管线

```mermaid
sequenceDiagram
    participant 用户
    participant Flutter
    participant Rust
    participant 缓存

    用户->>Flutter: 拖放音频文件
    Flutter->>Rust: engine.add(filePath, bytes)
    Rust->>Rust: SymphoniaDecoder → f32 PCM
    Rust->>缓存: 存储原始音频
    Rust->>Rust: audio_to_chart() → Chart 点集
    Rust->>缓存: 缓存 chart
    Rust->>Rust: MinMax.down_sample(chart, target)
    Rust-->>Flutter: StreamSink → ChartEvent.AddChart

    Flutter->>Rust: engine.addChart(filePath, DataType.spectrum)
    Rust->>缓存: 加载原始音频
    Rust->>Rust: FftTransform → Chart
    Rust->>缓存: 缓存 chart
    Rust-->>Flutter: StreamSink → ChartEvent.UpdateAllCharts

    用户->>Flutter: 拖动 slider
    Flutter->>Rust: engine.setIndexRange(start, end) [50ms 防抖]
    Rust->>Rust: 遍历可见 chart: get_range() → MinMax.down_sample()
    Rust-->>Flutter: StreamSink → ChartEvent.UpdateAllCharts
    Flutter->>Flutter: Watch 检测 signal 变化 → ChartWidget 重建
```

### Flutter 组件树

```mermaid
graph TD
    M[main.dart] --> SCAFFOLD[Scaffold]
    SCAFFOLD --> DROP[DropRegion<br/>拖放区域]
    DROP --> COL[Column]
    COL --> TITLE[TitleBar<br/>仅桌面端]
    COL --> CHART[ChartWidget<br/>SfCartesianChart]
    COL --> TOOL[ToolPlate]

    TOOL --> DRAG[GenericDragHandle<br/>拖拽调整高度]
    TOOL --> PV[PageView]

    PV --> HOME[HomePanel<br/>首页]
    PV --> INFO[InfoPanel<br/>信息]
    PV --> CTRL[ControlPanel<br/>4 个滑块 + 曲线选择器]
    PV --> VADPANEL[VadControlPanel<br/>算法选择 + 自适应参数]

    SCAFFOLD --> FAB[PickFileButton<br/>文件选择]
    SCAFFOLD --> NAV[NavigationBar<br/>4 个标签]

    CHART -->|"读取"| SIGS[Signals 信号:<br/>xViewMin/Max,<br/>yViewMin/Max,<br/>_dataVersion,<br/>vadVersion,<br/>chartSeriesManager]
```

### VAD 插件架构

```mermaid
graph TB
    subgraph "Rust Trait"
        TRAIT["VadAlgorithm trait<br/>┌─ name()<br/>├─ display_name()<br/>├─ get_parameters() → Vec&lt;VadParamDef&gt;<br/>├─ update_parameter(key, value)<br/>└─ process(samples) → VadResult"]
    end

    subgraph "算法实现"
        EVAD["EnergyVad 能量法<br/>参数: threshold, frame_size, hangover"]
        ZVAD["ZCRVad 过零率法<br/>参数: zcr_threshold, frame_size, energy_floor"]
        FUTURE["CustomVad 自定义<br/>(你的算法在这里)"]
    end

    subgraph "Flutter UI"
        SEL["算法下拉框"]
        DYN["自适应参数控件<br/>(float→Slider, int→Slider, bool→Switch)"]
        BTN["运行 VAD 按钮"]
    end

    subgraph "可视化"
        OVERLAY["AreaSeries 叠加层<br/>(绿色半透明)<br/>覆盖在音频波形上"]
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

### 曲线自管理状态机

```mermaid
stateDiagram-v2
    [*] --> 已加载: 添加音频文件
    已加载 --> 可见: 默认
    可见 --> 已选中: 下拉框选择
    已选中 --> 可见: 取消选中
    可见 --> 已隐藏: 切换显隐
    已隐藏 --> 可见: 切换显隐
    已选中 --> 已删除: 删除按钮
    已删除 --> [*]

    note right of 已选中
        可用操作:
        • 颜色选择器
        • 显隐切换
        • 删除 (Rust 缓存 + Flutter 状态)
    end note
```

---

## 🛠️ 快速开始

### 环境要求

- **Flutter SDK**: `^3.9.4`
- **Rust 工具链**: Stable
- **FVM**（可选）：管理 Flutter 版本

### 安装运行

```bash
git clone https://github.com/fans963/vad_flutter_and_rust.git
cd vad_flutter_and_rust

# 安装依赖
flutter pub get

# 生成 Rust-Flutter 桥接代码（修改 Rust 后必须执行）
flutter_rust_bridge_codegen generate

# 运行
flutter run
```

---

## 📂 项目结构

```
vad_flutter_and_rust/
├── lib/                          # Flutter 源码
│   ├── main.dart                 # 入口、窗口管理、拖放
│   └── src/
│       ├── signals/              # 响应式状态 (signals 包)
│       │   ├── audio_processor_signal.dart
│       │   ├── chart_control_signal.dart
│       │   ├── chart_series_signal.dart   # 曲线元数据管理器
│       │   ├── page_controller_signal.dart
│       │   ├── support_audio_format_signal.dart
│       │   └── vad_signal.dart
│       ├── ui/                   # 组件
│       │   ├── chart_widget.dart
│       │   ├── pick_file_button.dart
│       │   ├── title_bar.dart
│       │   ├── tool_plate.dart   # 底部面板: 滑块 + 曲线选择
│       │   └── vad_control_panel.dart
│       ├── util/
│       │   ├── drag_handler.dart
│       │   └── util.dart
│       └── rust/api/             # 自动生成的 FRB 绑定
├── rust/                         # Rust 源码
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── frb_generated.rs      # 自动生成 FFI 胶水代码
│       └── api/
│           ├── core/engine.rs    # AudioProcessorEngine
│           ├── traits/           # 7 个 trait (decoder, storage, transform, ...)
│           ├── types/            # 数据结构
│           ├── decoder/          # Symphonia 解码器
│           ├── storage/          # KV 音频/图表存储
│           ├── sampling/         # MinMax + EqualStep 降采样
│           ├── transform/        # FFT, 能量, ZCR
│           ├── communicator/     # StreamSink 事件推送
│           ├── events/           # 全局 StreamSink 单例
│           └── vad/              # 可插拔 VAD 算法
├── assets/                       # 图片、字体
└── pubspec.yaml
```

---

## 🤝 贡献

欢迎贡献代码：

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 发起 Pull Request

### 添加新的 VAD 算法

1. 创建 `rust/src/api/vad/my_vad.rs`，实现 `VadAlgorithm` trait
2. 在 `rust/src/api/vad/mod.rs` 的 `create_vad()` 和 `list_algorithm_names()` 中注册
3. 运行 `flutter_rust_bridge_codegen generate`
4. UI 自动根据 `get_parameters()` 渲染参数控件 — **无需修改 Flutter 代码**

---

## 👥 开发者

- **fans963**
- **🐂津哥**

## 📄 许可证

MIT。详见 `LICENSE` 文件。
