import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:vad/src/rust/api/types/chart.dart';
import 'package:vad/src/rust/api/types/vad.dart';
import 'package:vad/src/signals/chart_series_signal.dart';
import 'package:vad/src/signals/vad_signal.dart';

class VadControlPanel extends StatefulWidget {
  const VadControlPanel({super.key});

  @override
  State<VadControlPanel> createState() => _VadControlPanelState();
}

class _VadControlPanelState extends State<VadControlPanel> {
  @override
  void initState() {
    super.initState();
    refreshVadState();
  }

  Future<void> _onAlgorithmChanged(String? name) async {
    if (name == null) return;
    await selectVadAlgorithm(name);
  }

  bool _computing = false;

  Future<void> _runVad() async {
    final selected = chartSeriesManager.selectedKey;
    if (selected == null) return;
    final (filePath, _) = ChartSeriesManager.parseKey(selected);

    setState(() => _computing = true);
    try {
      await runVadOnFile(filePath);
    } finally {
      if (mounted) setState(() => _computing = false);
    }
  }

  Future<void> _onParamChanged(VadParamDef def, double value) async {
    final updated = List<VadParamDef>.from(vadParamsSignal.value);
    final idx = updated.indexWhere((p) => p.key == def.key);
    if (idx >= 0) {
      updated[idx] = VadParamDef(
        key: def.key,
        label: def.label,
        kind: def.kind,
        value: value,
        min: def.min,
        max: def.max,
        step: def.step,
      );
      vadParamsSignal.value = updated;
    }
    await setVadParam(def.key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final algorithms = vadAlgorithmsSignal.value;
      final currentAlgo = vadAlgorithmNameSignal.value;
      final params = vadParamsSignal.value;

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          // Algorithm selector
          Text('VAD 算法', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: algorithms.contains(currentAlgo) ? currentAlgo : null,
            items: algorithms
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: _onAlgorithmChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic parameter controls
          if (params.isNotEmpty)
            Text('参数调节', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...params.map((p) => _buildParamControl(context, p)),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),

          _buildRunButton(context),
        ],
      );
    });
  }

  Widget _buildParamControl(BuildContext context, VadParamDef def) {
    switch (def.kind) {
      case 'float':
        return _buildSlider(context, def);
      case 'int':
        return _buildSlider(context, def);
      case 'bool':
        return _buildSwitch(context, def);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSlider(BuildContext context, VadParamDef def) {
    final isInt = def.kind == 'int';
    final displayValue = isInt ? def.value.toInt().toString() : def.value.toStringAsFixed(3);
    final divisions = isInt ? (def.max - def.min).toInt() : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(def.label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Slider(
              value: def.value,
              min: def.min,
              max: def.max,
              divisions: divisions,
              onChanged: (v) => _onParamChanged(def, isInt ? v.roundToDouble() : v),
            ),
          ),
          SizedBox(width: 48, child: Text(displayValue, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildSwitch(BuildContext context, VadParamDef def) {
    return SwitchListTile(
      title: Text(def.label),
      value: def.value >= 0.5,
      onChanged: (v) => _onParamChanged(def, v ? 1.0 : 0.0),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRunButton(BuildContext context) {
    final selected = chartSeriesManager.selectedKeySignal.value;
    final hasResult = selected != null && chartSeriesManager.getAllSeries().any(
      (s) => s.$1 == ChartSeriesManager.parseKey(selected).$1 && s.$2 == DataType.vad,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected == null)
          Text('请先在图表中点击图例选择一条曲线', style: Theme.of(context).textTheme.bodySmall)
        else ...[
          Text('选中文件: ${ChartSeriesManager.parseKey(selected).$1.split('/').last}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _computing ? null : _runVad,
            icon: _computing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: Text(_computing ? '计算中...' : (hasResult ? '重新计算 VAD' : '运行 VAD')),
          ),
        ],
      ],
    );
  }
}
