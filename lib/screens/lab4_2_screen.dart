import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';
import '../widgets/waveform_viewer.dart';
import 'dart:math' as math;

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

  WaveformData _dummyWave(String label, double amp, double phase) {
    final n = 1024;
    final sr = 20000.0;
    final samples = List<double>.generate(
      n,
      (i) => amp * math.sin(2 * math.pi * i / 64 + phase),
    );
    return WaveformData(label: label, samples: samples, sampleRateHz: sr);
  }

  void _saveAll() {
    final app = context.read<AppState>();
    app.updateLab4_2(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lab 4.2 progress saved')));
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

          // Part A — Measure inductance and resistance of 3 inductors + resistor R
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
                    'Measure the inductance (mH) and internal resistance (Ω) of three inductors, and the resistance of the resistor R. Record the values below.',
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
                      ElevatedButton(
                        onPressed: () {
                          FocusScope.of(
                            context,
                          ).unfocus(); // hide keyboard immediately
                          final app = context.read<AppState>();
                          if (!app.deviceConnected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the meter.'),
                              ),
                            );
                            return;
                          }
                          app.showMeterOverlay(context);
                        },
                        child: const Text('Open Meter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Inductor 1
                  TextField(
                    controller: _L1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'L1 (mH)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(L1_mH: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _RL1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R_L1 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(RL1_Ohm: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Inductor 2
                  TextField(
                    controller: _L2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'L2 (mH)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(L2_mH: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _RL2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R_L2 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(RL2_Ohm: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Inductor 3
                  TextField(
                    controller: _L3Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'L3 (mH)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(L3_mH: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _RL3Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R_L3 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(RL3_Ohm: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Resistor R
                  TextField(
                    controller: _RCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(R_Ohm: v);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part B — Build circuit and enable signal generator (same specs), with tip text
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
                    '• The 420 Ω resistor is the sum of the internal resistances of the inductors; NOT an external resistor. \n',
                  ),
                  const SizedBox(height: 12),
                  // Diagram placeholder (replace with your asset if available)
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
                        onChanged: (v) => context.read<AppState>().updateLab4_2(
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
                              content: Text(
                                'Connect to the device to change outputs.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (!app.lab4_2.circuitBuilt_42) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
                            ),
                          );
                          return;
                        }
                        // Same specs as before: sine 1 kHz, 1.0 Vpp, 0 V offset
                        context.read<AppState>().sendEnableSignalGeneratorSine(
                          freqHz: 1000,
                          amplitude_mVpp: 1000,
                          offset_mV: 0,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Signal generator enabled (sine 1 kHz, 1.0 Vpp)',
                            ),
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
                              content: Text(
                                'Connect to the device to change outputs.',
                              ),
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

          // Part C — Measure and save input/output waveforms
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
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to capture waveforms.'),
                            ),
                          );
                          return;
                        }
                        // TODO: replace dummy with real snapshot via BLE
                        context.read<AppState>().setLab4_2VinWaveform(
                          _dummyWave('Vin (4.2)', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin waveform saved')),
                        );
                      },
                      child: const Text('Save Vin waveform'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to capture waveforms.'),
                            ),
                          );
                          return;
                        }
                        // TODO: replace dummy with real snapshot via BLE
                        context.read<AppState>().setLab4_2VoutWaveform(
                          _dummyWave('Vout (4.2)', 0.7, 0.3),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout waveform saved')),
                        );
                      },
                      child: const Text('Save Vout waveform'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_2.vinSaved_42 ? '✓' : '—'} | Vout ${app.lab4_2.voutSaved_42 ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part D — Measure tau using cursor on saved waveforms (as in prelab)
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
                          onPressed: () {
                            final w = context
                                .read<AppState>()
                                .lab4_2VinWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin waveform'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context
                                .read<AppState>()
                                .lab4_2VoutWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout waveform'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tauGraphCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'τ (ms) — from cursor measurement',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) app.updateLab4_2(tauGraph_ms: v);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part E — Calculate τ = L / (R + RL) and compare
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'τ_calc (ms) — L / (R + RL)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) app.updateLab4_2(tauCalc_ms: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tauPrelabCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'τ_prelab (ms)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) app.updateLab4_2(tauPrelab_ms: v);
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
                      app.updateLab4_2(
                        notesCompare: text.trim().isEmpty ? null : text.trim(),
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
                onPressed: _saveAll,
                child: const Text('Save Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
