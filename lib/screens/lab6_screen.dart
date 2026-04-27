import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/connection_warning.dart';

class Lab6Screen extends StatefulWidget {
  const Lab6Screen({super.key});

  @override
  State<Lab6Screen> createState() => _Lab6ScreenState();
}

class _Lab6ScreenState extends State<Lab6Screen> {
  // Controllers for Part E and F
  final _fMinus3dBCtrl = TextEditingController();
  final _rCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  final _notesHL = TextEditingController();
  bool? _isHighPass;

  // Row controllers for Vin/Vout (one per frequency)
  late final List<TextEditingController> _vinCtrls;
  late final List<TextEditingController> _voutCtrls;

  @override
  void initState() {
    super.initState();
    final rows = context.read<AppState>().lab6Rows;
    _vinCtrls = List.generate(
      rows.length,
      (i) => TextEditingController(text: rows[i].vin_mV?.toString() ?? ''),
    );
    _voutCtrls = List.generate(
      rows.length,
      (i) => TextEditingController(text: rows[i].vout_mV?.toString() ?? ''),
    );
    final s = context.read<AppState>().lab6;
    _fMinus3dBCtrl.text = s.fMinus3dBApproxHz?.toString() ?? '';
    _rCtrl.text = s.R_Ohm?.toString() ?? '';
    _cCtrl.text = s.C_uF?.toString() ?? '';
    _notesHL.text = s.notesHighLow ?? '';
    _isHighPass = s.isHighPass;
  }

  @override
  void dispose() {
    for (final c in _vinCtrls) {
      c.dispose();
    }
    for (final c in _voutCtrls) {
      c.dispose();
    }
    _fMinus3dBCtrl.dispose();
    _rCtrl.dispose();
    _cCtrl.dispose();
    _notesHL.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  /// Meter insert helper for Vin/Vout (mV RMS).
  void _attachMeterInsert({
    required bool connected,
    required TextEditingController controller,
    required void Function(double v) applyToState,
    int decimals = 1,
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
      // valueSI is in volts from the meter; convert to mV RMS for the table
      final mV = valueSI * 1000.0;
      controller.text = mV.toStringAsFixed(decimals);
      applyToState(mV);
    });

    app.showMeterOverlay(context);
  }

