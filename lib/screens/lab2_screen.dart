import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';

class Lab2Screen extends StatefulWidget {
  const Lab2Screen({super.key});
  @override
  State<Lab2Screen> createState() => _Lab2ScreenState();
}

class _Lab2ScreenState extends State<Lab2Screen> {
  // Controllers for A.1 and A.3 inputs
  final _r1Ctrl = TextEditingController();
  final _r2Ctrl = TextEditingController();
  final _r3Ctrl = TextEditingController();
  final _r4Ctrl = TextEditingController();
  final _rLCtrl = TextEditingController();
  final _iLCtrl = TextEditingController(); // mA
  final _vxyCtrl = TextEditingController();
  final _vlCalcCtrl = TextEditingController();
  final _vocCtrl = TextEditingController(); // V_OC (V)
  final _iscCtrl = TextEditingController(); // I_SC (mA)
  final _ilThCtrl = TextEditingController(); // Part D: IL_Thevenin (mA)
  final _ilSimCtrl = TextEditingController(); // Part E: IL_Simulation (mA)
  final _pdMeasThCtrl =
      TextEditingController(); // Part F: % diff Measured vs Thevenin
  final _pdMeasSimCtrl =
      TextEditingController(); // Part F: % diff Measured vs Simulation
  final _pdThSimCtrl =
      TextEditingController(); // Part F: % diff Thevenin vs Simulation
  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab2;
    _r1Ctrl.text = s.r1Ohm?.toString() ?? '';
    _r2Ctrl.text = s.r2Ohm?.toString() ?? '';
    _r3Ctrl.text = s.r3Ohm?.toString() ?? '';
    _r4Ctrl.text = s.r4Ohm?.toString() ?? '';
    _rLCtrl.text = s.rLOhm?.toString() ?? '';
    _iLCtrl.text = s.iL_mA?.toString() ?? '';
    _vxyCtrl.text = s.vxyVolt?.toString() ?? '';
    _vlCalcCtrl.text = s.vlCalcVolt?.toString() ?? '';
    _vocCtrl.text = s.vocVolt?.toString() ?? '';
    _iscCtrl.text = s.isc_mA?.toString() ?? '';
    _ilThCtrl.text = s.ilTh_mA?.toString() ?? '';
    _ilSimCtrl.text = s.ilSim_mA?.toString() ?? '';
    _pdMeasThCtrl.text = s.pd_meas_th_pct?.toString() ?? '';
    _pdMeasSimCtrl.text = s.pd_meas_sim_pct?.toString() ?? '';
    _pdThSimCtrl.text = s.pd_th_sim_pct?.toString() ?? '';
  }

  @override
  void dispose() {
    _r1Ctrl.dispose();
    _r2Ctrl.dispose();
    _r3Ctrl.dispose();
    _r4Ctrl.dispose();
    _rLCtrl.dispose();
    _iLCtrl.dispose();
    _vxyCtrl.dispose();
    _vlCalcCtrl.dispose();
    _vocCtrl.dispose();
    _iscCtrl.dispose();
    _ilThCtrl.dispose();
    _ilSimCtrl.dispose();
    _pdMeasThCtrl.dispose();
    _pdMeasSimCtrl.dispose();
    _pdThSimCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _save() {
    context.read<AppState>().updateLab2(
      r1Ohm: _parseDouble(_r1Ctrl.text),
      r2Ohm: _parseDouble(_r2Ctrl.text),
      r3Ohm: _parseDouble(_r3Ctrl.text),
      r4Ohm: _parseDouble(_r4Ctrl.text),
      rLOhm: _parseDouble(_rLCtrl.text),
      iL_mA: _parseDouble(_iLCtrl.text),
      vxyVolt: _parseDouble(_vxyCtrl.text),
      vlCalcVolt: _parseDouble(_vlCalcCtrl.text),
      vocVolt: _parseDouble(_vocCtrl.text),
      isc_mA: _parseDouble(_iscCtrl.text),
      ilTh_mA: _parseDouble(_ilThCtrl.text),
      ilSim_mA: _parseDouble(_ilSimCtrl.text),
      pd_meas_th_pct: _parseDouble(_pdMeasThCtrl.text),
      pd_meas_sim_pct: _parseDouble(_pdMeasSimCtrl.text),
      pd_th_sim_pct: _parseDouble(_pdThSimCtrl.text),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lab 2 progress saved')));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 2: Node voltages and Equivalent circuits'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // A.1 — Measure R1–R4 and RL
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A.1 — Measure Resistors',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Locate all required resistors and measure their resistances using the LabKit.',
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _r4Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R4 (Ω)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rLCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'RL (Ω)'),
                  ),
                ],
              ),
            ),
          ),

          // A.2 — Build per diagram and power to +5 V
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A.2 — Build the Circuit and Apply +5 V',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit based on the provided diagram. '
                    'After verifying connections, enable the positive supply to +5 V.',
                  ),
                  const SizedBox(height: 12),
                  // Replace with your real asset when ready:
                  // InteractiveViewer(child: Image.asset('assets/images/labs/lab2_circuit.png', fit: BoxFit.contain)),
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.asset(
                      'assets/images/labs/lab2_circuit1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab2.circuitBuilt,
                        onChanged: (v) => context.read<AppState>().updateLab2(
                          circuitBuilt: v ?? false,
                        ),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stacked power controls (full-width)
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

                        final built = context
                            .read<AppState>()
                            .lab2
                            .circuitBuilt; // latest value
                        if (!built) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
                            ),
                          );
                          return;
                        }

                        context.read<AppState>().sendSetPositiveSupply5V();
                      },
                      child: const Text('Enable +5 V'),
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

          // A.3 — Measure load current IL
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A.3 — Measure Load Current (IL)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure the load current IL as shown on the diagram. '
                    'Record your measurement in milliamps (mA).',
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
                    controller: _iLCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured IL (mA)',
                    ),
                    onChanged: (_) {
                      final val = _parseDouble(_iLCtrl.text);
                      if (val != null) {
                        context.read<AppState>().updateLab2(iL_mA: val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // B — Measure VL and compare to calculated value
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Measure VL (Vxy) and Compare',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1) Measure VL at the load (call it Vxy) using the LabKit multimeter.\n'
                    '2) Using your measured IL and RL from Part A, manually calculate VL = IL × RL.\n'
                    '3) Enter both values below and compare.',
                  ),
                  const SizedBox(height: 12),
                  // Multimeter action row
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        color: context.watch<AppState>().deviceConnected
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.watch<AppState>().deviceConnected
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

                  // Measured Vxy input
                  TextField(
                    controller: _vxyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vxy (V)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(vxyVolt: v);
                      }
                      setState(() {}); // refresh comparison line below
                    },
                  ),
                  const SizedBox(height: 12),

                  // NEW: Manually calculated VL input
                  TextField(
                    controller: _vlCalcCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Calculated VL (V)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(vlCalcVolt: v);
                      }
                      setState(() {}); // refresh comparison line below
                    },
                  ),

                  // OPTIONAL: Show difference if both values are present
                ],
              ),
            ),
          ),

          // C — Find Thevenin equivalent (VOC and ISC)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Remove RL and Measure VOC and ISC',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Remove the load resistor RL from the circuit.\n'
                    '1) Measure the open-circuit voltage VOC at the load terminals.\n'
                    '2) Measure the short-circuit current ISC at the load terminals.\n'
                    'Record both values using the multimeter.',
                  ),
                  const SizedBox(height: 12),
                  // Multimeter action row
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        color: context.watch<AppState>().deviceConnected
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.watch<AppState>().deviceConnected
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
                  // VOC input
                  TextField(
                    controller: _vocCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured VOC (V)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(vocVolt: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  // ISC input
                  TextField(
                    controller: _iscCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured ISC (mA)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(isc_mA: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // D — Thevenin equivalent and calculate IL_Thevenin
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — Thevenin Equivalent at Nodes x–y',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create the Thevenin equivalent circuit at nodes x and y using your measured values.\n'
                    'Draw it on paper, then compute the expected load current IL (mA) and record it below.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ilThCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'IL (mA) — from Thevenin calculation',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(ilTh_mA: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // E — Simulate Thevenin circuit and measure IL_Simulation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — Simulation Result',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simulate your Thevenin circuit externally. Record the simulated load current IL (mA) below.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ilSimCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'IL (mA) — from simulation',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(ilSim_mA: v);
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
                    'Part F — Compare IL values (percent differences)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have three IL values:\n'
                    '• Measured (Part A.3)\n'
                    '• Thevenin calculation (Part D)\n'
                    '• Simulation (Part E)\n\n'
                    'Compute the percent differences manually (e.g., |A − B| / average × 100%) and record them below.',
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _pdMeasThCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Percent diff — Measured vs Thevenin (%)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(pd_meas_th_pct: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _pdMeasSimCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Percent diff — Measured vs Simulation (%)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(pd_meas_sim_pct: v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _pdThSimCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Percent diff — Thevenin vs Simulation (%)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) {
                        context.read<AppState>().updateLab2(pd_th_sim_pct: v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Saving at the bottom
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