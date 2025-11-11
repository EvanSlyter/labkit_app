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
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lab 3 progress saved')));
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
                    'Collect the resistors you will need to create the circuit. Since we don’t have a 5k resistor, use two 10k resistors in parallel.',
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
                              ? 'Multimeter available'
                              : 'Connect device to use multimeter',
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
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _r2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R2 (Ω)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _r3Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R3 (Ω)'),
                  ),
                ],
              ),
            ),
          ),

          // Part B — Build first circuit and power it
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

                  // END diagram block
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: context.watch<AppState>().lab3.circuitBuilt,
                        onChanged: (v) => context.read<AppState>().updateLab3(
                          circuitBuilt: v ?? false,
                        ),
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

                  // Enable rails (+5 / −5)
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
                        if (!context.read<AppState>().lab3.circuitBuilt) {
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
                      },
                      child: const Text('Enable op-amp rails (+5 / −5)'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Set Vin = 0.5 V
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
                        if (!context.read<AppState>().lab3.circuitBuilt) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
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

                  // Disable outputs
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

          // Part C — Measure Vin and Vout and compare with simulation
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
                              ? 'Multimeter available'
                              : 'Connect device to use multimeter',
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
                    controller: _vinDCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vin (V)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab3(vinVoltDC: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voutDCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vout (V)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab3(voutVoltDC: v);
                      }
                    },
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

          // Part D — Save scaling factor and write expectation
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Scaling factor (DC)',
                    ),
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

          // Part E — Switch to AC input and save Vin/Vout waveforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — AC Input: Save Waveforms',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Switch the circuit to AC input as in circuit 4.3b, then save the waveforms for Vin and Vout (snapshots).',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        color: connected ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          connected
                              ? 'Oscilloscope snapshot available'
                              : 'Connect device to capture waveforms',
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
                              content: Text('Connect to capture waveforms.'),
                            ),
                          );
                          return;
                        }
                        // TODO: trigger Vin snapshot capture via BLE
                        context.read<AppState>().updateLab3(acVinSaved: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vin waveform saved (placeholder)'),
                          ),
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
                        // TODO: trigger Vout snapshot capture via BLE
                        context.read<AppState>().updateLab3(acVoutSaved: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vout waveform saved (placeholder)'),
                          ),
                        );
                      },
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
                  const SizedBox(height: 12),
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
                      child: const Text('Turn off power (Disable Outputs)'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Part F — Measure amplitudes, scaling factor (AC), and note expectation
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
                          onPressed: () {
                            final w = context.read<AppState>().lab3VinWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WaveformViewer(data: w),
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
                            final w = context.read<AppState>().lab3VoutWaveform;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WaveformViewer(data: w),
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
                    controller: _vinAmpCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Vin amplitude (V)',
                    ),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Vout amplitude (V)',
                    ),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Scaling factor (AC)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab3(scalingFactorAC: v);
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

          // Part G — Measure time shift between waveforms
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
                    'Measure the time shift between the two waveforms and record it. You can open the saved waveforms from Part E to analyze them.',
                  ),
                  const SizedBox(height: 12),

                  // Open saved waveforms (Vin, Vout)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab3VinWaveform;
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
                            final w = context.read<AppState>().lab3VoutWaveform;
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

                  // Time shift input
                  TextField(
                    controller: _timeShiftCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Time shift (ms)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab3(timeShiftMs: v);
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