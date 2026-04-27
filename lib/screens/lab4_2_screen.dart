import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';
import '../widgets/waveform_viewer.dart';

class Lab4_2Screen extends StatefulWidget {
  const Lab4_2Screen({super.key});

  @override
  State<Lab4_2Screen> createState() => _Lab4_2ScreenState();
}

class _Lab4_2ScreenState extends State<Lab4_2Screen> {
  // Controllers (A: inductors/resistor; D/E: tau values; E notes)
  final _L1Ctrl = TextEditingController();
  final _RL1Ctrl = TextEditingController();
  final _L2Ctrl = TextEditingController();
  final _RL2Ctrl = TextEditingController();
  final _L3Ctrl = TextEditingController();
  final _RL3Ctrl = TextEditingController();
  final _RCtrl = TextEditingController();
  final _tauGraphCtrl = TextEditingController(); // Part D
  final _tauCalcCtrl = TextEditingController(); // Part E
  final _tauPrelabCtrl = TextEditingController(); // Part E
  final _notesECtrl = TextEditingController(); // Part E comparison notes

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab4_2;
    _L1Ctrl.text = s.L1_mH?.toString() ?? '';
    _RL1Ctrl.text = s.RL1_Ohm?.toString() ?? '';
    _L2Ctrl.text = s.L2_mH?.toString() ?? '';
    _RL2Ctrl.text = s.RL2_Ohm?.toString() ?? '';
    _L3Ctrl.text = s.L3_mH?.toString() ?? '';
    _RL3Ctrl.text = s.RL3_Ohm?.toString() ?? '';
    _RCtrl.text = s.R_Ohm?.toString() ?? '';
    _tauGraphCtrl.text = s.tauGraph_ms?.toString() ?? '';
    _tauCalcCtrl.text = s.tauCalc_ms?.toString() ?? '';
    _tauPrelabCtrl.text = s.tauPrelab_ms?.toString() ?? '';
    _notesECtrl.text = s.notesCompare ?? '';
  }

  @override
  void dispose() {
    _L1Ctrl.dispose();
    _RL1Ctrl.dispose();
    _L2Ctrl.dispose();
    _RL2Ctrl.dispose();
    _L3Ctrl.dispose();
    _RL3Ctrl.dispose();
    _RCtrl.dispose();
    _tauGraphCtrl.dispose();
    _tauCalcCtrl.dispose();
    _tauPrelabCtrl.dispose();
    _notesECtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  /// Meter insert for Part A fields.
  void _attachMeterInsertA({
    required bool connected,
    required TextEditingController controller,
    required void Function(double v) applyToState,
    int decimals = 2,
    double Function(double siValue)? transform,
  }) {
    FocusScope.of(context).unfocus();
    final app = context.read<AppState>();

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to use the meter.')),
      );
      return;
    }

    app.setActiveInsertTarget((double valueSI) {
      final v = transform != null ? transform(valueSI) : valueSI;
      controller.text = v.toStringAsFixed(decimals);
      applyToState(v);
    });

    app.showMeterOverlay(context);
  }

  Widget _meterableFieldA({
    required bool connected,
    required String label,
    required TextEditingController controller,
    required void Function(double v) applyToState,
    int decimals = 2,
    double Function(double siValue)? transform,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label),
            onChanged: (t) {
              final v = _parseDouble(t);
              if (v != null) applyToState(v);
            },
          ),
        ),
        IconButton(
          tooltip: 'Use meter reading',
          icon: const Icon(Icons.download),
          onPressed: () => _attachMeterInsertA(
            connected: connected,
            controller: controller,
            applyToState: applyToState,
            decimals: decimals,
            transform: transform,
          ),
        ),
      ],
    );
  }

  /// Capture waveform via WaveformViewer and save into AppState.
  void _captureWaveform({
    required bool connected,
    required String title,
    required void Function(AppState app, WaveformData w) onSaved,
  }) {
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to capture waveforms.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaveformViewer(
          data: null, // capture mode
          title: title,
          onSaved: (w) {
            final app = context.read<AppState>();
            onSaved(app, w);
          },
        ),
      ),
    );
  }

  /// View-only open of saved waveform.
  void _openWaveform({
    required WaveformData? data,
    required String missingMsg,
    required String title,
  }) {
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(missingMsg)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WaveformViewer(data: data, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 4.2: RL Response with Inductors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Measure inductors and resistor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — Measure Inductors and Resistor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure the inductance (mH) and internal resistance (Ω) of three inductors, '
                    'and the resistance of the resistor R. Record the values below.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        color: connected ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          connected
                              ? 'Meter available'
                              : 'Connect device to use meter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // L1 (mH) & R_L1 (Ω)
                  _meterableFieldA(
                    connected: connected,
                    label: 'L1 (mH)',
                    controller: _L1Ctrl,
                    applyToState: (v) =>
                        app.updateLab4_2(L1_mH: v),
                    transform: (siH) => siH * 1e3, // H -> mH
                  ),
                  const SizedBox(height: 8),
                  _meterableFieldA(
                    connected: connected,
                    label: 'R_L1 (Ω)',
                    controller: _RL1Ctrl,
                    applyToState: (v) =>
                        app.updateLab4_2(RL1_Ohm: v),
                    transform: (siOhm) => siOhm,
                  ),
                  const SizedBox(height: 12),
                  // L2 & R_L2
                  _meterableFieldA(
                    connected: connected,
                    label: 'L2 (mH)',
                    controller: _L2Ctrl,
                    applyToState: (v) =>
                        app.updateLab4_2(L2_mH: v),
                    transform: (siH) => siH * 1e3,
                  ),
                  const SizedBox(height: 8),
                  _meterableFieldA(
                    connected: connected,
                    label: 'R_L2 (Ω)',
                    controller: _RL2Ctrl,
                    applyToState: (v) =>
                        app.updateLab4_2(RL2_Ohm: v),
                    transform: (siOhm) => siOhm,
                  ),
                  const SizedBox(height: 12),
                  // L3 & R_L3
                  _meterableFieldA(
                    connected: connected,
                    label: 'L3 (mH)',
                    controller: _L3Ctrl,
                    applyToState: (v) =>
                        app.updateLab4_2(L3_mH: v),
                    transform: (siH) => siH * 1e3,
                  ),
                  const SizedBox(height: 8),
                  _meterableFieldA(
                    connected: connected,
                    label: 'R_L3 (Ω)',
                    controller: _RL3Ctrl,
                    applyToState: (v) =>
                        app.updateLab4_2(RL3_Ohm: v),
                    transform: (siOhm) => siOhm,
                  ),
                  const SizedBox(height: 12),
                  _meterableFieldA(
                    connected: connected,
                    label: 'R (Ω)',
                    controller: _RCtrl,
                    applyToState: (v) =>
                        app.updateLab4_2(R_Ohm: v),
                    transform: (siOhm) => siOhm,
                  ),
                ],
              ),
            ),
          ),

          // Part B — Build circuit and enable signal generator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Build Circuit and Enable Signal Generator',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit per the diagram. The input is provided by the signal generator.\n\n'
                    'Tips:\n'
                    '• Use the three inductors in series to create a 360 mH inductor.\n'
                    '• The 420 Ω resistor is the sum of the internal resistances of the inductors; NOT an external resistor.\n',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Image.asset(
                        'assets/images/labs/lab4_circuit2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab4_2.circuitBuilt_42,
                        onChanged: (v) =>
                            context.read<AppState>().updateLab4_2(
                                  circuitBuilt_42: v ?? false,
                                ),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.ssid_chart,
                        color: connected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Enable signal generator input'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Connect to the device to change outputs.'),
                            ),
                          );
                          return;
                        }
                        if (!app.lab4_2.circuitBuilt_42) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Check the box after building first.'),
                            ),
                          );
                          return;
                        }
                        context.read<AppState>().sendEnableSignalGeneratorSine(
                              freqHz: 1000,
                              amplitude_mVpp: 1000,
                              offset_mV: 0,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Signal generator enabled (sine 1 kHz, 1.0 Vpp)'),
                          ),
                        );
                      },
                      child: const Text(
                        'Enable signal generator (sine 1 kHz, 1.0 Vpp)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Connect to the device to change outputs.'),
                            ),
                          );
                          return;
                        }
                        context.read<AppState>().sendDisableOutputs();
                      },
                      child: const Text('Disable Outputs'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Part C — Save Vin and Vout waveforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Save Vin and Vout Waveforms',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture and save the input (Vin) and output (Vout) waveforms.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _captureWaveform(
                        connected: connected,
                        title: 'Lab 4.2 — Vin',
                        onSaved: (app, w) {
                          app.setLab4_2VinWaveform(w);
                          app.lab4_2.vinSaved_42 = true;
                        },
                      ),
                      child: const Text('Save Vin waveform'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _captureWaveform(
                        connected: connected,
                        title: 'Lab 4.2 — Vout',
                        onSaved: (app, w) {
                          app.setLab4_2VoutWaveform(w);
                          app.lab4_2.voutSaved_42 = true;
                        },
                      ),
                      child: const Text('Save Vout waveform'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_2.vinSaved_42 ? '✓' : '—'} | '
                    'Vout ${app.lab4_2.voutSaved_42 ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part D — τ from waveform cursor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — τ from Waveform Cursor (ms)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use the waveform cursor method (as in prelab) to determine τ from a saved waveform. Enter τ (in ms).',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openWaveform(
                            data: context.read<AppState>().lab4_2VinWaveform,
                            missingMsg:
                                'No Vin waveform saved yet for Lab 4.2.',
                            title: 'Lab 4.2 — Vin',
                          ),
                          child: const Text('Open Vin waveform'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openWaveform(
                            data: context.read<AppState>().lab4_2VoutWaveform,
                            missingMsg:
                                'No Vout waveform saved yet for Lab 4.2.',
                            title: 'Lab 4.2 — Vout',
                          ),
                          child: const Text('Open Vout waveform'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tauGraphCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'τ (ms) — from cursor measurement',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) context.read<AppState>().updateLab4_2(
                            tauGraph_ms: v,
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part E — τ = L / (R + RL) and comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — τ = L / (R + RL) (ms) and Comparison',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compute τ using τ = L / (R + RL), where L is total inductance, R is the resistor, and RL is the total resistance of the inductor(s).\n'
                    'Enter your calculated τ and the prelab τ, then write a note comparing these values with τ from Part D.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tauCalcCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'τ_calc (ms) — L / (R + RL)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) context.read<AppState>().updateLab4_2(
                            tauCalc_ms: v,
                          );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tauPrelabCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'τ_prelab (ms)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) context.read<AppState>().updateLab4_2(
                            tauPrelab_ms: v,
                          );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesECtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText:
                          'Notes: Compare τ_calc, τ_prelab, and τ_cursor (Part D)',
                    ),
                    onChanged: (text) {
                      context.read<AppState>().updateLab4_2(
                            notesCompare:
                                text.trim().isEmpty ? null : text.trim(),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Labs'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.read<AppState>().updateLab4_2(
                        L1_mH: _parseDouble(_L1Ctrl.text),
                        RL1_Ohm: _parseDouble(_RL1Ctrl.text),
                        L2_mH: _parseDouble(_L2Ctrl.text),
                        RL2_Ohm: _parseDouble(_RL2Ctrl.text),
                        L3_mH: _parseDouble(_L3Ctrl.text),
                        RL3_Ohm: _parseDouble(_RL3Ctrl.text),
                        R_Ohm: _parseDouble(_RCtrl.text),
                        tauGraph_ms: _parseDouble(_tauGraphCtrl.text),
                        tauCalc_ms: _parseDouble(_tauCalcCtrl.text),
                        tauPrelab_ms: _parseDouble(_tauPrelabCtrl.text),
                        notesCompare: _notesECtrl.text.trim().isEmpty
                            ? null
                            : _notesECtrl.text.trim(),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lab 4.2 progress saved'),
                    ),
                  );
                },
                child: const Text('Save Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}