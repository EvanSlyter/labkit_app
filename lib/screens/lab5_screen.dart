import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';
import '../widgets/waveform_viewer.dart';
import 'dart:math' as math;

class Lab5Screen extends StatefulWidget {
  const Lab5Screen({super.key});
  @override
  State<Lab5Screen> createState() => _Lab5ScreenState();
}

class _Lab5ScreenState extends State<Lab5Screen> {
  // Controllers
  final _rPotMinCtrl = TextEditingController();
  final _rPotMaxCtrl = TextEditingController();

  final _notesPhaseCtrl = TextEditingController();

  final _timeShiftMaxCtrl = TextEditingController();
  final _phaseShiftMaxCtrl = TextEditingController();

  final _vrmsSourceCtrl = TextEditingController();
  final _vrmsPotCtrl = TextEditingController();
  final _vrmsCapCtrl = TextEditingController();

  bool? _kvlApplies;
  final _notesKVLCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab5;
    _rPotMinCtrl.text = s.rPotMinOhm?.toString() ?? '';
    _rPotMaxCtrl.text = s.rPotMaxOhm?.toString() ?? '';
    _notesPhaseCtrl.text = s.notesPhaseShift ?? '';
    _timeShiftMaxCtrl.text = s.timeShiftMsMax?.toString() ?? '';
    _phaseShiftMaxCtrl.text = s.phaseShiftDegMax?.toString() ?? '';
    _vrmsSourceCtrl.text = s.vrmsSource?.toString() ?? '';
    _vrmsPotCtrl.text = s.vrmsPot?.toString() ?? '';
    _vrmsCapCtrl.text = s.vrmsCap?.toString() ?? '';
    _kvlApplies = s.kvlApplies;
    _notesKVLCtrl.text = s.notesKVL ?? '';
  }

  @override
  void dispose() {
    _rPotMinCtrl.dispose();
    _rPotMaxCtrl.dispose();
    _notesPhaseCtrl.dispose();
    _timeShiftMaxCtrl.dispose();
    _phaseShiftMaxCtrl.dispose();
    _vrmsSourceCtrl.dispose();
    _vrmsPotCtrl.dispose();
    _vrmsCapCtrl.dispose();
    _notesKVLCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  // Dummy waveforms until BLE is wired
  WaveformData _dummyWave(String label, double amp, double phase) {
    final n = 1024;
    final sr = 20000.0;
    final samples = List<double>.generate(
      n,
      (i) => amp * math.sin(2 * math.pi * i / 64 + phase),
    );
    return WaveformData(label: label, samples: samples, sampleRateHz: sr);
  }

  void _save() {
    context.read<AppState>().updateLab5(
      rPotMinOhm: _parseDouble(_rPotMinCtrl.text),
      rPotMaxOhm: _parseDouble(_rPotMaxCtrl.text),
      notesPhaseShift: _notesPhaseCtrl.text.trim().isEmpty
          ? null
          : _notesPhaseCtrl.text.trim(),
      timeShiftMsMax: _parseDouble(_timeShiftMaxCtrl.text),
      phaseShiftDegMax: _parseDouble(_phaseShiftMaxCtrl.text),
      vrmsSource: _parseDouble(_vrmsSourceCtrl.text),
      vrmsPot: _parseDouble(_vrmsPotCtrl.text),
      vrmsCap: _parseDouble(_vrmsCapCtrl.text),
      kvlApplies: _kvlApplies,
      notesKVL: _notesKVLCtrl.text.trim().isEmpty
          ? null
          : _notesKVLCtrl.text.trim(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lab 5 progress saved')));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 5: Potentiometer and Phase Shift'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Connect potentiometer and measure min/max resistance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — Potentiometer Min/Max Resistance',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect the potentiometer on an empty breadboard section. Measure its minimum and maximum resistance (Ω).',
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
                    controller: _rPotMinCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'R_pot_min (Ω)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab5(rPotMinOhm: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rPotMaxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'R_pot_max (Ω)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab5(rPotMaxOhm: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part B — Build circuit, use actual diagram lab5_circuit1, save waveforms at min and max, compare phase shift
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Build Circuit and Save Waveforms (Min/Max)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit per the diagram. Set the potentiometer to minimum resistance, save Vin_min and Vout_min.\n'
                    'Then set the potentiometer to maximum resistance, save Vin_max and Vout_max.\n'
                    'Comment on how the phase shift changes with the potentiometer resistance.',
                  ),
                  const SizedBox(height: 12),

                  // Diagram: lab5_circuit1.png
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
                        'assets/images/labs/lab5_circuit1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab5.circuitBuilt_5,
                        onChanged: (v) => context.read<AppState>().updateLab5(
                          circuitBuilt_5: v ?? false,
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
                        child: Text('Enable signal generator (same specs)'),
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
                        if (!app.lab5.circuitBuilt_5) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
                            ),
                          );
                          return;
                        }
                        // Example: sine 1 kHz, 1.0 Vpp, 0 V offset (same specs as before)
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
                      child: const Text('Enable signal generator'),
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Save Vin_min / Vout_min
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
                        context.read<AppState>().setLab5VinMinWaveform(
                          _dummyWave('Vin_min', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin_min saved')),
                        );
                      },
                      child: const Text('Save Vin_min'),
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
                        context.read<AppState>().setLab5VoutMinWaveform(
                          _dummyWave('Vout_min', 0.6, 0.2),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout_min saved')),
                        );
                      },
                      child: const Text('Save Vout_min'),
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Save Vin_max / Vout_max
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
                        context.read<AppState>().setLab5VinMaxWaveform(
                          _dummyWave('Vin_max', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin_max saved')),
                        );
                      },
                      child: const Text('Save Vin_max'),
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
                        context.read<AppState>().setLab5VoutMaxWaveform(
                          _dummyWave('Vout_max', 0.8, 0.4),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout_max saved')),
                        );
                      },
                      child: const Text('Save Vout_max'),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final s = context.watch<AppState>().lab5;
                      return Text(
                        'Saved: Vin_min ${s.vinMinSaved ? '✓' : '—'} | Vout_min ${s.voutMinSaved ? '✓' : '—'} | '
                        'Vin_max ${s.vinMaxSaved ? '✓' : '—'} | Vout_max ${s.voutMaxSaved ? '✓' : '—'}',
                        style: const TextStyle(color: Colors.grey),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  // Compare waveforms and write about phase shift change
                  TextField(
                    controller: _notesPhaseCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText:
                          'Notes: How does phase shift change with potentiometer resistance?',
                    ),
                    onChanged: (t) {
                      context.read<AppState>().updateLab5(
                        notesPhaseShift: t.trim().isEmpty ? null : t.trim(),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  // Quick access to open saved waveforms
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context
                                .read<AppState>()
                                .lab5VinMinWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin_min'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context
                                .read<AppState>()
                                .lab5VoutMinWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout_min'),
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
                            final w = context
                                .read<AppState>()
                                .lab5VinMaxWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin_max'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context
                                .read<AppState>()
                                .lab5VoutMaxWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout_max'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Part C — Analyze Vin_max and Vout_max (time shift and phase shift)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Analyze Vin_max and Vout_max',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Open Vin_max and Vout_max, measure the time shift (ms) and calculate the phase shift (degrees). Record your values.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context
                                .read<AppState>()
                                .lab5VinMaxWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin_max'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context
                                .read<AppState>()
                                .lab5VoutMaxWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout_max'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timeShiftMaxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured time shift (ms)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab5(timeShiftMsMax: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseShiftMaxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Calculated phase shift (degrees)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab5(
                          phaseShiftDegMax: v,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part D — Measure RMS voltages (source, potentiometer, capacitor)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — RMS Measurements',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure RMS voltages of the source, the potentiometer, and the capacitor.',
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
                    controller: _vrmsSourceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'V_RMS (source, V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab5(vrmsSource: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _vrmsPotCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'V_RMS (potentiometer, V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab5(vrmsPot: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _vrmsCapCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'V_RMS (capacitor, V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab5(vrmsCap: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part E — KVL check and missing info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — KVL Check',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Does KVL apply to your measurements from Part C? If not, what information might be missing?',
                  ),
                  const SizedBox(height: 12),

                  // Yes / No checkboxes (mutually exclusive)
                  CheckboxListTile(
                    title: const Text('Yes'),
                    value: _kvlApplies == true,
                    onChanged: (checked) {
                      setState(() {
                        // If user checks Yes, set true; if they uncheck, clear selection
                        _kvlApplies = (checked ?? false) ? true : null;
                      });
                      // Persist when a definite choice is made; clear if null
                      context.read<AppState>().updateLab5(
                        kvlApplies: _kvlApplies,
                      );
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('No'),
                    value: _kvlApplies == false && _kvlApplies != null,
                    onChanged: (checked) {
                      setState(() {
                        // If user checks No, set false; if they uncheck, clear selection
                        _kvlApplies = (checked ?? false) ? false : null;
                      });
                      context.read<AppState>().updateLab5(
                        kvlApplies: _kvlApplies,
                      );
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesKVLCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText:
                          'Notes: If it does not apply, what might be missing?',
                    ),
                    onChanged: (t) {
                      context.read<AppState>().updateLab5(
                        notesKVL: t.trim().isEmpty ? null : t.trim(),
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