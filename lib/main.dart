import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vad/src/rust/api/audio_processor.dart';
import 'package:vad/src/rust/api/util.dart';
import 'package:vad/src/rust/frb_generated.dart';
import 'package:vad/src/util.dart';
import 'package:window_manager/window_manager.dart';

// 数据类，包含音频和FFT数据
class AudioChartData {
  final ChartData? audioData;
  final ChartData? fftData;
  AudioChartData({this.audioData, this.fftData});
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  if (isDesktop) {
    await trayManager.setIcon('assets/icon/icon.svg');
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _selectedFileName = 'Tom';
  int _fileBytesLength = 0;
  AudioProcessor? _audioProcessor;
  String? _currentFilePath;
  double _zoomLevel = 1.0; // 1.0 表示显示所有数据
  double _panPosition = 0.0; // 0.0 到 1.0，表示起始位置的比例
  static const int maxPoints = 1000; // 最大显示点数

  // 同时获取音频和FFT数据
  Future<AudioChartData> _getChartData() async {
    if (_audioProcessor == null || _currentFilePath == null) {
      return AudioChartData();
    }

    final audioDataLen = _audioProcessor!.audioDataLen(
      filePath: _currentFilePath!,
    );

    final audioData = await _audioProcessor!.getAudioData(
      filePath: _currentFilePath!,
      offset: (0.0, 0.0),
      index: (BigInt.zero, BigInt.from(128)),
    );

    ChartData fftData = await _audioProcessor!.getFftData(
      filePath: _currentFilePath!,
      offset: (0.0, 0.0),
      index: (
        BigInt.zero,
        BigInt.from(128), // 使用固定长度作为FFT索引范围
      ),
    );

    fftData = ChartData(
      index: fftData.index,
      data: await performLog10Parallel(inputData: fftData.data),
    );

    return AudioChartData(audioData: audioData, fftData: fftData);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a', 'flac'],
      withData: true,
    );
    if (result != null) {
      PlatformFile file = result.files.first;

      if (file.bytes != null) {
        final Uint8List fileContentBytes = file.bytes!;
        final filePath = file.path!;

        _audioProcessor ??= await AudioProcessor.newInstance();
        _audioProcessor?.add(filePath: filePath, fileData: fileContentBytes);

        setState(() {
          _selectedFileName = file.name;
          _fileBytesLength = fileContentBytes.length;
          _currentFilePath = filePath;
        });
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: null,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 自定义标题栏
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) async {
                if (!isDesktop) return;
                await windowManager.startDragging();
              },
              child: Container(
                height: 36,
                color: Colors.grey[900],
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Text(
                      'vad',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    // 可选：窗口控制按钮
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        if (!isDesktop) return;
                        await windowManager.close();
                      },
                      tooltip: '关闭',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _pickFile, child: const Text('选择文件')),
            if (_currentFilePath != null) ...[
              Row(
                children: [
                  const Text('Zoom: '),
                  Expanded(
                    child: Slider(
                      year2023: false,
                      value: _zoomLevel,
                      min: 0.01,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _zoomLevel = value;
                        });
                      },
                    ),
                  ),
                  Text('${(_zoomLevel * 100).toInt()}%'),
                ],
              ),
              Row(
                children: [
                  const Text('Pan: '),
                  Expanded(
                    child: Slider(
                      year2023: false,
                      value: _panPosition,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _panPosition = value;
                        });
                      },
                    ),
                  ),
                  Text('${(_panPosition * 100).toInt()}%'),
                ],
              ),
              Expanded(
                child: FutureBuilder<AudioChartData>(
                  future: _getChartData(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final chartData = snapshot.data!;
                      final audioData = chartData.audioData;
                      final fftData = chartData.fftData;

                      final lineBars = <LineChartBarData>[];

                      // 添加音频数据线（蓝色）
                      if (audioData != null && audioData.data.isNotEmpty) {
                        lineBars.add(
                          LineChartBarData(
                            dotData: FlDotData(show: false),
                            spots: List.generate(
                              audioData.data.length,
                              (i) =>
                                  FlSpot(audioData.index[i], audioData.data[i]),
                            ),
                            isCurved: false,
                            color: Colors.blue,
                          ),
                        );
                      }

                      // 添加FFT数据线（红色）
                      if (fftData != null && fftData.data.isNotEmpty) {
                        lineBars.add(
                          LineChartBarData(
                            dotData: FlDotData(show: false),
                            spots: List.generate(
                              fftData.data.length,
                              (i) => FlSpot(
                                fftData.index.isNotEmpty
                                    ? fftData.index[i]
                                    : i.toDouble(),
                                fftData.data[i],
                              ),
                            ),
                            isCurved: false,
                            color: Colors.red,
                          ),
                        );
                      }

                      if (lineBars.isEmpty) {
                        return const Center(child: Text('No data available'));
                      }

                      // 使用音频数据长度来计算缩放范围
                      final dataLength =
                          audioData?.data.length ?? fftData?.data.length ?? 0;

                      return LineChart(
                        LineChartData(
                          minX:
                              _panPosition *
                              (dataLength - (dataLength * _zoomLevel).toInt()),
                          maxX:
                              (_panPosition *
                                  (dataLength -
                                      (dataLength * _zoomLevel).toInt())) +
                              (dataLength * _zoomLevel).toInt() -
                              1,
                          lineBarsData: lineBars,
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                        ),
                      );
                    }
                    // 异步没有完成时显示空内容
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