  Widget _meterableVinVoutField({
    required bool connected,
    required String label,
    required TextEditingController controller,
    required void Function(double v) applyToState,
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;
    final rows = app.lab6Rows;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 6: Frequency Response and Bode Plot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Build circuit and apply input waveform
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — Build Circuit and Apply Input (f = 1 Hz)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit per the diagram. Then apply the input waveform:\n'
                    'f = 1 Hz, phase = 0°, offset = 0 V, amplitude = 2 V.',
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
                        'assets/images/labs/lab6_circuit1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab6.circuitBuilt_6,
                        onChanged: (v) => context
                            .read<AppState>()
                            .updateLab6Build(built: v ?? false),
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
                        child: Text(
                          'Enable signal generator (f = 1 Hz, 2 V amplitude, 0° phase, 0 V offset)',
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
                              content:
                                  Text('Connect to the device to change inputs.'),
                            ),
                          );
                          return;
                        }
                        if (!app.lab6.circuitBuilt_6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Check the box after building first.'),
                            ),
                          );
                          return;
                        }
                        context.read<AppState>().sendEnableSignalGeneratorSine(
                              freqHz: 1,
                              amplitude_mVpp: 2000, // adjust if needed
                              offset_mV: 0,
                              phase_mdeg: 0,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Signal generator enabled (1 Hz, 2 V amplitude, 0°, 0 V offset)',
                            ),
                          ),
                        );
                      },
                      child: const Text('Enable input'),
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

          // Part B — Table row for 1 Hz (Vin RMS, Vout RMS, ratio)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Measure RMS at 1 Hz',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure and record Vin (mV RMS) and Vout (mV RMS). The ratio Vout/Vin will be shown.',
                  ),
                  const SizedBox(height: 12),
                  _lab6TableRow(
                    context: context,
                    index: 0,
                    row: rows[0],
                    vinCtrl: _vinCtrls[0],
                    voutCtrl: _voutCtrls[0],
                    showSetGenerator: true,
                  ),
                ],
              ),
            ),
          ),

          // Part C — Fill the rest of the table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Fill the Table for All Frequencies',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Repeat the measurements for each frequency below and record Vin (mV RMS), Vout (mV RMS).',
                  ),
                  const SizedBox(height: 12),
                  for (int i = 1; i < rows.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _lab6TableRow(
                        context: context,
                        index: i,
                        row: rows[i],
                        vinCtrl: _vinCtrls[i],
                        voutCtrl: _voutCtrls[i],
                        showSetGenerator: true,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Part D — Bode plot description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Part D — Bode Plot',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Using the data from your table, create a Bode Plot of the magnitude response.\n'
                    'The horizontal axis is log(frequency); the vertical axis is decibels.\n'
                    'Use dB = 20 log10(Vout/Vin).',
                  ),
                ],
              ),
            ),
          ),

          // Part E — –3 dB frequency and theoretical f0
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — –3 dB Frequency and Theoretical f0',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the approximate –3 dB frequency from your Bode plot, and enter R (Ω) and C (µF) to compute the theoretical cutoff f0 = 1/(2πRC).',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fMinus3dBCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'f_–3dB (Hz)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab6Bode(
                              fMinus3dBApproxHz: v,
                            );
                      }
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'R (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab6Bode(R_Ohm: v);
                      }
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'C (µF)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) {
                        context.read<AppState>().updateLab6Bode(C_uF: v);
                      }
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (_) {
                      final s = context.watch<AppState>().lab6;
                      final fPlot = s.fMinus3dBApproxHz;
                      final f0 = s.f0TheoryHz;
                      final comp = (fPlot != null && f0 != null)
                          ? 'Δ = ${(fPlot - f0).toStringAsFixed(2)} Hz '
                              '(relative: ${((fPlot - f0) / f0 * 100).toStringAsFixed(1)} %)'
                          : 'Enter R and C to see f0 and comparison.';
                      return Text(
                        'Theoretical f0 = ${f0 != null ? f0.toStringAsFixed(2) : '—'} Hz\n$comp',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part F — High-pass or low-pass?
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part F — High-pass or Low-pass?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select whether the circuit is high-pass or low-pass, and explain how you know (based on your data and plot).',
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('High-pass'),
                    value: _isHighPass == true,
                    onChanged: (checked) {
                      setState(() {
                        _isHighPass = (checked ?? false) ? true : null;
                      });
                      context
                          .read<AppState>()
                          .updateLab6HighLow(isHighPass: _isHighPass);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Low-pass'),
                    value: _isHighPass == false && _isHighPass != null,
                    onChanged: (checked) {
                      setState(() {
                        _isHighPass = (checked ?? false) ? false : null;
                      });
                      context
                          .read<AppState>()
                          .updateLab6HighLow(isHighPass: _isHighPass);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesHL,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Explanation'),
                    onChanged: (t) {
                      context.read<AppState>().updateLab6HighLow(
                          notes: t.trim().isEmpty ? null : t.trim());
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
                onPressed: () {
                  // Data already kept in AppState as user types.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lab 6 progress saved (in memory)'),
                    ),
                  );
                },
                child: const Text('Save Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Table row: frequency, stacked Vin/Vout fields with meter icons, ratio, generator button
  Widget _lab6TableRow({
    required BuildContext context,
    required int index,
    required Lab6Row row,
    required TextEditingController vinCtrl,
    required TextEditingController voutCtrl,
    bool showSetGenerator = false,
  }) {
    final app = context.read<AppState>();
    final connected = app.deviceConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with frequency and optional "Set generator"
        Row(
          children: [
            Text(
              'f = ${row.fHz} Hz',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (showSetGenerator)
              OutlinedButton(
                onPressed: () {
                  if (!connected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connect to set generator.'),
                      ),
                    );
                    return;
                  }
                  app.sendEnableSignalGeneratorSine(
                    freqHz: row.fHz,
                    amplitude_mVpp: 2000, // same as Part A
                    offset_mV: 0,
                    phase_mdeg: 0,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Generator set to ${row.fHz} Hz'),
                    ),
                  );
                },
                child: const Text('Set generator'),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Vin (stacked) with meter icon
        _meterableVinVoutField(
          connected: connected,
          label: 'Vin (mV RMS)',
          controller: vinCtrl,
          applyToState: (v) {
            app.updateLab6Row(index: index, vin_mV: v);
            setState(() {});
          },
        ),
        const SizedBox(height: 6),

        // Vout (stacked) with meter icon
        _meterableVinVoutField(
          connected: connected,
          label: 'Vout (mV RMS)',
          controller: voutCtrl,
          applyToState: (v) {
            app.updateLab6Row(index: index, vout_mV: v);
            setState(() {});
          },
        ),
        const SizedBox(height: 6),

        // Ratio display
        Text(
          'Vout/Vin: ${row.ratio != null ? row.ratio!.toStringAsFixed(3) : '—'}',
          textAlign: TextAlign.left,
        ),
      ],
    );
  }
}