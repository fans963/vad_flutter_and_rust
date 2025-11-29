import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vad/src/provider/audio_process_providr.dart';
import 'package:vad/src/provider/chart_paramater_provider.dart';

class PickFileButton extends ConsumerWidget {
  const PickFileButton({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref)  {
    return FloatingActionButton(
      tooltip: '添加音频文件',
      child: const Icon(Icons.add),
      onPressed: () async {
        FilePickerResult? result= await FilePicker.platform.pickFiles(
          withData: true,
          type: FileType.custom,
          allowedExtensions: ['wav', 'mp3', 'flac'],
        );

        if (result != null && result.files.isNotEmpty) {
          for (var file in result.files) {
            debugPrint('Picked file: ${file.name}, size: ${file.size} bytes');
            await ref.read(audioProcessorProvider.notifier).addFile(file.path!,file.bytes!);
            ref.read(chartParameterProvider.notifier).add(
              (
                filePath: file.path!,
                visible: true,
                offset: (0.0, 0.0),
                index: (BigInt.zero, BigInt.from(10000)),
                dataType: ChartDataType.Waveform,
                downSampleFactor: 10.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        } 
      },
    );
  }
}
