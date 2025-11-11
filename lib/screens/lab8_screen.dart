import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';

class Lab8Screen extends StatefulWidget {
  const Lab8Screen({super.key});
  @override
  State<Lab8Screen> createState() => _Lab8ScreenState();
}

class _Lab8ScreenState extends State<Lab8Screen> {
  // AND table (4 rows)
  final List<TextEditingController> _andVoutCtrls =
      List<TextEditingController>.generate(4, (i) => TextEditingController());

  final List<TextEditingController> _orVoutCtrls =
      List<TextEditingController>.generate(4, (i) => TextEditingController());

  final List<TextEditingController> _complexVoutCtrls =
      List<TextEditingController>.generate(8, (i) => TextEditingController());

  final TextEditingController _notesCtrl = TextEditingController();

  // Labels for rows
  final List<String> _andLabels = const [
    'A = 0 V, B = 0 V',
    'A = 0 V, B = 5 V',
    'A = 5 V, B = 0 V',
    'A = 5 V, B = 5 V',
  ];

  final List<String> _orLabels = const [
    'A = 0 V, B = 0 V',
    'A = 0 V, B = 5 V',
    'A = 5 V, B = 0 V',
    'A = 5 V, B = 5 V',
  ];

  final List<String> _complexLabels = const [
    'A = 0 V, B = 0 V, C = 0 V',
    'A = 0 V, B = 0 V, C = 5 V',
    'A = 0 V, B = 5 V, C = 0 V',
    'A = 0 V, B = 5 V, C = 5 V',
    'A = 5 V, B = 0 V, C = 0 V',
    'A = 5 V, B = 0 V, C = 5 V',
    'A = 5 V, B = 5 V, C = 0 V',
    'A = 5 V, B = 5 V, C = 5 V',
  ];

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab8;
    for (int i = 0; i < 4; i++) {
      _andVoutCtrls[i].text = s.andVout[i]?.toString() ?? '';
      _orVoutCtrls[i].text = s.orVout[i]?.toString() ?? '';
    }
    for (int i = 0; i < 8; i++) {
      _complexVoutCtrls[i].text = s.complexVout[i]?.toString() ?? '';
    }
    _notesCtrl.text = s.notesCompare ?? '';
  }

  @override
  void dispose() {
    for (final c in _andVoutCtrls) {
      c.dispose();
    }
    for (final c in _orVoutCtrls) {
      c.dispose();
    }
    for (final c in _complexVoutCtrls) {
      c.dispose();
    }
    _notesCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 8: Logic Gates and Truth Tables'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — AND 7408
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — AND Gate (7408): Pin Diagram and Truth Table',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use 5 V as logic 1 and 0 V as logic 0. Test inputs A/B and record the measured Vout for each combination.',
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
                        'assets/images/labs/lab8_circuit1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab8.builtAND,
                        onChanged: (v) => context
                            .read<AppState>()
                            .setLab8BuiltAND(v ?? false),
                      ),
                      const Text(
                        'I have wired the 7408 AND gate per the diagram',
                      ),
                    ],
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
                  for (int i = 0; i < _andLabels.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _truthRow(
                        label: _andLabels[i],
                        controller: _andVoutCtrls[i],
                        onChanged: (text) {
                          final v = _parseDouble(text);
                          if (v != null) {
                            context.read<AppState>().updateLab8AndRow(
                              i,
                              voutV: v,
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Part B — OR 7432
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — OR Gate (7432): Pin Diagram and Truth Table',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use 5 V as logic 1 and 0 V as logic 0. Test inputs A/B and record the measured Vout for each combination.',
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
                        'assets/images/labs/lab8_circuit2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab8.builtOR,
                        onChanged: (v) =>
                            context.read<AppState>().setLab8BuiltOR(v ?? false),
                      ),
                      const Text(
                        'I have wired the 7432 OR gate per the diagram',
                      ),
                    ],
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
                  for (int i = 0; i < _orLabels.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _truthRow(
                        label: _orLabels[i],
                        controller: _orVoutCtrls[i],
                        onChanged: (text) {
                          final v = _parseDouble(text);
                          if (v != null) {
                            context.read<AppState>().updateLab8OrRow(
                              i,
                              voutV: v,
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Part C — Complex circuit lab8_circuit3
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Build Complex Circuit (AND/OR chips)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit shown (lab8_circuit3). Use as many 7408/7432 chips as needed.',
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
                        'assets/images/labs/lab8_circuit3.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab8.builtComplex,
                        onChanged: (v) => context
                            .read<AppState>()
                            .setLab8BuiltComplex(v ?? false),
                      ),
                      const Text('I have built the complex circuit'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Part D — 3-input truth table and comparison notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — 3-Input Truth Table and Comparison',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use 5 V as logic 1 and 0 V as logic 0. For each (A,B,C) combination below, record measured Vout (V). '
                    'Then compare with prelab and simulations.',
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < _complexLabels.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _truthRow(
                        label: _complexLabels[i],
                        controller: _complexVoutCtrls[i],
                        onChanged: (text) {
                          final v = _parseDouble(text);
                          if (v != null) {
                            context.read<AppState>().updateLab8ComplexRow(
                              i,
                              voutV: v,
                            );
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes: Compare with prelab and simulations',
                    ),
                    onChanged: (t) {
                      context.read<AppState>().updateLab8Notes(
                        t.trim().isEmpty ? null : t.trim(),
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
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lab 8 progress saved (values persist in memory)',
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

  // Simple row widget for "Label — Vout (V)"
  Widget _truthRow({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Vout (V)'),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
