import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vad/src/provider/audio_process_providr.dart';

class PickFileButton extends ConsumerWidget {
  const PickFileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      tooltip: '添加音频文件',
      child: const Icon(Icons.add),
      onPressed: () async {
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'Audio',
          extensions: <String>['wav', 'mp3', 'flac'],
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
            await ref
                .read(audioProcessorProvider.notifier)
                .addFile(file.path, bytes);
            // ref.read(chartParameterProvider.notifier).add((
            //   filePath: file.path,
            //   visible: true,
            //   offset: (0.0, 0.0),
            //   index: (BigInt.zero, BigInt.from(100000)),
            //   dataType: DataType.audio,
            //   targetWidth: 1000,
            //   color: Colors.black,
            // ));
          }
        }
      },
    );
  }
}
