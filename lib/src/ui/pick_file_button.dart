import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:vad/src/rust/api/types/chart.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';

class PickFileButton extends StatelessWidget {
  const PickFileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: '添加音频文件',
      child: const Icon(Icons.add),
      onPressed: () async {
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'Audio',
          extensions: <String>['wav', 'mp3', 'flac', 'aac', 'ogg', 'opus'],
        );
        final List<XFile> files = await openFiles(
          acceptedTypeGroups: <XTypeGroup>[typeGroup],
        );

        if (files.isNotEmpty) {
          for (var file in files) {
            final bytes = await file.readAsBytes();
            debugPrint(
              'Picked file: ${file.name}, size: ${await file.length()} bytes',
            );
            final format = file.name.split('.').last.toLowerCase();
            await audioProcessorEngine.addFile(
              file.path,
              bytes,
              format: format,
            );
            audioProcessorEngine.engine().then((engine) async {
              await engine.addChart(
                filePath: file.path,
                dataType: DataType.spectrum,
              );
              await engine.addChart(
                filePath: file.path,
                dataType: DataType.energy,
              );
              await engine.addChart(
                filePath: file.path,
                dataType: DataType.zeroCrossingRate,
              );
            });
          }
        }
      },
    );
  }
}
