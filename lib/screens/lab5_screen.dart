import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';
import '../widgets/waveform_viewer.dart';

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

  void _save() {
    context.read<AppState>().updateLab5(
          rPotMinOhm: _parseDouble(_rPotMinCtrl.text),
          rPotMaxOhm: _parseDouble(_rPotMaxCtrl.text),
          notesPhaseShift:
              _notesPhaseCtrl.text.trim().isEmpty ? null : _notesPhaseCtrl.text.trim(),
          timeShiftMsMax: _parseDouble(_timeShiftMaxCtrl.text),
          phaseShiftDegMax: _parseDouble(_phaseShiftMaxCtrl.text),
          vrmsSource: _parseDouble(_vrmsSourceCtrl.text),
          vrmsPot: _parseDouble(_vrmsPotCtrl.text),
          vrmsCap: _parseDouble(_vrmsCapCtrl.text),
          kvlApplies: _kvlApplies,
          notesKVL:
              _notesKVLCtrl.text.trim().isEmpty ? null : _notesKVLCtrl.text.trim(),
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lab 5 progress saved')));
  }

  /// Meter insert helper (Parts A & D).
  void _attachMeterInsert({
    required bool connected,
    required TextEditingController controller,
    required void Function(double v) applyToState,
    int decimals = 3,
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

  Widget _meterableField({
    required bool connected,
    required String label,
    required TextEditingController controller,
    required void Function(double v) applyToState,
    int decimals = 3,
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
          onPressed: () => _attachMeterInsert(
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

  /// View-only open waveform.
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

          // Part A — Potentiometer min/max resistance
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
                    'Connect the potentiometer on an empty breadboard section. '
                    'Measure its minimum and maximum resistance (Ω).',
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
                  _meterableField(
                    connected: connected,
                    label: 'R_pot_min (Ω)',
                    controller: _rPotMinCtrl,
                    decimals: 2,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab5(rPotMinOhm: v),
                    transform: (siOhm) => siOhm,
                  ),
                  const SizedBox(height: 8),
                  _meterableField(
                    connected: connected,
                    label: 'R_pot_max (Ω)',
                    controller: _rPotMaxCtrl,
                    decimals: 2,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab5(rPotMaxOhm: v),
                    transform: (siOhm) => siOhm,
                  ),
                ],
              ),
            ),
          ),

          // Part B — Build circuit and save waveforms
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
                        onChanged: (v) =>
                            context.read<AppState>().updateLab5(
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
                              content:
                                  Text('Connect to the device to change outputs.'),
                            ),
                          );
                          return;
                        }
                        if (!app.lab5.circuitBuilt_5) {
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
                            content:
                                Text('Signal generator enabled (sine 1 kHz, 1.0 Vpp)'),
                          ),
                        );
                      },
                      child: const Text('Enable signal generator'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Save Vin_min / Vout_min via capture
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _captureWaveform(
                        connected: connected,
                        title: 'Lab 5 — Vin_min',
                        onSaved: (app, w) {
                          app.setLab5VinMinWaveform(w);
                          app.lab5.vinMinSaved = true;
                        },
                      ),
                      child: const Text('Save Vin_min'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _captureWaveform(
                        connected: connected,
                        title: 'Lab 5 — Vout_min',
                        onSaved: (app, w) {
                          app.setLab5VoutMinWaveform(w);
                          app.lab5.voutMinSaved = true;
                        },
                      ),
                      child: const Text('Save Vout_min'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Save Vin_max / Vout_max via capture
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _captureWaveform(
                        connected: connected,
                        title: 'Lab 5 — Vin_max',
                        onSaved: (app, w) {
                          app.setLab5VinMaxWaveform(w);
                          app.lab5.vinMaxSaved = true;
                        },
                      ),
                      child: const Text('Save Vin_max'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _captureWaveform(
                        connected: connected,
                        title: 'Lab 5 — Vout_max',
                        onSaved: (app, w) {
                          app.setLab5VoutMaxWaveform(w);
                          app.lab5.voutMaxSaved = true;
                        },
                      ),
                      child: const Text('Save Vout_max'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final s = context.watch<AppState>().lab5;
                      return Text(
                        'Saved: Vin_min ${s.vinMinSaved ? '✓' : '—'} | '
                        'Vout_min ${s.voutMinSaved ? '✓' : '—'} | '
                        'Vin_max ${s.vinMaxSaved ? '✓' : '—'} | '
                        'Vout_max ${s.voutMaxSaved ? '✓' : '—'}',
                        style: const TextStyle(color: Colors.grey),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesPhaseCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText:
                          'Notes: How does phase shift change with potentiometer resistance?',
                    ),
                    onChanged: (t) {
                      context.read<AppState>().updateLab5(
                            notesPhaseShift:
                                t.trim().isEmpty ? null : t.trim(),
                          );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Open waveforms
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openWaveform(
                            data: context.read<AppState>().lab5VinMinWaveform,
                            missingMsg: 'No Vin_min waveform saved yet.',
                            title: 'Lab 5 — Vin_min',
                          ),
                          child: const Text('Open Vin_min'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openWaveform(
                            data: context.read<AppState>().lab5VoutMinWaveform,
                            missingMsg: 'No Vout_min waveform saved yet.',
                            title: 'Lab 5 — Vout_min',
                          ),
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
                          onPressed: () => _openWaveform(
                            data: context.read<AppState>().lab5VinMaxWaveform,
                            missingMsg: 'No Vin_max waveform saved yet.',
                            title: 'Lab 5 — Vin_max',
                          ),
                          child: const Text('Open Vin_max'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openWaveform(
                            data: context.read<AppState>().lab5VoutMaxWaveform,
                            missingMsg: 'No Vout_max waveform saved yet.',
                            title: 'Lab 5 — Vout_max',
                          ),
                          child: const Text('Open Vout_max'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Part C — Analyze Vin_max and Vout_max
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
                          onPressed: () => _openWaveform(
                            data: context.read<AppState>().lab5VinMaxWaveform,
                            missingMsg: 'No Vin_max waveform saved yet.',
                            title: 'Lab 5 — Vin_max',
                          ),
                          child: const Text('Open Vin_max'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openWaveform(
                            data: context.read<AppState>().lab5VoutMaxWaveform,
                            missingMsg: 'No Vout_max waveform saved yet.',
                            title: 'Lab 5 — Vout_max',
                          ),
                          child: const Text('Open Vout_max'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timeShiftMaxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Measured time shift (ms)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context
                            .read<AppState>()
                            .updateLab5(timeShiftMsMax: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseShiftMaxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Calculated phase shift (degrees)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context
                            .read<AppState>()
                            .updateLab5(phaseShiftDegMax: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part D — RMS measurements (meter-insertable)
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  _meterableField(
                    connected: connected,
                    label: 'V_RMS (source, V)',
                    controller: _vrmsSourceCtrl,
                    decimals: 3,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab5(vrmsSource: v),
                    transform: (siV) => siV,
                  ),
                  const SizedBox(height: 8),
                  _meterableField(
                    connected: connected,
                    label: 'V_RMS (potentiometer, V)',
                    controller: _vrmsPotCtrl,
                    decimals: 3,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab5(vrmsPot: v),
                    transform: (siV) => siV,
                  ),
                  const SizedBox(height: 8),
                  _meterableField(
                    connected: connected,
                    label: 'V_RMS (capacitor, V)',
                    controller: _vrmsCapCtrl,
                    decimals: 3,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab5(vrmsCap: v),
                    transform: (siV) => siV,
                  ),
                ],
              ),
            ),
          ),

          // Part E — KVL check and notes
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
                  CheckboxListTile(
                    title: const Text('Yes'),
                    value: _kvlApplies == true,
                    onChanged: (checked) {
                      setState(() {
                        _kvlApplies = (checked ?? false) ? true : null;
                      });
                      context
                          .read<AppState>()
                          .updateLab5(kvlApplies: _kvlApplies);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('No'),
                    value: _kvlApplies == false && _kvlApplies != null,
                    onChanged: (checked) {
                      setState(() {
                        _kvlApplies = (checked ?? false) ? false : null;
                      });
                      context
                          .read<AppState>()
                          .updateLab5(kvlApplies: _kvlApplies);
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