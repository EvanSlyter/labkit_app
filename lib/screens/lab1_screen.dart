import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';

class Lab1Screen extends StatefulWidget {
  const Lab1Screen({super.key});

  @override
  State<Lab1Screen> createState() => _Lab1ScreenState();
}

class _Lab1ScreenState extends State<Lab1Screen> {
  // Controllers for inputs
  final _rA1Ctrl = TextEditingController();
  final _rA2Ctrl = TextEditingController();
  final _vCCtrl = TextEditingController();
  final _v1CtrlCalc = TextEditingController();
  final _v2CtrlCalc = TextEditingController();
  final _v1CtrlMeasure = TextEditingController();
  final _v2CtrlMeasure = TextEditingController();
  final _notesDCtrl = TextEditingController();
  final _notesFCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _rA1Ctrl.text = state.lab1.rA1Ohm?.toString() ?? '';
    _rA2Ctrl.text = state.lab1.rA2Ohm?.toString() ?? '';
    _vCCtrl.text = state.lab1.vCVolt?.toString() ?? '';
    _v1CtrlCalc.text = state.lab1.v1VoltCalc?.toString() ?? '';
    _v1CtrlMeasure.text = state.lab1.v1VoltMeasure?.toString() ?? '';
    _v2CtrlCalc.text = state.lab1.v2VoltCalc?.toString() ?? '';
    _v2CtrlMeasure.text = state.lab1.v2VoltMeasure?.toString() ?? '';
    _notesDCtrl.text = state.lab1.notesD ?? '';
    _notesFCtrl.text = state.lab1.notesF ?? '';
  }

  @override
  void dispose() {
    _rA1Ctrl.dispose();
    _rA2Ctrl.dispose();
    _vCCtrl.dispose();
    _v1CtrlCalc.dispose();
    _v2CtrlCalc.dispose();
    _v1CtrlMeasure.dispose();
    _v2CtrlMeasure.dispose();
    _notesDCtrl.dispose();
    _notesFCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _saveProgress() {
    final state = context.read<AppState>();
    state.updateLab1(
      rA1Ohm: _parseDouble(_rA1Ctrl.text),
      rA2Ohm: _parseDouble(_rA2Ctrl.text),
      vCVolt: _parseDouble(_vCCtrl.text),
      v1VoltCalc: _parseDouble(_v1CtrlCalc.text),
      v1VoltMeasure: _parseDouble(_v1CtrlMeasure.text),
      v2VoltCalc: _parseDouble(_v2CtrlCalc.text),
      v2VoltMeasure: _parseDouble(_v2CtrlMeasure.text),
      notesD: _notesDCtrl.text.trim().isEmpty ? null : _notesDCtrl.text.trim(),
      notesF: _notesFCtrl.text.trim().isEmpty ? null : _notesFCtrl.text.trim(),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lab 1 progress saved')));
  }

  /// Attach meter insert behavior to a specific field.
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
    final state = context.watch<AppState>();
    final connected = state.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 1: Ohm’s and Kirchoff’s Laws'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // PART A — Measure resistance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — Measure Resistance',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'In your component kit, find the two resistors you will need to construct the circuit (as shown below). '
                    'Use the Multimeter to measure both resistor values. They are nominally 100 and 220 ohms but may vary.',
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  _meterableField(
                    connected: connected,
                    label: 'Measured R1 (Ω)',
                    controller: _rA1Ctrl,
                    decimals: 2,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab1(rA1Ohm: v),
                  ),
                  const SizedBox(height: 8),
                  _meterableField(
                    connected: connected,
                    label: 'Measured R2 (Ω)',
                    controller: _rA2Ctrl,
                    decimals: 2,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab1(rA2Ohm: v),
                  ),
                ],
              ),
            ),
          ),

          // PART B — Build circuit
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Build the Circuit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit based on the provided diagram (1.1d).',
                  ),
                  const SizedBox(height: 12),
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.asset(
                      'assets/images/labs/lab1_circuit1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: context.watch<AppState>().lab1.circuitBuilt,
                        onChanged: (v) => context
                            .read<AppState>()
                            .updateLab1(circuitBuilt: v ?? false),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.power,
                            color: connected ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Enable positive supply to +5 V'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: connected
                              ? () => context
                                  .read<AppState>()
                                  .sendSetPositiveSupply5V()
                              : null,
                          child: const Text('Enable +5 V'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: connected
                              ? () => context
                                  .read<AppState>()
                                  .sendDisableOutputs()
                              : null,
                          child: const Text('Disable'),
                        ),
                      ),
                      if (!connected)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Connect to the device to change outputs.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // PART C — Measure Vs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Measure Voltage at Node',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure Vs using the Multimeter (the voltage source; nominally 5 V).\n'
                    'From now on, whenever you are using a voltage source, be sure to measure it.',
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  _meterableField(
                    connected: connected,
                    label: 'Measured VS (V)',
                    controller: _vCCtrl,
                    decimals: 3,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab1(vCVolt: v),
                  ),
                ],
              ),
            ),
          ),

          // PART D — Calculation / notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — Discussion',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use your measured values of R1, R2, and Vs to calculate V1 and V2 as you did in the pre-lab assignment.',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _v1CtrlCalc,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Calculated V1 (V)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context
                            .read<AppState>()
                            .updateLab1(v1VoltCalc: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _v2CtrlCalc,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Calculated V2 (V)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context
                            .read<AppState>()
                            .updateLab1(v2VoltCalc: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // PART E — Measure V1, V2
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — Measure Two Voltages',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure the voltages of V1 and V2 using the Labkit.',
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  _meterableField(
                    connected: connected,
                    label: 'Measured V1 (V)',
                    controller: _v1CtrlMeasure,
                    decimals: 3,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab1(v1VoltMeasure: v),
                  ),
                  const SizedBox(height: 8),
                  _meterableField(
                    connected: connected,
                    label: 'Measured V2 (V)',
                    controller: _v2CtrlMeasure,
                    decimals: 3,
                    applyToState: (v) =>
                        context.read<AppState>().updateLab1(v2VoltMeasure: v),
                  ),
                ],
              ),
            ),
          ),

          // PART F — Comparison notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part F — Comparison',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compare your calculated voltage values from Part D with your measured values from Part E. '
                    'Calculate a percent difference for both V1 and V2.',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesFCtrl,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: '% difference'),
                    onChanged: (text) {
                      context.read<AppState>().updateLab1(
                            notesF: text.trim().isEmpty ? null : text.trim(),
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
                onPressed: _saveProgress,
                child: const Text('Save Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}