import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class WaveformViewer extends StatefulWidget {
  final WaveformData? data; // if non-null: view-only
  final void Function(WaveformData w)? onSaved; // if non-null: enable capture+save flow
  final String? title;

  const WaveformViewer({
    super.key,
    required this.data,
    this.onSaved,
    this.title,
  });

  @override
  State<WaveformViewer> createState() => _WaveformViewerState();
}

class _WaveformViewerState extends State<WaveformViewer> {
  double _windowSec = 5.0;
  bool _followLatest = true;
  double _windowEndSec = 0.0;

  @override
  void initState() {
    super.initState();

    // Capture mode: clear old buffer, do NOT auto-start capture.
    if (widget.onSaved != null && widget.data == null) {
      final app = context.read<AppState>();
      app.stopWaveformCapture();
      app.clearWaveformCapture();
      _followLatest = true;
      _windowEndSec = 0.0;
    }

    // View-only mode: make panning make sense.
    if (widget.data != null) {
      _followLatest = false;
    }
  }

  List<FlSpot> _toSpotsWindowed({
    required List<double> samples,
    required double sampleRateHz,
    required double windowSec,
    required bool followLatest,
    required double manualWindowEndSec,
  }) {
    final n = samples.length;
    if (n == 0) return const [];

    final totalSec = (n - 1) / sampleRateHz;
    final endSec = followLatest ? totalSec : manualWindowEndSec.clamp(0.0, totalSec);
    final startSec = (endSec - windowSec).clamp(0.0, endSec);

    final startIdx = (startSec * sampleRateHz).floor().clamp(0, n - 1);
    final endIdx = (endSec * sampleRateHz).ceil().clamp(0, n - 1);

    final spots = <FlSpot>[];
    for (int i = startIdx; i <= endIdx; i++) {
      final t = i / sampleRateHz;
      spots.add(FlSpot(t, samples[i]));
    }
    return spots;
  }

  // Whole seconds only on X axis
  Widget _bottomTitle(double value, TitleMeta meta) {
    final s = value.round();
    if ((value - s).abs() > 1e-6) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text('$s', style: const TextStyle(fontSize: 11)),
    );
  }

  // Hundredths on Y axis
  Widget _leftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bool captureEnabled = widget.onSaved != null;

    final WaveformData? shown = widget.data;
    final bool usingLive = (shown == null);
    final List<double> samples = usingLive ? app.waveformBuffer : shown.samples;

    // Keep consistent with ESP32 notify rate
    final double sampleRateHz = usingLive ? 5.0 : shown.sampleRateHz;

    final double totalSec =
        samples.isEmpty ? 0.0 : (samples.length - 1) / sampleRateHz;

    final bool viewOnly = (shown != null && !captureEnabled);
    if (viewOnly && _windowEndSec == 0.0 && totalSec > 0) {
      _windowEndSec = totalSec;
    }

    if (!_followLatest) {
      _windowEndSec = _windowEndSec.clamp(0.0, totalSec);
    }

    final spots = _toSpotsWindowed(
      samples: samples,
      sampleRateHz: sampleRateHz,
      windowSec: _windowSec,
      followLatest: _followLatest,
      manualWindowEndSec: _windowEndSec,
    );

    double minX = 0, maxX = 1;
    if (spots.isNotEmpty) {
      minX = spots.first.x;
      maxX = spots.last.x;
      if ((maxX - minX).abs() < 1e-9) maxX = minX + 1;
    }

    final title = widget.title ?? (usingLive ? 'Waveform (Capture)' : shown.label);

    // Show position slider when:
    // - view-only (always), OR
    // - capture mode but user turned off followLatest
    final bool showPositionSlider = viewOnly || !_followLatest;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (captureEnabled) ...[
              // Capture controls (no Save PNG)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (app.meterMode != MeterMode.voltage) {
                          app.setMeterMode(MeterMode.voltage);
                        }
                        app.startWaveformCapture();
                        setState(() => _followLatest = true);
                      },
                      child: const Text('Start capture'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed:
                          app.waveformCapturing ? app.stopWaveformCapture : null,
                      child: const Text('Stop'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed:
                          samples.isNotEmpty ? app.clearWaveformCapture : null,
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: app.waveformBuffer.length >= 2
                          ? () {
                              final w = app.saveWaveform(label: title);
                              if (w == null) return;
                              widget.onSaved?.call(w);
                              if (mounted) Navigator.pop(context);
                            }
                          : null,
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Text('Follow latest'),
                        Switch(
                          value: _followLatest,
                          onChanged: (v) {
                            setState(() {
                              _followLatest = v;
                              if (_followLatest) _windowEndSec = totalSec;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Window slider (zoom)
            Row(
              children: [
                const Text('Window'),
                Expanded(
                  child: Slider(
                    value: _windowSec,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: '${_windowSec.toStringAsFixed(0)} s',
                    onChanged: (v) => setState(() => _windowSec = v),
                  ),
                ),
                SizedBox(
                  width: 54,
                  child: Text('${_windowSec.toStringAsFixed(0)}s'),
                ),
              ],
            ),

            // Position slider (pan)
            if (showPositionSlider)
              Row(
                children: [
                  const Text('Position'),
                  Expanded(
                    child: Slider(
                      value: _windowEndSec.clamp(0.0, totalSec),
                      min: 0.0,
                      max: math.max(totalSec, 0.0001),
                      label: '${_windowEndSec.toStringAsFixed(1)} s',
                      onChanged: (v) => setState(() {
                        _windowEndSec = v;
                        _followLatest = false;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text('${_windowEndSec.toStringAsFixed(1)}s'),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            Expanded(
              child: spots.isEmpty
                  ? Center(
                      child: Text(
                        captureEnabled
                            ? 'No samples yet. Tap Start capture.'
                            : 'No saved waveform to display.',
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: minX,
                        maxX: maxX,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: false,
                            dotData: const FlDotData(show: false),
                            color: Colors.blue,
                            barWidth: 2,
                          ),
                        ],
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 56,
                              getTitlesWidget: _leftTitle,
                            ),
                            axisNameWidget: const Text('V'),
                            axisNameSize: 18,
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: _bottomTitle,
                            ),
                            axisNameWidget: const Text('s'),
                            axisNameSize: 18,
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                      ),
                    ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                captureEnabled
                    ? (app.waveformCapturing
                        ? 'Capturing… (${app.waveformBuffer.length} samples)'
                        : 'Samples: ${samples.length}')
                    : 'Samples: ${samples.length}',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
