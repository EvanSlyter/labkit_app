import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';
import '../widgets/waveform_viewer.dart';
import 'dart:math' as math;




class Lab4_1Screen extends StatefulWidget {
  const Lab4_1Screen({super.key});
  @override
  State<Lab4_1Screen> createState() => _Lab4_1ScreenState();
}

class _Lab4_1ScreenState extends State<Lab4_1Screen> {
  final _tauCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _rA1Ctrl = TextEditingController();
  final _cA1Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab4_1;
    _tauCtrl.text = s.tauMs?.toString() ?? '';
    _notesCtrl.text = s.notesCompare ?? '';
    _rA1Ctrl.text = s.rOhm_A1?.toString() ?? '';
    _cA1Ctrl.text = s.c_uF_A1?.toString() ?? '';
  }

  @override
  void dispose() {
    _tauCtrl.dispose();
    _notesCtrl.dispose();
    _rA1Ctrl.dispose();
    _cA1Ctrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _save() {
    context.read<AppState>().updateLab4(
      tauMs: _parseDouble(_tauCtrl.text),
      notesCompare: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lab 4.1 progress saved')));
  }

  // Helper to add dummy data until BLE is wired
  WaveformData _dummyWave(String label, double amp, double phase) {
    final n = 1024;
    final sr = 20000.0;
    final samples = List<double>.generate(
      n,
      (i) => amp * math.sin(2 * math.pi * i / 64 + phase),
    );
    return WaveformData(label: label, samples: samples, sampleRateHz: sr);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 4.1: RC Response with Different Capacitors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Build circuit 4.1
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A.1 — Record Component Values',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Record the resistor and capacitor values used in Circuit 4.1.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rA1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Resistor R (Ω)',
                    ),
                    onChanged: (text) {
                      final v = double.tryParse(text.trim());
                      if (v != null) {
                        context.read<AppState>().updateLab4(rOhm_A1: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cA1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Capacitor C (µF)',
                    ),
                    onChanged: (text) {
                      final v = double.tryParse(text.trim());
                      if (v != null) {
                        context.read<AppState>().updateLab4(c_uF_A1: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A.2 — Build Circuit 4.1 and Enable Signal Generator',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit per the diagram. The only input is the signal generator. '
                    'Enable the signal generator with the specified output.',
                  ),
                  const SizedBox(height: 12),

                  // Diagram (lab4_circuit1.png)
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
                        'assets/images/labs/lab4_circuit1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: context.watch<AppState>().lab4_1.circuitBuilt_41,
                        onChanged: (v) => context.read<AppState>().updateLab4(
                          circuitBuilt_41: v ?? false,
                        ),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header label
                  Row(
                    children: [
                      Icon(
                        Icons.ssid_chart,
                        color: context.watch<AppState>().deviceConnected
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Enable signal generator input'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Enable signal generator with specific output (example settings)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final connected = context
                            .read<AppState>()
                            .deviceConnected;
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
                        if (!context.read<AppState>().lab4_1.circuitBuilt_41) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
                            ),
                          );
                          return;
                        }
                        // Example output: sine, 1 kHz, 1.0 Vpp, 0 V offset
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

                  // Disable outputs (safety)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        final connected = context
                            .read<AppState>()
                            .deviceConnected;
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

          // Part B — Save input/output waveforms (1 µF)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Save Vin/Vout (Capacitor = 1 µF)',
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
                        // TODO: replace with real BLE snapshot for Vin (1 µF)
                        context.read<AppState>().setLab4Vin_1uF(
                          _dummyWave('Vin (1 µF)', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin (1 µF) saved')),
                        );
                      },
                      child: const Text('Save Vin (1 µF)'),
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
                        // TODO: replace with real BLE snapshot for Vout (1 µF)
                        context.read<AppState>().setLab4Vout_1uF(
                          _dummyWave('Vout (1 µF)', 0.7, 0.2),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout (1 µF) saved')),
                        );
                      },
                      child: const Text('Save Vout (1 µF)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_1.vinSaved_1uF ? '✓' : '—'} | Vout ${app.lab4_1.voutSaved_1uF ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part C — Replace 1 µF with 10 µF and save waveforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Replace Capacitor with 10 µF and Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Replace the 1 µF capacitor with 10 µF, then save Vin and Vout again.',
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
                        context.read<AppState>().setLab4Vin_10uF(
                          _dummyWave('Vin (10 µF)', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin (10 µF) saved')),
                        );
                      },
                      child: const Text('Save Vin (10 µF)'),
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
                        context.read<AppState>().setLab4Vout_10uF(
                          _dummyWave('Vout (10 µF)', 0.8, 0.4),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout (10 µF) saved')),
                        );
                      },
                      child: const Text('Save Vout (10 µF)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_1.vinSaved_10uF ? '✓' : '—'} | Vout ${app.lab4_1.voutSaved_10uF ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part D — Replace 10 µF with 100 µF and save waveforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — Replace Capacitor with 100 µF and Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Replace the 10 µF capacitor with 100 µF, then save Vin and Vout again.',
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
                        context.read<AppState>().setLab4Vin_100uF(
                          _dummyWave('Vin (100 µF)', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin (100 µF) saved')),
                        );
                      },
                      child: const Text('Save Vin (100 µF)'),
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
                        context.read<AppState>().setLab4Vout_100uF(
                          _dummyWave('Vout (100 µF)', 0.9, 0.7),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout (100 µF) saved')),
                        );
                      },
                      child: const Text('Save Vout (100 µF)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_1.vinSaved_100uF ? '✓' : '—'} | Vout ${app.lab4_1.voutSaved_100uF ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part E — Measure tau using τ = R × C
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — Time Constant τ = R × C',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compute τ = R × C for your circuit and enter the value (in milliseconds).',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tauCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'τ (ms)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab4(tauMs: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part F — Compare saved waveforms and explain differences using τ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part F — Compare Waveforms (1 µF, 10 µF, 100 µF)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Open the saved waveforms for each capacitor value and explain differences using τ.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vin_1uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (1 µF)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vout_1uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (1 µF)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vin_10uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (10 µF)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vout_10uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (10 µF)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vin_100uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (100 µF)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vout_100uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (100 µF)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes: Explain differences using τ',
                    ),
                    onChanged: (text) {
                      context.read<AppState>().updateLab4(
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
                onPressed: _save,
                child: const Text('Save Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}