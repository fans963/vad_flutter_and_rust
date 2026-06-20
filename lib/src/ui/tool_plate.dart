import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';
import 'package:vad/src/signals/audio_info_signal.dart';
import 'package:vad/src/rust/api/types/vad.dart';
import 'package:vad/src/signals/audio_player_signal.dart';
import 'package:vad/src/signals/chart_control_signal.dart';
import 'package:vad/src/signals/chart_series_signal.dart';
import 'package:vad/src/signals/page_controller_signal.dart';
import 'package:vad/src/signals/vad_signal.dart';
import 'package:vad/src/util/drag_handler.dart';

class ToolPlate extends StatelessWidget {
  const ToolPlate({super.key});

  @override
  Widget build(BuildContext context) {
    final widgets = [
      const HomePanel(),
      const InfoPanel(),
      const ControlPanel(),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: toolPlateHeightSignal.value,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            GenericDragHandle(
              onDragUpdate: (double newHeight) {
                final screenHeight = MediaQuery.of(context).size.height;
                toolPlateHeightSignal.value = newHeight.clamp(
                  50.0,
                  screenHeight * 0.6,
                );
              },
              onDragStart: () {
                return toolPlateHeightSignal.value;
              },
            ),
            Expanded(
              child: PageView(
                controller: pageControllerSignal.value,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) => pageIndexSignal.value = index,
                children: widgets,
              ),
            ),
          ],
        ),
        ),
      );
     
    });
  }
}

