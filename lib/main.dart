import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vad/src/rust/api/audio_processor.dart';
import 'package:vad/src/rust/api/simple.dart';
import 'package:vad/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
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
  Float64List? _audioData;
  double _zoomLevel = 1.0; // 1.0 表示显示所有数据
  double _panPosition = 0.0; // 0.0 到 1.0，表示起始位置的比例
  static const int maxPoints = 10000; // 最大显示点数

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

        // 创建 AudioProcessor
        final audioProcessor = await AudioProcessor.newInstance(
          filePath: file.path!,
          fileData: fileContentBytes,
        );

        // 获取音频数据
        final audioData = await audioProcessor.getAudioData();

        setState(() {
          _selectedFileName = file.name;
          _fileBytesLength = fileContentBytes.length;
          _audioProcessor = audioProcessor;
          _audioData = audioData;
        });
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Action: Call Rust `greet("$_selectedFileName")`\nResult: `${greet(name: _selectedFileName)}`\nFile size: $_fileBytesLength bytes\nAudioProcessor: ${_audioProcessor != null ? 'Created' : 'Not created'}',
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _pickFile, child: const Text('选择文件')),
            if (_audioData != null) ...[
              Row(
                children: [
                  const Text('Zoom: '),
                  Expanded(
                    child: Slider(
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
                child: LineChart(
                  LineChartData(
                    minX:
                        _panPosition *
                        (_audioData!.length -
                            (_audioData!.length * _zoomLevel).toInt()),
                    maxX:
                        (_panPosition *
                            (_audioData!.length -
                                (_audioData!.length * _zoomLevel).toInt())) +
                        (_audioData!.length * _zoomLevel).toInt() -
                        1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: () {
                          int totalLength = _audioData!.length;
                          int visibleLength = (totalLength * _zoomLevel)
                              .toInt();
                          int start =
                              (_panPosition * (totalLength - visibleLength))
                                  .toInt();
                          int end = start + visibleLength;
                          int step = (visibleLength / maxPoints).ceil();
                          List<FlSpot> spots = [];
                          for (int i = start; i < end; i += step) {
                            if (i < totalLength) {
                              spots.add(FlSpot(i.toDouble(), _audioData![i]));
                            }
                          }
                          return spots;
                        }(),
                        isCurved: false,
                        color: Colors.blue,
                      ),
                    ],
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: true),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
