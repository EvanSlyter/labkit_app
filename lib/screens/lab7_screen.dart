import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';
import '../widgets/waveform_viewer.dart';
import 'dart:math' as math;

class Lab7Screen extends StatefulWidget {
  const Lab7Screen({super.key});
  @override
  State<Lab7Screen> createState() => _Lab7ScreenState();
}

class _Lab7ScreenState extends State<Lab7Screen> {
  // Part A controllers
  final _r1Ctrl = TextEditingController();
  final _r2Ctrl = TextEditingController();
  final _r3Ctrl = TextEditingController();
  final _cCtrl = TextEditingController();

  // Part B (sine) controllers
  final _vinAmpSineCtrl = TextEditingController();
  final _voutAmpSineCtrl = TextEditingController();
  final _phaseSineCtrl = TextEditingController();

  // Part C (square) controllers
  final _vinAmpSquareCtrl = TextEditingController();
  final _voutAmpSquareCtrl = TextEditingController();
  final _phaseSquareCtrl = TextEditingController();

  // Part D (triangle) controllers
  final _vinAmpTriCtrl = TextEditingController();
  final _voutAmpTriCtrl = TextEditingController();
  final _phaseTriCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab7;
    _r1Ctrl.text = s.r1Ohm?.toString() ?? '';
    _r2Ctrl.text = s.r2Ohm?.toString() ?? '';
    _r3Ctrl.text = s.r3Ohm?.toString() ?? '';
    _cCtrl.text = s.c_uF?.toString() ?? '';

    _vinAmpSineCtrl.text = s.vinAmpSine_V?.toString() ?? '';
    _voutAmpSineCtrl.text = s.voutAmpSine_V?.toString() ?? '';
    _phaseSineCtrl.text = s.phaseDegSine?.toString() ?? '';

    _vinAmpSquareCtrl.text = s.vinAmpSquare_V?.toString() ?? '';
    _voutAmpSquareCtrl.text = s.voutAmpSquare_V?.toString() ?? '';
    _phaseSquareCtrl.text = s.phaseDegSquare?.toString() ?? '';

