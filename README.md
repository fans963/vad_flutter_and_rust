<div align="center">

# 🎵 VAD - Voice Activity Detection & Audio Visualizer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.9.4+-02569B?logo=flutter)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-1.0+-orange?logo=rust)](https://www.rust-lang.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-blue)](#supported-platforms)

**一个基于 Flutter 和 Rust 的跨平台音频分析与可视化工具**

*A cross-platform audio analysis and visualization tool built with Flutter and Rust*

[English](#english) | [中文](#中文)

</div>

---

## 中文

### 📖 项目简介

VAD 是一个现代化的音频分析工具，结合了 Flutter 的跨平台 UI 能力和 Rust 的高性能音频处理能力。该项目使用 Flutter Rust Bridge 实现了两种语言的无缝集成，为用户提供了强大的音频波形可视化和 FFT 频谱分析功能。

### ✨ 主要特性

- 🎨 **现代化 UI 设计**
  - 支持明暗主题自动切换
  - Material Design 3 设计语言
  - 流畅的动画效果和交互体验
  - 响应式布局适配多种屏幕尺寸

- 🔊 **强大的音频处理能力**
  - 支持多种音频格式（WAV, MP3, FLAC）
  - 实时波形可视化
  - 快速傅里叶变换（FFT）频谱分析
  - 并行处理优化，充分利用多核 CPU

- 📊 **丰富的可视化功能**
  - 交互式音频波形图表
  - FFT 频谱可视化
  - 可调节的采样率和帧大小
  - 下采样支持以提高性能

- 🖥️ **跨平台支持**
  - Windows、macOS、Linux 桌面应用
  - Web 应用支持
  - 系统托盘集成（桌面端）
  - 文件拖放支持

### 🛠️ 技术栈

#### Frontend (Flutter)
- **框架**: Flutter 3.9.4+
- **状态管理**: Riverpod 3.1.0
- **UI 组件**:
  - `fl_chart`: 图表可视化
  - `flex_color_scheme`: 主题管理
  - `dynamic_color`: 动态颜色支持
  - `animations`: 流畅动画效果
- **桌面功能**:
  - `window_manager`: 窗口管理
  - `tray_manager`: 系统托盘
  - `desktop_drop`: 拖放支持
- **工具库**:
  - `file_picker`: 文件选择
  - `url_launcher`: URL 启动

#### Backend (Rust)
- **音频处理**:
  - `symphonia`: 音频解码（支持多种格式）
  - `rustfft`: 快速傅里叶变换
  - `rayon`: 并行计算
- **跨语言通信**:
  - `flutter_rust_bridge`: Flutter-Rust 桥接

### 📋 系统要求

- **操作系统**: Windows 10+, macOS 10.15+, Linux (Ubuntu 20.04+), 或现代浏览器
- **Flutter SDK**: 3.9.4 或更高版本
- **Rust**: 1.70 或更高版本
- **Dart SDK**: 3.9.4 或更高版本

#### Linux 额外依赖
```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-dev libappindicator3-dev

# Fedora
sudo dnf install gtk3-devel libappindicator-gtk3-devel
```

### 🚀 快速开始

#### 1. 克隆项目
```bash
git clone https://github.com/fans963/vad_flutter_and_rust.git
cd vad_flutter_and_rust
```

#### 2. 安装依赖
```bash
# 安装 Flutter 依赖
flutter pub get

# Rust 依赖会在构建时自动下载
```

#### 3. 运行项目

**桌面应用**:
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

**Web 应用**:
```bash
flutter run -d chrome
```

### 🔨 构建发布版本

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

构建产物位置：
- Windows: `build/windows/x64/runner/Release/`
- macOS: `build/macos/Build/Products/Release/`
- Linux: `build/linux/x64/release/bundle/`
- Web: `build/web/`

### 📂 项目结构

```
vad_flutter_and_rust/
├── lib/                          # Flutter Dart 代码
│   ├── main.dart                # 应用入口
│   └── src/
│       ├── rust/                # Rust 桥接代码（自动生成）
│       ├── ui/                  # UI 组件
│       │   ├── chart_widget.dart      # 图表组件
│       │   ├── pick_file_button.dart  # 文件选择按钮
│       │   ├── title_bar.dart         # 标题栏
│       │   └── tool_plate.dart        # 工具面板
│       ├── provider/            # Riverpod 状态管理
│       └── util/                # 工具函数
├── rust/                        # Rust 音频处理代码
│   ├── src/
│   │   ├── api/
│   │   │   ├── audio_processor.rs  # 音频处理核心
│   │   │   └── util.rs             # FFT 和工具函数
│   │   └── lib.rs
│   └── Cargo.toml
├── rust_builder/                # Rust 构建配置
├── assets/                      # 资源文件
│   ├── image/                   # 图片资源
│   └── screenshots/             # 截图（用于文档）
├── android/                     # Android 平台配置
├── ios/                         # iOS 平台配置
├── linux/                       # Linux 平台配置
├── macos/                       # macOS 平台配置
├── windows/                     # Windows 平台配置
├── web/                         # Web 平台配置
├── pubspec.yaml                 # Flutter 依赖配置
├── flutter_rust_bridge.yaml     # FRB 配置
└── README.md                    # 本文件
```

### 🎯 使用方法

1. **启动应用**
   - 运行应用后，您将看到主界面和一个图表区域

2. **加载音频文件**
   - 点击右下角的 `+` 浮动按钮
   - 选择支持的音频文件（WAV, MP3, FLAC）
   - 或直接将文件拖放到应用窗口（桌面端）

3. **查看波形**
   - 加载后自动显示音频波形
   - 可以缩放和平移查看不同部分

4. **分析频谱**
   - 使用底部工具栏切换到 FFT 视图
   - 调整帧大小和其他参数

5. **多文件支持**
   - 可同时加载多个音频文件
   - 使用不同颜色区分

### 🐛 故障排除

#### Linux 编译 tray_manager 报错

如果在 Linux 下编译时遇到以下错误：

```
error: 'app_indicator_new' is deprecated [-Werror,-Wdeprecated-declarations]
```

**解决方案**：

在 `linux/flutter/ephemeral/.plugin_symlinks/tray_manager/linux/CMakeLists.txt` 中添加以下编译参数：

```cmake
target_compile_options(${PLUGIN_NAME} PRIVATE -Wno-error=deprecated-declarations)
```

这会关闭废弃 API 报错，使项目正常编译运行。

#### Flutter Rust Bridge 生成失败

如果遇到 FRB 代码生成问题：

```bash
# 重新生成桥接代码
flutter_rust_bridge_codegen generate
```

#### 音频文件无法加载

确保音频文件格式受支持且未损坏。当前支持的格式：
- WAV (PCM)
- MP3
- FLAC

### 🔧 开发指南

#### 修改 Rust 代码后
```bash
# 重新生成 Flutter-Rust 桥接代码
flutter_rust_bridge_codegen generate

# 重新运行应用
flutter run
```

#### 添加新的音频处理功能
1. 在 `rust/src/api/audio_processor.rs` 中添加 Rust 函数
2. 运行 `flutter_rust_bridge_codegen generate` 生成 Dart 绑定
3. 在 Flutter 代码中调用新函数

#### 调试技巧
```bash
# Flutter 调试模式
flutter run --debug

# 查看 Rust 日志
# 在 Rust 代码中使用 println! 或 eprintln!
```

### 🤝 贡献

欢迎贡献！如果您想为这个项目做出贡献：

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

### 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

### 👥 开发者

- **fans963** - [GitHub](https://github.com/fans963)
- **🐂津哥** - Co-developer

### 🙏 致谢

- [Flutter](https://flutter.dev) - 跨平台 UI 框架
- [Rust](https://www.rust-lang.org) - 高性能系统编程语言
- [Flutter Rust Bridge](https://github.com/fzyzcjy/flutter_rust_bridge) - Flutter 和 Rust 的桥接
- [Symphonia](https://github.com/pdeljanov/Symphonia) - 纯 Rust 音频解码库
- [fl_chart](https://github.com/imaNNeo/fl_chart) - 强大的 Flutter 图表库

### 📞 联系方式

- 项目地址: [https://github.com/fans963/vad_flutter_and_rust](https://github.com/fans963/vad_flutter_and_rust)
- 问题反馈: [Issues](https://github.com/fans963/vad_flutter_and_rust/issues)

---

## English

### 📖 Project Overview

VAD is a modern audio analysis tool that combines Flutter's cross-platform UI capabilities with Rust's high-performance audio processing power. This project uses Flutter Rust Bridge to seamlessly integrate both languages, providing users with powerful audio waveform visualization and FFT spectrum analysis features.

### ✨ Key Features

- 🎨 **Modern UI Design**
  - Automatic light/dark theme switching
  - Material Design 3 design language
  - Smooth animations and interactions
  - Responsive layout for various screen sizes

- 🔊 **Powerful Audio Processing**
  - Support for multiple audio formats (WAV, MP3, FLAC)
  - Real-time waveform visualization
  - Fast Fourier Transform (FFT) spectrum analysis
  - Parallel processing optimization utilizing multi-core CPUs

- 📊 **Rich Visualization**
  - Interactive audio waveform charts
  - FFT spectrum visualization
  - Adjustable sample rate and frame size
  - Downsampling support for improved performance

- 🖥️ **Cross-Platform Support**
  - Windows, macOS, Linux desktop applications
  - Web application support
  - System tray integration (desktop)
  - File drag-and-drop support

### 🛠️ Technology Stack

#### Frontend (Flutter)
- **Framework**: Flutter 3.9.4+
- **State Management**: Riverpod 3.1.0
- **UI Components**:
  - `fl_chart`: Chart visualization
  - `flex_color_scheme`: Theme management
  - `dynamic_color`: Dynamic color support
  - `animations`: Smooth animations
- **Desktop Features**:
  - `window_manager`: Window management
  - `tray_manager`: System tray
  - `desktop_drop`: Drag-and-drop support
- **Utilities**:
  - `file_picker`: File selection
  - `url_launcher`: URL launching

#### Backend (Rust)
- **Audio Processing**:
  - `symphonia`: Audio decoding (multi-format support)
  - `rustfft`: Fast Fourier Transform
  - `rayon`: Parallel computing
- **Cross-Language Communication**:
  - `flutter_rust_bridge`: Flutter-Rust bridge

### 📋 System Requirements

- **OS**: Windows 10+, macOS 10.15+, Linux (Ubuntu 20.04+), or modern browsers
- **Flutter SDK**: 3.9.4 or higher
- **Rust**: 1.70 or higher
- **Dart SDK**: 3.9.4 or higher

#### Additional Linux Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-dev libappindicator3-dev

# Fedora
sudo dnf install gtk3-devel libappindicator-gtk3-devel
```

### 🚀 Quick Start

#### 1. Clone Repository
```bash
git clone https://github.com/fans963/vad_flutter_and_rust.git
cd vad_flutter_and_rust
```

#### 2. Install Dependencies
```bash
# Install Flutter dependencies
flutter pub get

# Rust dependencies are automatically downloaded during build
```

#### 3. Run Project

**Desktop**:
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

**Web**:
```bash
flutter run -d chrome
```

### 🔨 Build Release

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

Build artifacts location:
- Windows: `build/windows/x64/runner/Release/`
- macOS: `build/macos/Build/Products/Release/`
- Linux: `build/linux/x64/release/bundle/`
- Web: `build/web/`

### 📂 Project Structure

```
vad_flutter_and_rust/
├── lib/                          # Flutter Dart code
│   ├── main.dart                # Application entry
│   └── src/
│       ├── rust/                # Rust bridge code (auto-generated)
│       ├── ui/                  # UI components
│       │   ├── chart_widget.dart      # Chart component
│       │   ├── pick_file_button.dart  # File picker button
│       │   ├── title_bar.dart         # Title bar
│       │   └── tool_plate.dart        # Tool panel
│       ├── provider/            # Riverpod state management
│       └── util/                # Utility functions
├── rust/                        # Rust audio processing code
│   ├── src/
│   │   ├── api/
│   │   │   ├── audio_processor.rs  # Core audio processing
│   │   │   └── util.rs             # FFT and utilities
│   │   └── lib.rs
│   └── Cargo.toml
├── rust_builder/                # Rust build configuration
├── assets/                      # Asset files
│   ├── image/                   # Images
│   └── screenshots/             # Screenshots (for docs)
├── android/                     # Android platform config
├── ios/                         # iOS platform config
├── linux/                       # Linux platform config
├── macos/                       # macOS platform config
├── windows/                     # Windows platform config
├── web/                         # Web platform config
├── pubspec.yaml                 # Flutter dependencies
├── flutter_rust_bridge.yaml     # FRB configuration
└── README.md                    # This file
```

### 🎯 Usage

1. **Launch Application**
   - After running, you'll see the main interface with a chart area

2. **Load Audio Files**
   - Click the `+` floating button in bottom-right
   - Select supported audio files (WAV, MP3, FLAC)
   - Or drag-and-drop files into the window (desktop)

3. **View Waveform**
   - Waveform displays automatically after loading
   - Zoom and pan to view different sections

4. **Analyze Spectrum**
   - Use bottom toolbar to switch to FFT view
   - Adjust frame size and other parameters

5. **Multiple Files**
   - Load multiple audio files simultaneously
   - Different colors for distinction

### 🐛 Troubleshooting

#### Linux tray_manager Build Error

If you encounter this error when building on Linux:

```
error: 'app_indicator_new' is deprecated [-Werror,-Wdeprecated-declarations]
```

**Solution**:

Add the following compile option in `linux/flutter/ephemeral/.plugin_symlinks/tray_manager/linux/CMakeLists.txt`:

```cmake
target_compile_options(${PLUGIN_NAME} PRIVATE -Wno-error=deprecated-declarations)
```

This disables deprecated API errors and allows normal compilation.

#### Flutter Rust Bridge Generation Failure

If you encounter FRB code generation issues:

```bash
# Regenerate bridge code
flutter_rust_bridge_codegen generate
```

#### Audio File Loading Issues

Ensure audio files are in supported formats and not corrupted. Currently supported formats:
- WAV (PCM)
- MP3
- FLAC

### 🔧 Development Guide

#### After Modifying Rust Code
```bash
# Regenerate Flutter-Rust bridge code
flutter_rust_bridge_codegen generate

# Re-run application
flutter run
```

#### Adding New Audio Processing Features
1. Add Rust functions in `rust/src/api/audio_processor.rs`
2. Run `flutter_rust_bridge_codegen generate` to generate Dart bindings
3. Call new functions in Flutter code

#### Debugging Tips
```bash
# Flutter debug mode
flutter run --debug

# View Rust logs
# Use println! or eprintln! in Rust code
```

### 🤝 Contributing

Contributions are welcome! If you'd like to contribute to this project:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 👥 Developers

- **fans963** - [GitHub](https://github.com/fans963)
- **🐂津哥** - Co-developer

### 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - Cross-platform UI framework
- [Rust](https://www.rust-lang.org) - High-performance systems programming language
- [Flutter Rust Bridge](https://github.com/fzyzcjy/flutter_rust_bridge) - Bridge between Flutter and Rust
- [Symphonia](https://github.com/pdeljanov/Symphonia) - Pure Rust audio decoding library
- [fl_chart](https://github.com/imaNNeo/fl_chart) - Powerful Flutter charting library

### 📞 Contact

- Repository: [https://github.com/fans963/vad_flutter_and_rust](https://github.com/fans963/vad_flutter_and_rust)
- Issue Tracker: [Issues](https://github.com/fans963/vad_flutter_and_rust/issues)

---

<div align="center">

**Made with ❤️ using Flutter and Rust**

</div>
