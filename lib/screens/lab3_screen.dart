import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';
import '../widgets/waveform_viewer.dart';

class Lab3Screen extends StatefulWidget {
  const Lab3Screen({super.key});

  @override
  State<Lab3Screen> createState() => _Lab3ScreenState();
}

class _Lab3ScreenState extends State<Lab3Screen> {
  // Controllers for all inputs
  final _r1Ctrl = TextEditingController();
  final _r2Ctrl = TextEditingController();
  final _r3Ctrl = TextEditingController();
  final _vinDCtrl = TextEditingController();
  final _voutDCtrl = TextEditingController();
  final _notesCCtrl = TextEditingController();
  final _sfDCCtrl = TextEditingController();
  final _notesDCtrl = TextEditingController();
  final _vinAmpCtrl = TextEditingController();
  final _voutAmpCtrl = TextEditingController();
  final _sfACCtrl = TextEditingController();
  final _notesFCtrl = TextEditingController();
  final _timeShiftCtrl = TextEditingController();
  final _phaseShiftCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab3;
    _r1Ctrl.text = s.r1Ohm?.toString() ?? '';
    _r2Ctrl.text = s.r2Ohm?.toString() ?? '';
    _r3Ctrl.text = s.r3Ohm?.toString() ?? '';
    _vinDCtrl.text = s.vinVoltDC?.toString() ?? '';
    _voutDCtrl.text = s.voutVoltDC?.toString() ?? '';
    _notesCCtrl.text = s.notesC ?? '';
    _sfDCCtrl.text = s.scalingFactorDC?.toString() ?? '';
    _notesDCtrl.text = s.notesD ?? '';
    _vinAmpCtrl.text = s.vinAmp?.toString() ?? '';
    _voutAmpCtrl.text = s.voutAmp?.toString() ?? '';
    _sfACCtrl.text = s.scalingFactorAC?.toString() ?? '';
    _notesFCtrl.text = s.notesF ?? '';
    _timeShiftCtrl.text = s.timeShiftMs?.toString() ?? '';
    _phaseShiftCtrl.text = s.phaseShiftDeg?.toString() ?? '';
  }

  @override
  void dispose() {
    _r1Ctrl.dispose();
    _r2Ctrl.dispose();
    _r3Ctrl.dispose();
    _vinDCtrl.dispose();
    _voutDCtrl.dispose();
    _notesCCtrl.dispose();
    _sfDCCtrl.dispose();
    _notesDCtrl.dispose();
    _vinAmpCtrl.dispose();
    _voutAmpCtrl.dispose();
    _sfACCtrl.dispose();
    _notesFCtrl.dispose();
    _timeShiftCtrl.dispose();
    _phaseShiftCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _save() {
    context.read<AppState>().updateLab3(
          r1Ohm: _parseDouble(_r1Ctrl.text),
          r2Ohm: _parseDouble(_r2Ctrl.text),
          r3Ohm: _parseDouble(_r3Ctrl.text),
          vinVoltDC: _parseDouble(_vinDCtrl.text),
          voutVoltDC: _parseDouble(_voutDCtrl.text),
          notesC: _notesCCtrl.text.trim().isEmpty ? null : _notesCCtrl.text.trim(),
          scalingFactorDC: _parseDouble(_sfDCCtrl.text),
          notesD: _notesDCtrl.text.trim().isEmpty ? null : _notesDCtrl.text.trim(),
          vinAmp: _parseDouble(_vinAmpCtrl.text),
          voutAmp: _parseDouble(_voutAmpCtrl.text),
          scalingFactorAC: _parseDouble(_sfACCtrl.text),
          notesF: _notesFCtrl.text.trim().isEmpty ? null : _notesFCtrl.text.trim(),
          timeShiftMs: _parseDouble(_timeShiftCtrl.text),
          phaseShiftDeg: _parseDouble(_phaseShiftCtrl.text),
        );

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lab 3 progress saved')));
  }

  void _openSavedWaveform({
    required WaveformData? w,
    required String missingMsg,
    required String title,
  }) {
    if (w == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(missingMsg)));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WaveformViewer(data: w, title: title)),
    );
  }

  void _captureAndSaveInto({
    required bool connected,
    required String title,
    required void Function(WaveformData w) onSaved,
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
          onSaved: onSaved,
        ),
      ),
    );
  }

  // Meter insert helper (Lab 3 Part A/C/E)
  void _attachMeterInsert({
    required bool connected,
    required TextEditingController controller,
    required void Function(double v) applyToState,
    int decimals = 3,
  }) {
    FocusScope.of(context).unfocus();
    final app = context.read<AppState>();

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to use the meter.')),
      );
      return;
    }

    app.setActiveInsertTarget((double value) {
      controller.text = value.toStringAsFixed(decimals);
      applyToState(value);
    });

    app.showMeterOverlay(context);
  }

  Widget _meterableField({
    required bool connected,
    required String label,
    required TextEditingController controller,
    required void Function(double v) applyToState,
    int decimals = 3,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label),
            onChanged: (text) {
              final v = _parseDouble(text);
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 3: Intro to Op Amps'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Measure 3 resistor values
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — Measure Resistors (3)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Collect the resistors you will need to create the circuit. R1=1k, R2=5k. \n'
                    'Since we don’t have a 5k resistor, use two 10k resistors in parallel. \n'
                    'Instructions on how to properly connect resistors in parallel are in the index of the lab manual.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.speed, color: connected ? Colors.blue : Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          connected
                              ? 'Multimeter available'
                              : 'Connect device to use multimeter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _meterableField(
                    connected: connected,
                    label: 'R1 (Ω)',
                    controller: _r1Ctrl,
                    decimals: 2,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab3(r1Ohm: v),
                  ),
                  const SizedBox(height: 8),
                  _meterableField(
                    connected: connected,
                    label: 'R2.1 (Ω)',
                    controller: _r2Ctrl,
                    decimals: 2,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab3(r2Ohm: v),
                  ),
                  const SizedBox(height: 8),
                  _meterableField(
                    connected: connected,
                    label: 'R2.2 (Ω)',
                    controller: _r3Ctrl,
                    decimals: 2,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab3(r3Ohm: v),
                  ),
                ],
              ),
            ),
          ),

          // Part B — Build circuit, power rails, set input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Build the Circuit, Power Op-Amp Rails, Set Input',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit per the diagram. Then power the op-amp with +5 V and −5 V rails, '
                    'and apply a 0.5 V DC input to the circuit.',
                  ),
                  const SizedBox(height: 12),
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.asset(
                      'assets/images/labs/lab3_circuit1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: context.watch<AppState>().lab3.circuitBuilt,
                        onChanged: (v) =>
                            context.read<AppState>().updateLab3(circuitBuilt: v ?? false),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.power,
                        color: context.watch<AppState>().deviceConnected
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Op-amp rails (+5 / −5) and DC input'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final connected = context.read<AppState>().deviceConnected;
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to the device to change outputs.'),
                            ),
                          );
                          return;
                        }
                        if (!context.read<AppState>().lab3.circuitBuilt) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Check the box after building first.'),
                            ),
                          );
                          return;
                        }
                        context.read<AppState>().sendSetInputDc500mV();
                      },
                      child: const Text('Set Vin = 0.5 V'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        final connected = context.read<AppState>().deviceConnected;
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to the device to change outputs.'),
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

          // Part C — Measure Vin and Vout (DC)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Measure Vin and Vout (DC) and Compare',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure Vin and Vout in the DC circuit and write a note comparing with your prior simulation.',
                  ),
                  const SizedBox(height: 12),
                  _meterableField(
                    connected: connected,
                    label: 'Measured Vin (V)',
                    controller: _vinDCtrl,
                    decimals: 3,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab3(vinVoltDC: v),
                  ),
                  const SizedBox(height: 8),
                  _meterableField(
                    connected: connected,
                    label: 'Measured Vout (V)',
                    controller: _voutDCtrl,
                    decimals: 3,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab3(voutVoltDC: v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes: Comparison with simulation',
                    ),
                    onChanged: (text) {
                      context.read<AppState>().updateLab3(
                            notesC: text.trim().isEmpty ? null : text.trim(),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part D — DC scaling factor and expectation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — DC Scaling Factor and Expectation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the scaling factor (Vout/Vin) for the DC circuit and write whether it matches expectation.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sfDCCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Scaling factor (DC)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab3(scalingFactorDC: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesDCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes: is it as expected?',
                    ),
                    onChanged: (text) {
                      context.read<AppState>().updateLab3(
                            notesD: text.trim().isEmpty ? null : text.trim(),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part E — AC input, save waveforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Part E — AC Input',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Part E.1 — Switch to AC Circuit',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Switch the circuit to the AC input version as shown below.'),
                  const SizedBox(height: 12),
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.asset(
                      'assets/images/labs/lab3_circuit2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Connect to enable AC input.')),
                          );
                          return;
                        }
                        await context.read<AppState>().sendEnableSignalGeneratorSine(
                              freqHz: 1000,
                              amplitude_mVpp: 1000,
                              offset_mV: 0,
                            );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('AC signal generator enabled (placeholder)')),
                        );
                      },
                      child: const Text('Enable AC input (signal generator)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        final connected = context.read<AppState>().deviceConnected;
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Connect to the device to change outputs.')),
                          );
                          return;
                        }
                        context.read<AppState>().sendDisableOutputs();
                      },
                      child: const Text('Turn off power (Disable Outputs)'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Part E.2 — Save Waveforms',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'After switching to AC input, save the waveforms for Vin and Vout (snapshots).',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.show_chart,
                          color: connected ? Colors.blue : Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          connected
                              ? 'Waveform capture available'
                              : 'Connect device to capture waveforms',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _captureAndSaveInto(
                        connected: connected,
                        title: 'Lab 3 — Vin (AC)',
                        onSaved: (w) {
                          final app = context.read<AppState>();
                          app.setLab3VinWaveform(w);
                          app.updateLab3(acVinSaved: true);
                        },
                      ),
                      child: const Text('Save Vin waveform'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _captureAndSaveInto(
                        connected: connected,
                        title: 'Lab 3 — Vout (AC)',
                        onSaved: (w) {
                          final app = context.read<AppState>();
                          app.setLab3VoutWaveform(w);
                          app.updateLab3(acVoutSaved: true);
                        },
                      ),
                      child: const Text('Save Vout waveform'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (ctx) {
                      final s = context.watch<AppState>().lab3;
                      return Text(
                        'Saved: Vin ${s.acVinSaved ? '✓' : '—'} | Vout ${s.acVoutSaved ? '✓' : '—'}',
                        style: const TextStyle(color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part F — AC amplitudes, scaling factor, and notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part F — AC Amplitudes and Scaling Factor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure the amplitudes of Vin and Vout (AC), calculate scaling factor = Vout_amp / Vin_amp, save values, and note if as expected.',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openSavedWaveform(
                            w: context.read<AppState>().lab3VinWaveform,
                            missingMsg: 'No Vin waveform saved yet.',
                            title: 'Lab 3 — Vin',
                          ),
                          child: const Text('Open Vin waveform'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openSavedWaveform(
                            w: context.read<AppState>().lab3VoutWaveform,
                            missingMsg: 'No Vout waveform saved yet.',
                            title: 'Lab 3 — Vout',
                          ),
                          child: const Text('Open Vout waveform'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vinAmpCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Vin amplitude (V)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab3(vinAmp: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voutAmpCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Vout amplitude (V)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab3(voutAmp: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sfACCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Scaling factor (AC)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context
                            .read<AppState>()
                            .updateLab3(scalingFactorAC: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesFCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes: is it as expected?',
                    ),
                    onChanged: (text) {
                      context.read<AppState>().updateLab3(
                            notesF: text.trim().isEmpty ? null : text.trim(),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part G — time shift + phase shift
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part G — Time Shift Between Vin and Vout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure the time shift between the two waveforms and record it. '
                    'You can open the saved waveforms from Part E to analyze them.\n'
                    'Once you have the time shift, calculate the phase shift as in the prelab.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openSavedWaveform(
                            w: context.read<AppState>().lab3VinWaveform,
                            missingMsg: 'No Vin waveform saved yet.',
                            title: 'Lab 3 — Vin',
                          ),
                          child: const Text('Open Vin waveform'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openSavedWaveform(
                            w: context.read<AppState>().lab3VoutWaveform,
                            missingMsg: 'No Vout waveform saved yet.',
                            title: 'Lab 3 — Vout',
                          ),
                          child: const Text('Open Vout waveform'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timeShiftCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Time shift (ms)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab3(timeShiftMs: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseShiftCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Phase shift (deg)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context
                            .read<AppState>()
                            .updateLab3(phaseShiftDeg: v);
                      }
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