class HomePanel extends StatelessWidget {
  const HomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const AssetImage(
                    'assets/image/fan_avatar.png',
                  ),
                ),
                SizedBox(width: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const AssetImage(
                    'assets/image/liu_avatar.jpg',
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            AutoSizeText(
              'Developer: fans963 & 🐂津哥',
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: 1,
              minFontSize: 14,
            ),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      'Project Repository: ',
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      minFontSize: 12,
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(
                          'https://github.com/fans963/vad_flutter_and_rust',
                        );
                        await launchUrl(url);
                      },
                      child: AutoSizeText(
                        'https://github.com/fans963/vad_flutter_and_rust',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                        maxLines: 1,
                        minFontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final infoMap = audioInfoMapSignal.value;
      final colorScheme = Theme.of(context).colorScheme;

      if (infoMap.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.audio_file, size: 48, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text('暂无音频文件', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
              const SizedBox(height: 8),
              Text('拖放或点击 + 添加音频文件', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outlineVariant)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: infoMap.length,
        itemBuilder: (context, index) {
          final entry = infoMap.entries.elementAt(index);
          final filePath = entry.key;
          final info = entry.value;
          final fileName = filePath.split('/').last;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.audiotrack, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          info.format.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(label: '时长', value: formatDuration(info.durationSecs)),
                      const SizedBox(width: 8),
                      _InfoChip(label: '采样率', value: '${info.sampleRate} Hz'),
                      const SizedBox(width: 8),
                      _InfoChip(label: '声道', value: info.channels.toString()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(label: '采样数', value: formatSampleCount(info.sampleCount)),
                      const SizedBox(width: 8),
                      _InfoChip(label: '位深', value: '32-bit float'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(width: 4),
          Text(value, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  bool _engineConfigured = false;
  Timer? _debounce;
  final _vadDropdownKey = GlobalKey();
  late final _xZoomController = TextEditingController();
  late final _yZoomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    refreshVadState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _xZoomController.dispose();
    _yZoomController.dispose();
    super.dispose();
  }

  Future<void> _ensureEngineConfigured() async {
    if (_engineConfigured) return;
    _engineConfigured = true;
    final engine = await audioProcessorEngine.engine();
    await engine.setDownSamplePointsNum(
      pointsNum: BigInt.from(kDownsamplePoints),
    );
  }

  void _scheduleEngineUpdate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      _applyToEngine();
    });
  }

  Future<void> _applyToEngine() async {
    final maxIdx = chartMaxIndexSignal.value;
    if (maxIdx <= 0) return;

    await _ensureEngineConfigured();

    final (xStart, xEnd) = recomputeVisibleRanges();

    final engine = await audioProcessorEngine.engine();
    await engine.setIndexRange(start: xStart, end: xEnd);
  }

  void _showColorPicker() {
    final meta = chartSeriesManager.getSelectedMeta();
    if (meta == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: meta.color,
            onColorChanged: (color) {
              meta.color = color;
              chartSeriesManager.versionSignal.value++;
            },
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final key = chartSeriesManager.selectedKey;
    if (key == null) return;

    final (filePath, dataType) = ChartSeriesManager.parseKey(key);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除 "$filePath" 的 ${dataType.name} 数据？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await chartSeriesManager.deleteSelected();
    }
  }

  Widget _buildSeriesSelector(BuildContext context) {
    final allSeries = chartSeriesManager.getAllSeries();
    final selectedKey = chartSeriesManager.selectedKeySignal.value;

    if (allSeries.isEmpty) {
      return Text('暂无数据，请先加载音频文件',
          style: Theme.of(context).textTheme.bodySmall);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择曲线', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: selectedKey,
          isExpanded: true,
          items: allSeries.map((s) {
            final (fp, dt) = s;
            final key = ChartSeriesManager.makeKey(fp, dt);
            final fileName = fp.split('/').last;
            final color = chartSeriesManager.getColor(fp, dt);
            return DropdownMenuItem(
              value: key,
              child: Row(children: [
                Container(width: 12, height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text('$fileName — ${dt.name}', overflow: TextOverflow.ellipsis)),
              ]),
            );
          }).toList(),
          onChanged: (key) {
            if (key == null) return;
            final (fp, dt) = ChartSeriesManager.parseKey(key);
            chartSeriesManager.select(fp, dt);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _playSelected() async {
    final key = chartSeriesManager.selectedKey;
    if (key == null) return;
    final (fp, _) = ChartSeriesManager.parseKey(key);
    await playAudio(fp, startFraction: xPositionSignal.value);
  }

  Widget _buildAudioBar(BuildContext context) {
    return Watch((context) {
      final isPlaying = isPlayingSignal.value;
      final pos = playbackPositionSignal.value;
      final dur = playbackDurationSignal.value;
      final hasAudio = dur > Duration.zero;
      final fraction = playbackFractionSignal.value;

      String _fmt(Duration d) {
        final m = d.inMinutes.toString().padLeft(2, '0');
        final s = (d.inSeconds % 60).toString().padLeft(2, '0');
        return '$m:$s';
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              padding: EdgeInsets.zero,
            ),
            child: Slider(
              value: hasAudio ? fraction.clamp(0.0, 1.0) : 0.0,
              min: 0.0,
              max: 1.0,
              divisions: 1000,
              onChanged: hasAudio
                  ? (v) {
                      // Live preview: update position display while dragging
                      final totalMs = dur.inMilliseconds;
                      playbackPositionSignal.value =
                          Duration(milliseconds: (v * totalMs).round());
                      playbackFractionSignal.value = v;
                    }
                  : null,
              onChangeEnd: hasAudio
                  ? (v) => seekTo(v)
                  : null,
            ),
          ),
          // Controls row: time | play/stop | speed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Current time / total time
                Text(
                  '${_fmt(pos)} / ${_fmt(dur)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                // Stop button (small, secondary)
                IconButton(
                  icon: const Icon(Icons.stop, size: 20),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onPressed: hasAudio ? stopAudio : null,
                  tooltip: '停止',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Play / Pause button (primary, larger)
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 36,
                  ),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: togglePlayPause,
                  tooltip: isPlaying ? '暂停' : '播放',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                // Speed selector
                _SpeedSelector(),
              ],
            ),
          ),
          // Error indicator
          if (playbackErrorSignal.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Text(
                playbackErrorSignal.value!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      );
    });
  }

  Widget _buildSelectedSeriesBar(BuildContext context) {
    final selectedKey = chartSeriesManager.selectedKeySignal.value;
    final meta = chartSeriesManager.getSelectedMeta();

    if (selectedKey == null || meta == null) {
      return const SizedBox.shrink();
    }

    final (filePath, dataType) = ChartSeriesManager.parseKey(selectedKey);
    final fileName = filePath.split('/').last;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: meta.color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选中: $fileName — ${dataType.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Color indicator + picker
              GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: meta.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _showColorPicker,
                icon: const Icon(Icons.colorize, size: 18),
                label: const Text('换色'),
              ),
              // Visibility toggle
              IconButton(
                onPressed: () {
                  final (fp, dt) = ChartSeriesManager.parseKey(selectedKey);
                  chartSeriesManager.toggleVisibility(fp, dt);
                },
                icon: Icon(
                  meta.isVisible ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                tooltip: meta.isVisible ? '隐藏' : '显示',
              ),
              // Play button
              IconButton(
                onPressed: _playSelected,
                icon: const Icon(Icons.play_circle, size: 22),
                tooltip: '播放音频',
              ),
              const Spacer(),
              // Delete button
              TextButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
              // Deselect button
              TextButton(
                onPressed: () => chartSeriesManager.deselect(),
                child: const Text('取消选中'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final maxIdx = chartMaxIndexSignal.value;
      chartSeriesManager.versionSignal.value; // react to visibility/color changes
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Series selector ──
            _buildSeriesSelector(context),
            const SizedBox(height: 12),
            _buildSelectedSeriesBar(context),
            const SizedBox(height: 12),
            _buildAudioBar(context),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),

            // ── Axis controls: X and Y side by side ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // X-axis column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('X 轴', style: Theme.of(context).textTheme.titleMedium),
                      _buildCompactSlider(
                        context,
                        label: '位置',
                        value: xPositionSignal.value,
                        min: 0.0,
                        max: 1.0,
                        divisions: 200,
                        display: '${(xPositionSignal.value * 100).toStringAsFixed(0)}%',
                        onChanged: (v) {
                          xPositionSignal.value = v;
                          recomputeVisibleRanges();
                          _scheduleEngineUpdate();
                        },
                      ),
                      _buildCompactSlider(
                        context,
                        label: '缩放',
                        value: xZoomSignal.value.clamp(xZoomMinSignal.value, 1.0),
                        min: xZoomMinSignal.value,
                        max: 1.0,
                        display: '${(xZoomSignal.value * 100).toStringAsFixed(0)}%',
                        textController: _xZoomController,
                        suffix: '%',
                        textScale: 100.0,
                        onChanged: (v) {
                          xZoomSignal.value = v;
                          _xZoomController.text = (v * 100).toStringAsFixed(0);
                          recomputeVisibleRanges();
                          _scheduleEngineUpdate();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Y-axis column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Y 轴', style: Theme.of(context).textTheme.titleMedium),
                      _buildCompactSlider(
                        context,
                        label: '缩放',
                        value: yZoomSignal.value.clamp(yZoomMinSignal.value, yZoomMaxSignal.value),
                        min: yZoomMinSignal.value,
                        max: yZoomMaxSignal.value,
                        display: '${yZoomSignal.value.toStringAsFixed(1)}x',
                        textController: _yZoomController,
                        suffix: 'x',
                        onChanged: (v) {
                          yZoomSignal.value = v;
                          _yZoomController.text = v.toStringAsFixed(1);
                          recomputeVisibleRanges();
                          _scheduleEngineUpdate();
                        },
                      ),
                      _buildCompactSlider(
                        context,
                        label: '位置',
                        value: yPositionSignal.value,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        display: '${(yPositionSignal.value * 100).toStringAsFixed(0)}%',
                        onChanged: (v) {
                          yPositionSignal.value = v;
                          recomputeVisibleRanges();
                          _scheduleEngineUpdate();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Info bar ──
            Text(
              'X: ${xViewMinSignal.value.toStringAsFixed(0)} – ${xViewMaxSignal.value.toStringAsFixed(0)}  |  '
              'Y: ${yViewMinSignal.value.toStringAsFixed(3)} – ${yViewMaxSignal.value.toStringAsFixed(3)}  |  '
              'Total: ${maxIdx.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _buildVadSection(context),
          ],
        ),
      );
    });
  }

  Widget _buildCompactSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String display,
    required ValueChanged<double> onChanged,
    TextEditingController? textController,
    String? suffix,
    double textScale = 1.0,
  }) {
    return Row(
      children: [
        SizedBox(width: 36, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 64,
          child: TextField(
            controller: textController,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              border: const OutlineInputBorder(),
              suffixText: suffix,
              suffixStyle: Theme.of(context).textTheme.bodySmall,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (text) {
              final parsed = double.tryParse(text);
              if (parsed != null) {
                onChanged((parsed / textScale).clamp(min, max));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVadSection(BuildContext context) {
    return Watch((context) {
      final algorithms = vadAlgorithmsSignal.value;
      final currentAlgo = vadAlgorithmNameSignal.value;
      final params = vadParamsSignal.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 4),
          Text('VAD', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: GestureDetector(
                key: _vadDropdownKey,
                onTap: () async {
                  final box = _vadDropdownKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
                  if (overlay == null) return;
                  final selected = await showMenu<String>(
                    context: context,
                    position: RelativeRect.fromRect(
                      box.localToGlobal(Offset.zero) & box.size,
                      Offset.zero & overlay.size,
                    ),
                    items: algorithms
                        .map((n) => PopupMenuItem(
                              value: n,
                              child: Row(children: [
                                if (n == currentAlgo)
                                  const Icon(Icons.check, size: 16)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(n),
                              ]),
                            ))
                        .toList(),
                  );
                  if (selected != null) selectVadAlgorithm(selected);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(currentAlgo, style: Theme.of(context).textTheme.bodyMedium)),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final key = chartSeriesManager.selectedKey;
                if (key != null) {
                  final (fp, _) = ChartSeriesManager.parseKey(key);
                  runVadOnFile(fp);
                }
              },
              child: const Text('运行 VAD'),
            ),
          ]),
          if (params.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...params.map((p) => _buildMiniParam(context, p)),
          ],
        ],
      );
    });
  }

  Widget _buildMiniParam(BuildContext context, VadParamDef def) {
    final displayValue = def.kind == 'int'
        ? def.value.toInt().toString()
        : def.value.toStringAsFixed(3);
    return Row(children: [
      SizedBox(width: 60, child: Text(def.label, style: Theme.of(context).textTheme.bodySmall)),
      Expanded(
        child: Slider(
          value: def.value,
          min: def.min,
          max: def.max,
          divisions: def.kind == 'int' ? (def.max - def.min).toInt() : null,
          onChanged: (v) => _onVadParamChanged(def, def.kind == 'int' ? v.roundToDouble() : v),
        ),
      ),
      SizedBox(width: 36, child: Text(displayValue, style: Theme.of(context).textTheme.bodySmall)),
    ]);
  }

  Future<void> _onVadParamChanged(VadParamDef def, double value) async {
    final updated = List<VadParamDef>.from(vadParamsSignal.value);
    final idx = updated.indexWhere((p) => p.key == def.key);
    if (idx >= 0) {
      updated[idx] = VadParamDef(key: def.key, label: def.label, kind: def.kind, value: value, min: def.min, max: def.max, step: def.step);
      vadParamsSignal.value = updated;
    }
    await setVadParam(def.key, value);
  }
}

class _SpeedSelector extends StatelessWidget {
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static final _currentSpeed = signal(1.0);

  const _SpeedSelector();

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final speed = _currentSpeed.value;
      return PopupMenuButton<double>(
        tooltip: '播放速度',
        onSelected: (v) {
          _currentSpeed.value = v;
          setPlaybackSpeed(v);
        },
        itemBuilder: (_) => _speeds
            .map((s) => PopupMenuItem(
                  value: s,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s == speed)
                        const Icon(Icons.check, size: 16)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text('${s}x'),
                    ],
                  ),
                ))
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '${speed}x',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: speed != 1.0
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
          ),
        ),
      );
    });
  }
}
