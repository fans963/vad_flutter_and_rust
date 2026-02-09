# VAD Flutter & Rust Audio Analysis Tool

A professional-grade **Voice Activity Detection (VAD)** and **Audio Analysis** application built with **Flutter** for the frontend and **Rust** for high-performance signal processing.

![Project License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![Rust](https://img.shields.io/badge/Rust-%23000000.svg?style=flat&logo=rust&logoColor=white)

## 🚀 Overview

This application provides a real-time, interactive environment for analyzing audio files. By leveraging Rust's computational power and Flutter's reactive UI, it delivers smooth visualization of complex audio data, including Energy, Zero-Crossing Rate (ZCR), and FFT-based Spectral analysis.

### Key Features

*   **Multi-Algorithm VAD**: Implements Energy-based and Zero-Crossing Rate detection.
*   **Spectral Analysis**: High-performance FFT computation for frequency domain visualization.
*   **Interactive Visualization**: Professional charting with zoom, pan, and real-time range updates using Syncfusion.
*   **High Performance**: CPU-intensive audio processing is offloaded to Rust with Rayon parallelism.
*   **Universal Codec Support**: Handles various audio formats (MP3, WAV, FLAC, AAC, etc.) via the Symphonia library.
*   **Responsive UI**: Modern Material 3 design with desktop-optimized interactions (Drag-and-Drop, Tray support).
*   **Smart Caching**: Efficient memory management with key-value storage and downsampling for large audio files.

## 🏗️ Architecture

The project follows a clean separation of concerns between UI and Logic:

### Frontend (Flutter)
- **State Management**: Built with [Signals](https://pub.dev/packages/signals) for reactive and efficient UI updates.
- **FFI Communication**: Utilizes [flutter_rust_bridge (v2)](https://pub.dev/packages/flutter_rust_bridge) for seamless, type-safe interaction with Rust.
- **Visualization**: Professional charts powered by `syncfusion_flutter_charts`.

### Backend (Rust)
- **Core Engine**: `AudioProcessorEngine` orchestrates decoding, transformation, and storage.
- **Signal Processing**:
    - `rustfft`: Optimized FFT computation.
    - `rayon`: Multi-threaded data processing.
- **Decoding**: `symphonia` for fast and safe audio format handling.
- **Concurrency**: `dashmap` for high-performance concurrent data access.

## 🛠️ Getting Started

### Prerequisites

*   **Flutter SDK**: `^3.9.4`
*   **Rust Toolchain**: Stable version
*   **Cargokit**: For managing Flutter-Rust integration

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/fans963/vad_flutter_and_rust.git
    cd vad_flutter_and_rust
    ```

2.  Install Flutter dependencies:
    ```bash
    flutter pub get
    ```

3.  Generate Bridge Code (if modified):
    ```bash
    flutter_rust_bridge_codegen generate
    ```

4.  Run the application:
    ```bash
    flutter run
    ```

## 📊 Data Pipeline

1.  **Ingestion**: Audio file dropped or selected -> Format detected by Flutter.
2.  **Decoding**: Data passed to Rust -> `SymphoniaDecoder` produces f32 PCM samples.
3.  **Transformation**: PCM data runs through `EnergyCalculator`, `ZeroCrossingRateCalculator`, and `FftTransform`.
4.  **Optimization**: Results are cached and downsampled based on the current UI view width.
5.  **Streaming**: Processed data is sent back to Flutter via `StreamSink` for instantaneous display.

## 🤝 Contributing

Contributions are welcome! Whether it's a new VAD algorithm, UI improvement, or bug fix.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 👥 Developers

*   **fans963**
*   **🐂津哥**

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
Built with ❤️ using Flutter and Rust.