    _vinAmpTriCtrl.text = s.vinAmpTri_V?.toString() ?? '';
    _voutAmpTriCtrl.text = s.voutAmpTri_V?.toString() ?? '';
    _phaseTriCtrl.text = s.phaseDegTri?.toString() ?? '';
  }

  @override
  void dispose() {
    _r1Ctrl.dispose();
    _r2Ctrl.dispose();
    _r3Ctrl.dispose();
    _cCtrl.dispose();
    _vinAmpSineCtrl.dispose();
    _voutAmpSineCtrl.dispose();
    _phaseSineCtrl.dispose();
    _vinAmpSquareCtrl.dispose();
    _voutAmpSquareCtrl.dispose();
    _phaseSquareCtrl.dispose();
    _vinAmpTriCtrl.dispose();
    _voutAmpTriCtrl.dispose();
    _phaseTriCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  WaveformData _dummyWave(String label, double amp, double phase) {
    final n = 1024, sr = 20000;
    final samples = List<double>.generate(
      n,
      (i) => amp * math.sin(2 * math.pi * i / 64 + phase),
    );
    return WaveformData(
      label: label,
      samples: samples,
      sampleRateHz: sr.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 7: Waveforms with Op-Amp'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Measure components and build circuit (with diagram)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — Measure Components and Build Circuit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure R1, R2, R3 (Ω) and C (µF), then build the circuit per the diagram. \n'
                    'Note: The 5k resistor R2 should be made with two 10k resistors in parallel.',
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
                        'assets/images/labs/lab7_circuit1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
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
final app = context.read<AppState>();
if (!app.deviceConnected) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Connect to use the meter.')),
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
                  TextField(
                    controller: _r1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R1 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Components(r1Ohm: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _r2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R2 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Components(r2Ohm: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _r3Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R3 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Components(r3Ohm: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'C (µF)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Components(c_uF: v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab7.circuitBuilt_7,
                        onChanged: (v) =>
                            context.read<AppState>().setLab7Built(v ?? false),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Part B — Sine: enable rails + generator, save Vin/Vout, measure amplitudes and phase
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Sine Wave (f = 30 Hz, 0°, 0 V offset, 0.5 V amplitude)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable op-amp rails (+/− 5 V), set the generator to sine. Save Vin and Vout snapshots. Measure amplitudes and phase between waves.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.power,
                        color: connected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Enable op-amp rails (+/− 5 V)'),
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
                              content: Text('Connect to change outputs.'),
                            ),
                          );
                          return;
                        }
                        if (!app.lab7.circuitBuilt_7) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
                            ),
                          );
                          return;
                        }
                        context
                            .read<AppState>()
                            .sendEnableOpAmpRailsPlusMinus5();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Op-amp rails enabled')),
                        );
                      },
                      child: const Text('Enable rails'),
                    ),
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
                        child: Text(
                          'Set generator: sine, 30 Hz, 0°, 0 V offset, 0.5 V amplitude',
                        ),
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
                              content: Text('Connect to set generator.'),
                            ),
                          );
                          return;
                        }
                        // NOTE: amplitude interpretation:
                        // If 0.5 V means peak-to-peak, pass 500 mVpp; if 0.5 V peak, pass 1000 mVpp.
                        context.read<AppState>().sendEnableSignalGeneratorSine(
                          freqHz: 30,
                          amplitude_mVpp: 500,
                          offset_mV: 0,
                          phase_mdeg: 0,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generator set: sine 30 Hz, 0.5 V'),
                          ),
                        );
                      },
                      child: const Text('Enable sine generator'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VinSine(
                              _dummyWave('Vin (sine)', 0.25, 0.0),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vin (sine) saved')),
                            );
                          },
                          child: const Text('Save Vin (sine)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VoutSine(
                              _dummyWave('Vout (sine)', 0.20, 0.3),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vout (sine) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vout (sine)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VinSine;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (sine)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VoutSine;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (sine)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vinAmpSineCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vin amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Sine(vinAmp_V: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voutAmpSineCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vout amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Sine(voutAmp_V: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseSineCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Phase shift (degrees)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Sine(phaseDeg: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to change outputs.'),
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

          // Part C — Square wave
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Square Wave (f = 30 Hz, 0°, 0 V offset, 0.5 V amplitude)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set the generator to square. Save Vin and Vout snapshots. Measure amplitudes and phase shift.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to set generator.'),
                            ),
                          );
                          return;
                        }
                        context
                            .read<AppState>()
                            .sendEnableSignalGeneratorSquare(
                              freqHz: 30,
                              amplitude_mVpp: 500,
                              offset_mV: 0,
                              phase_mdeg: 0,
                              duty_per_mille: 500,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generator set: square 30 Hz, 0.5 V'),
                          ),
                        );
                      },
                      child: const Text('Enable square generator'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VinSquare(
                              _dummyWave('Vin (square)', 0.25, 0.0),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vin (square) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vin (square)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VoutSquare(
                              _dummyWave('Vout (square)', 0.20, 0.3),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vout (square) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vout (square)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VinSquare;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (square)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VoutSquare;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (square)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vinAmpSquareCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vin amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Square(vinAmp_V: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voutAmpSquareCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vout amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Square(voutAmp_V: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseSquareCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Phase shift (degrees)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Square(phaseDeg: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part D — Triangle wave
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — Triangle Wave (f = 30 Hz, 0°, 0 V offset, 0.5 V amplitude)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set the generator to triangle. Save Vin and Vout snapshots. Measure amplitudes and phase shift.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to set generator.'),
                            ),
                          );
                          return;
                        }
                        context
                            .read<AppState>()
                            .sendEnableSignalGeneratorTriangle(
                              freqHz: 30,
                              amplitude_mVpp: 500,
                              offset_mV: 0,
                              phase_mdeg: 0,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Generator set: triangle 30 Hz, 0.5 V',
                            ),
                          ),
                        );
                      },
                      child: const Text('Enable triangle generator'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VinTri(
                              _dummyWave('Vin (triangle)', 0.25, 0.0),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vin (triangle) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vin (triangle)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VoutTri(
                              _dummyWave('Vout (triangle)', 0.20, 0.3),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vout (triangle) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vout (triangle)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VinTri;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (triangle)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VoutTri;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (triangle)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vinAmpTriCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vin amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Tri(vinAmp_V: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voutAmpTriCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vout amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Tri(voutAmp_V: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseTriCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Phase shift (degrees)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab7Tri(phaseDeg: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to change outputs.'),
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

          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Labs'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lab 7 progress saved (values persist in memory)',
                    ),
                  ),
                ),
                child: const Text('Save Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}