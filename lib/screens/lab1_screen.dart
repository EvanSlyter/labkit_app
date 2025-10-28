import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';
import '../widgets/meter_screen.dart';

class Lab1Screen extends StatefulWidget {
  const Lab1Screen({super.key});
  @override
  State<Lab1Screen> createState() => _Lab1ScreenState();
}

class _Lab1ScreenState extends State<Lab1Screen> {
  // ADD: controllers for inputs
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
    // EXISTS: Provider is set up; we can read AppState here
    final state = context.read<AppState>();
    // ADD: prefill from saved progress
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
    // ADD: dispose controllers
    _rA1Ctrl.dispose();
    _rA2Ctrl.dispose();
    _vCCtrl.dispose();
    _v1CtrlCalc.dispose();
    _v1CtrlMeasure.dispose();
    _v2CtrlCalc.dispose();
    _v2CtrlMeasure.dispose();
    _notesDCtrl.dispose();
    _notesFCtrl.dispose();
    super.dispose();
  }

  // ADD: helpers
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lab 1 progress saved')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>(); // EXISTS: Provider watch
    final connected = state.deviceConnected; // EXISTS: app connection flag

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
          // EXISTS: optional warning banner if not connected
          if (!connected) const ConnectionWarning(),

          // PART A — Measure resistance with multimeter; record two values
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
                    'In your component kit, find the two resistors you will need to contruct figure 1.1d (as shown below). Use the Multimeter to measure both resistor values. They are nominally 100 and 220 ohms but may vary.',
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
                        onPressed: connected
                            ? () {
                                Navigator.pushNamed(context, '/meter');
                              }
                            : null,
                        child: const Text('Open Meter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rA1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured R1 (Ω)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rA2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured R2 (Ω)',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PART B — Build circuit based on diagram
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
                    'Build the circuit based on the provided diagram.',
                  ),
                  const SizedBox(height: 12),
                  // UPDATED earlier to Image.asset in your setup:
                  // InteractiveViewer(child: Image.asset('assets/images/labs/lab1_circuit.png', fit: BoxFit.contain)),
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
                        onChanged: (v) => context.read<AppState>().updateLab1(
                          circuitBuilt: v ?? false,
                        ),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                  // ADD: supply control buttons
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
                  if (!context.watch<AppState>().deviceConnected)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Connect to the device to change outputs.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // PART C — Measure a voltage at part of the circuit
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
                    'Measure Vs using the Multimeter. Note that Vs is the nominal 5V power supply on the circuit board, but it, like the resistors, has a tolerance.\n\n'
                    'From now on, whenever you are using a voltage source, be sure to measure it, as you cannot assume its value is exactly equal to its nominal value.',
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
                        onPressed: connected
                            ? () {
                                Navigator.pushNamed(context, '/meter');
                              }
                            : null,
                        child: const Text('Open Meter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vCCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured VS (V)',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PART D — Text only (no devices)
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Calculated V1 (V)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _v2CtrlCalc,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Calculated V2 (V)',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PART E — Measure two voltages and record them
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
                      ElevatedButton(
                        onPressed: connected
                            ? () {
                                Navigator.pushNamed(context, '/meter');
                              }
                            : null,
                        child: const Text('Open Meter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _v1CtrlMeasure,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured V1 (V)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _v2CtrlMeasure,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured V2 (V)',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PART F — Text only (no devices)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part F — Coomparison',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compare your calculated voltage values from part D with your measured values from part E. Calculate a percent difference for both V1 and V2',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesFCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '% difference',
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