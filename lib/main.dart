import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(const LabKitApp());

enum AppMode { none, free, lab }

enum ToolRequirement { meter, scope }

class WaveformData {
  final String label; // e.g., 'Vin' or 'Vout'
  final List<double> samples; // normalized units (e.g., volts)
  final double sampleRateHz; // e.g., 20000.0
  WaveformData({
    required this.label,
    required this.samples,
    required this.sampleRateHz,
  });
}

class Lab1Progress {
  double? rA1Ohm; // Part A: measured resistance 1 (Ω)
  double? rA2Ohm; // Part A: measured resistance 2 (Ω)
  bool circuitBuilt = false; // Part B: checkbox for built circuit
  double? vCVolt; // Part C: measured voltage (V)
  double? v1VoltCalc; // Part D: measured voltage 1 (V)
  double? v1VoltMeasure; // Part D: measured voltage 1 (V)
  double? v2VoltCalc; // Part E: measured voltage 2 (V)
  double? v2VoltMeasure; // Part E: measured voltage 2 (V)
  String? notesD; // Part D: text-only notes
  String? notesF; // Part F: text-only notes
}

class Lab2Progress {
  // A.1: five resistors
  double? r1Ohm;
  double? r2Ohm;
  double? r3Ohm;
  double? r4Ohm;
  double? rLOhm;

  // A.2: built confirmation
  bool circuitBuilt = false;

  // A.3: measured current IL (mA)
  double? iL_mA;

  //B: VL = Vxy
  double? vxyVolt;
  double? vlCalcVolt; // manually calculated VL (V)

  //C
  double? vocVolt; // open-circuit voltage (V)
  double? isc_mA; // short-circuit current (mA)

  //D, E, F
  double? ilTh_mA; // Part D: IL from Thevenin calculation (mA)
  double? ilSim_mA; // Part E: IL from simulation (mA)
  double? pd_meas_th_pct; // Part F: % diff (Measured vs Thevenin)
  double? pd_meas_sim_pct; // Part F: % diff (Measured vs Simulation)
  double? pd_th_sim_pct; // Part F: % diff (Thevenin vs Simulation)
}

class Lab3Progress {
  // Part A: three resistors
  double? r1Ohm;
  double? r2Ohm;
  double? r3Ohm;

  // Part B: built confirmation
  bool circuitBuilt = false;

  // Part C: DC measurements and comparison notes
  double? vinVoltDC; // Measured Vin (V) in DC circuit
  double? voutVoltDC; // Measured Vout (V) in DC circuit
  String? notesC; // Notes about comparison with simulation

  // Part D: DC scaling factor and notes
  double? scalingFactorDC; // Vout/Vin (manual entry)
  String? notesD;

  // Part E: AC waveform capture status
  bool acVinSaved = false;
  bool acVoutSaved = false;

  // Part F: AC amplitudes, scaling factor, and notes
  double? vinAmp; // amplitude of Vin (V)
  double? voutAmp; // amplitude of Vout (V)
  double? scalingFactorAC; // voutAmp/vinAmp (manual entry)
  String? notesF;

  // Part G: time shift between waveforms
  double? timeShiftMs; // time shift (ms) — manual entry
}

class AppState extends ChangeNotifier {
  AppMode mode = AppMode.none;
  bool deviceConnected = false;
  bool outputsEnabled = false;

  void setOutputsEnabled(bool enabled) {
    outputsEnabled = enabled;
    notifyListeners();
  }

  void setMode(AppMode m) {
    mode = m;
    notifyListeners();
  }

  void setDeviceConnected(bool connected) {
    deviceConnected = connected;
    notifyListeners();
  }

  Future<void> sendSetOutputs({
    required bool enable,
    int? dc_mV,
    int? freq_mHz,
    int? amplitude_mV,
    int? offset_mV,
  }) async {
    // Placeholder: simulate success
    setOutputsEnabled(enable);
    // TODO: build and write SetOutputs command over BLE and wait for Ack.
  }

  Future<void> sendSetPositiveSupply5V() async {
    // TODO (BLE): build SetOutputs for positive channel at 5000 mV and write to Control characteristic
    // Example payload per your spec:
    // - cmd_id = 0x30 (SetOutputs)
    // - output_mask = 0x01 (positive channel bit)
    // - mode = 0x00 (DC)
    // - dc_mV = 5000
    // - ramp_ms = 500 (optional)
    // When Ack OK, set outputsEnabled(true)
    setOutputsEnabled(true);
  }

  Future<void> sendEnableOpAmpRailsPlusMinus5() async {
    // TODO (BLE): send commands to enable +5 V and -5 V rails for the op-amp.
    // Example: SetOutputs for positive rail, then SetOutputs for negative rail (or a combined command).
    setOutputsEnabled(true);
  }

  Future<void> sendSetInputDc500mV() async {
    // TODO (BLE): set the circuit input to 0.5 V (500 mV).
    // Example: SetOutputs for input channel with dc_mV = 500 and a small ramp_ms.
    // Optionally track a field like inputSetpoint_mV if you want to display it.
  }

  Future<void> sendDisableOutputs() async {
    // TODO (BLE): send OutputOff (cmd_id 0x3F) or SetOutputs(enable=false)
    setOutputsEnabled(false);
  }

  final lab1 = Lab1Progress();

  void updateLab1({
    double? rA1Ohm,
    double? rA2Ohm,
    bool? circuitBuilt,
    double? vCVolt,
    double? v1VoltCalc,
    double? v1VoltMeasure,
    double? v2VoltCalc,
    double? v2VoltMeasure,
    String? notesD,
    String? notesF,
  }) {
    if (rA1Ohm != null) lab1.rA1Ohm = rA1Ohm;
    if (rA2Ohm != null) lab1.rA2Ohm = rA2Ohm;
    if (circuitBuilt != null) lab1.circuitBuilt = circuitBuilt;
    if (vCVolt != null) lab1.vCVolt = vCVolt;
    if (v1VoltCalc != null) lab1.v1VoltCalc = v1VoltCalc;
    if (v1VoltMeasure != null) lab1.v1VoltMeasure = v1VoltMeasure;
    if (v2VoltCalc != null) lab1.v2VoltCalc = v2VoltCalc;
    if (v2VoltMeasure != null) lab1.v2VoltMeasure = v2VoltMeasure;
    if (notesD != null) lab1.notesD = notesD;
    if (notesF != null) lab1.notesF = notesF;
    notifyListeners();
  }

  final lab2 = Lab2Progress();

  void updateLab2({
    double? r1Ohm,
    double? r2Ohm,
    double? r3Ohm,
    double? r4Ohm,
    double? rLOhm,
    bool? circuitBuilt,
    double? iL_mA,
    double? vxyVolt,
    double? vlCalcVolt,
    double? vocVolt,
    double? isc_mA,
    double? ilTh_mA,
    double? ilSim_mA,
    double? pd_meas_th_pct,
    double? pd_meas_sim_pct,
    double? pd_th_sim_pct,
  }) {
    if (r1Ohm != null) lab2.r1Ohm = r1Ohm;
    if (r2Ohm != null) lab2.r2Ohm = r2Ohm;
    if (r3Ohm != null) lab2.r3Ohm = r3Ohm;
    if (r4Ohm != null) lab2.r4Ohm = r4Ohm;
    if (rLOhm != null) lab2.rLOhm = rLOhm;
    if (circuitBuilt != null) lab2.circuitBuilt = circuitBuilt;
    if (iL_mA != null) lab2.iL_mA = iL_mA;
    if (vxyVolt != null) lab2.vxyVolt = vxyVolt;
    if (vlCalcVolt != null) lab2.vlCalcVolt = vlCalcVolt;
    if (vocVolt != null) lab2.vocVolt = vocVolt;
    if (isc_mA != null) lab2.isc_mA = isc_mA;
    if (ilTh_mA != null) lab2.ilTh_mA = ilTh_mA;
    if (ilSim_mA != null) lab2.ilSim_mA = ilSim_mA;
    if (pd_meas_th_pct != null) lab2.pd_meas_th_pct = pd_meas_th_pct;
    if (pd_meas_sim_pct != null) lab2.pd_meas_sim_pct = pd_meas_sim_pct;
    if (pd_th_sim_pct != null) lab2.pd_th_sim_pct = pd_th_sim_pct;
    notifyListeners();
  }

  final lab3 = Lab3Progress();

  void updateLab3({
    double? r1Ohm,
    double? r2Ohm,
    double? r3Ohm,
    bool? circuitBuilt,
    double? vinVoltDC,
    double? voutVoltDC,
    String? notesC,
    double? scalingFactorDC,
    String? notesD,
    bool? acVinSaved,
    bool? acVoutSaved,
    double? vinAmp,
    double? voutAmp,
    double? scalingFactorAC,
    String? notesF,
    double? timeShiftMs,
  }) {
    if (r1Ohm != null) lab3.r1Ohm = r1Ohm;
    if (r2Ohm != null) lab3.r2Ohm = r2Ohm;
    if (r3Ohm != null) lab3.r3Ohm = r3Ohm;
    if (circuitBuilt != null) lab3.circuitBuilt = circuitBuilt;
    if (vinVoltDC != null) lab3.vinVoltDC = vinVoltDC;
    if (voutVoltDC != null) lab3.voutVoltDC = voutVoltDC;
    if (notesC != null) lab3.notesC = notesC;
    if (scalingFactorDC != null) lab3.scalingFactorDC = scalingFactorDC;
    if (notesD != null) lab3.notesD = notesD;
    if (acVinSaved != null) lab3.acVinSaved = acVinSaved;
    if (acVoutSaved != null) lab3.acVoutSaved = acVoutSaved;
    if (vinAmp != null) lab3.vinAmp = vinAmp;
    if (voutAmp != null) lab3.voutAmp = voutAmp;
    if (scalingFactorAC != null) lab3.scalingFactorAC = scalingFactorAC;
    if (notesF != null) lab3.notesF = notesF;
    if (timeShiftMs != null) lab3.timeShiftMs = timeShiftMs;
    notifyListeners();
  }

  // Lab 3 waveforms
  WaveformData? lab3VinWaveform;
  WaveformData? lab3VoutWaveform;

  //(call these from lab 3 Part E after capture)
  void setLab3VinWaveform(WaveformData w) {
    lab3VinWaveform = w;
    notifyListeners();
  }

  void setLab3VoutWaveform(WaveformData w) {
    lab3VoutWaveform = w;
    notifyListeners();
  }
}

class LabKitApp extends StatelessWidget {
  const LabKitApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'LabKit',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const Root(),
      ),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});
  @override
  Widget build(BuildContext context) {
    // App always starts in Lab Mode now
    return const LabModeRoot();
  }
}

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('LabKit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Choose a mode',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Lab Mode'),
              subtitle: Text(
                state.deviceConnected
                    ? 'Device connected. Start labs.'
                    : 'Connect to the LabKit before starting labs.',
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  final state = context.read<AppState>();
                  if (!state.deviceConnected) {
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Device not connected'),
                        content: const Text(
                          'You can open Lab Mode now, but some steps require connecting to the LabKit device.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Continue'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              state.setMode(
                                AppMode.free,
                              ); // optional quick path to connect
                            },
                            child: const Text('Go to Connect'),
                          ),
                        ],
                      ),
                    );
                  }
                  state.setMode(AppMode.lab);
                },
                child: const Text('Start'),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Free Mode'),
              subtitle: const Text('Explore tools with tabs (no manual flow).'),
              trailing: ElevatedButton(
                onPressed: () => state.setMode(AppMode.free),
                child: const Text('Start'),
              ),
            ),
            const Spacer(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      state.deviceConnected ? Icons.check_circle : Icons.cancel,
                      color: state.deviceConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.deviceConnected
                            ? 'Connected to device'
                            : 'Not connected',
                      ),
                    ),
                    // Placeholder connect button for testing. Replace with your BLE connect flow.
                    ElevatedButton(
                      onPressed: () {
                        state.setDeviceConnected(!state.deviceConnected);
                      },
                      child: Text(
                        state.deviceConnected ? 'Disconnect' : 'Connect',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeterScreen extends StatelessWidget {
  const MeterScreen({super.key});

  Widget _metricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _metricCard('DC', '1.23 V'),
        _metricCard('RMS', '0.87 V'),
        _metricCard('Frequency', '1000 Hz'),
        _metricCard('Peak-to-Peak', '2.00 V'),
      ],
    );
  }
}

class ScopeScreen extends StatelessWidget {
  const ScopeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Capture requested (placeholder)'),
                    ),
                  );
                },
                child: const Text('Capture'),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sample rate: 20 kS/s Points: 2048')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('Chart goes here'),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SwitchListTile(
          title: const Text('Mock data mode'),
          value: true,
          onChanged: (_) {},
        ),
        ListTile(
          leading: Icon(
            state.deviceConnected ? Icons.check_circle : Icons.cancel,
            color: state.deviceConnected ? Colors.green : Colors.red,
          ),
          title: Text(
            state.deviceConnected ? 'Connected to device' : 'Not connected',
          ),
          subtitle: const Text('Real BLE connect goes in the Connect tab.'),
          trailing: ElevatedButton(
            onPressed: () => context.read<AppState>().setDeviceConnected(
              !state.deviceConnected,
            ),
            child: Text(state.deviceConnected ? 'Disconnect' : 'Connect'),
          ),
        ),
      ],
    );
  }
}

/* ==========================
Lab Mode (9 labs, gated)
========================== */

class LabModeRoot extends StatelessWidget {
  const LabModeRoot({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('LabKit — Lab Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<AppState>().setMode(AppMode.none),
        ),
      ),
      body: state.deviceConnected
          ? const LabListScreen()
          : const LabConnectionGate(),
    );
  }
}

class LabConnectionGate extends StatelessWidget {
  const LabConnectionGate({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Connect to the LabKit device to begin the labs.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Placeholder: in real app, navigate to a connect flow or start BLE connect.
                context.read<AppState>().setDeviceConnected(true);
              },
              child: const Text('Connect Device (placeholder)'),
            ),
          ],
        ),
      ),
    );
  }
}

class LabListScreen extends StatelessWidget {
  const LabListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final labs = [
      'Lab 1: Ohm’s Law and Kirchoff’s Laws',
      'Lab 2: Node Voltages and Equivalent Circuits',
      'Lab 3: Intro to Op Amps',
      'Lab 4: First Order RC and RL Transients',
      'Lab 5: Intro to AC Signals',
      'Lab 6: Frequency Response',
      'Lab 7: Op Amp Integrator and Active Filter',
      'Lab 8: Intro to Logic Gates',
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: labs.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (ctx, i) {
        return ListTile(
          leading: const Icon(Icons.menu_book),
          title: Text(labs[i]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => labScreenFor(i + 1)),
          ),
        );
      },
    );
  }

  Widget labScreenFor(int index) {
    switch (index) {
      case 1:
        return const Lab1Screen();
      case 2:
        return const Lab2Screen();
      case 3:
        return const Lab3Screen();
      case 4:
        return const Lab4Screen();
      case 5:
        return const Lab5Screen();
      case 6:
        return const Lab6Screen();
      case 7:
        return const Lab7Screen();
      case 8:
        return const Lab8Screen();
      default:
        return const Lab1Screen();
    }
  }
}

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
                                // TODO (BLE/UI): navigate to Meter or start measurement
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Opening Meter (placeholder)',
                                    ),
                                  ),
                                );
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
                                // TODO (BLE/UI): navigate to Meter or start measurement
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Opening Meter (placeholder)',
                                    ),
                                  ),
                                );
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
                      labelText: 'Measured V1 (V)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _v2CtrlCalc,
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
                                // TODO (BLE/UI): navigate to Meter or start measurement
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Opening Meter (placeholder)',
                                    ),
                                  ),
                                );
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the multimeter.'),
                              ),
                            );
                            return;
                          }
                          // TODO: navigate to Meter or start a resistance read flow
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Meter (placeholder)'),
                            ),
                          );
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the multimeter.'),
                              ),
                            );
                            return;
                          }
                          // TODO: navigate to Meter or start a current measurement flow
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Meter (placeholder)'),
                            ),
                          );
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
                          final connected = context
                              .read<AppState>()
                              .deviceConnected;
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the multimeter.'),
                              ),
                            );
                            return;
                          }
                          // TODO: navigate to Meter or trigger a measurement flow
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Meter (placeholder)'),
                            ),
                          );
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
                          final connected = context
                              .read<AppState>()
                              .deviceConnected;
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the multimeter.'),
                              ),
                            );
                            return;
                          }
                          // TODO: navigate to Meter or trigger a measurement flow
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Meter (placeholder)'),
                            ),
                          );
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

class Lab3Screen extends StatefulWidget {
  const Lab3Screen({super.key});
  @override
  State<Lab3Screen> createState() => _Lab3ScreenState();
}

class Lab3WaveformViewer extends StatelessWidget {
  final WaveformData? data; // pass Vin or Vout waveform data
  const Lab3WaveformViewer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data?.label ?? 'Waveform')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data == null
            ? const Center(child: Text('No saved waveform to display.'))
            : LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: List<FlSpot>.generate(
                        data!.samples.length,
                        (i) => FlSpot(i / data!.sampleRateHz, data!.samples[i]),
                      ),
                      isCurved: false,
                      dotData: FlDotData(show: false),
                      color: Colors.blue,
                      barWidth: 2,
                    ),
                  ],
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                ),
              ),
      ),
    );
  }
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the multimeter.'),
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Meter (placeholder)'),
                            ),
                          );
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
                  // Replace with your real asset when ready:
                  // InteractiveViewer(child: Image.asset('assets/images/labs/lab2_circuit.png', fit: BoxFit.contain)),
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the multimeter.'),
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Meter (placeholder)'),
                            ),
                          );
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
                      if (v != null)
                        context.read<AppState>().updateLab3(vinVoltDC: v);
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
                      if (v != null)
                        context.read<AppState>().updateLab3(voutVoltDC: v);
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
                      if (v != null)
                        context.read<AppState>().updateLab3(scalingFactorDC: v);
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
                                    Lab3WaveformViewer(data: w),
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
                                    Lab3WaveformViewer(data: w),
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
                      if (v != null)
                        context.read<AppState>().updateLab3(vinAmp: v);
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
                      if (v != null)
                        context.read<AppState>().updateLab3(voutAmp: v);
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
                      if (v != null)
                        context.read<AppState>().updateLab3(scalingFactorAC: v);
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
                                builder: (_) => Lab3WaveformViewer(data: w),
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
                                builder: (_) => Lab3WaveformViewer(data: w),
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

class Lab4Screen extends StatelessWidget {
  const Lab4Screen({super.key});
  @override
  Widget build(BuildContext c) => _labStub(c, 'Lab 4: RLC Resonance');
}

class Lab5Screen extends StatelessWidget {
  const Lab5Screen({super.key});
  @override
  Widget build(BuildContext c) => _labStub(c, 'Lab 5: Diodes');
}

class Lab6Screen extends StatelessWidget {
  const Lab6Screen({super.key});
  @override
  Widget build(BuildContext c) => _labStub(c, 'Lab 6: Transistors');
}

class Lab7Screen extends StatelessWidget {
  const Lab7Screen({super.key});
  @override
  Widget build(BuildContext c) => _labStub(c, 'Lab 7: Op-Amps');
}

class Lab8Screen extends StatelessWidget {
  const Lab8Screen({super.key});
  @override
  Widget build(BuildContext c) => _labStub(c, 'Lab 8: Filters');
}

Widget _labStub(BuildContext context, String title) {
  final state = context.watch<AppState>();
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (!state.deviceConnected) const ConnectionWarning(),
        const OutputControlPanel(),
        Card(
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Replace with detailed lab content, images, and tool actions.',
            ),
          ),
        ),
      ],
    ),
  );
}

class LabStep {
  final String title;
  final String text;
  final ToolRequirement? tool;
  LabStep({required this.title, required this.text, this.tool});
}

class ConnectionWarning extends StatelessWidget {
  const ConnectionWarning({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3F3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Not connected. Connect to the LabKit to use meter and scope tools.',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Wire to your BLE connect flow
              context.read<AppState>().setDeviceConnected(true);
            },
            child: const Text('Connect now'),
          ),
        ],
      ),
    );
  }
}

class OutputControlPanel extends StatelessWidget {
  const OutputControlPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Outputs',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  state.outputsEnabled ? Icons.power : Icons.power_off,
                  color: state.outputsEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.outputsEnabled
                        ? 'Outputs enabled'
                        : 'Outputs disabled',
                  ),
                ),
                ElevatedButton(
                  onPressed: state.deviceConnected
                      ? () => context.read<AppState>().sendSetOutputs(
                          enable: !state.outputsEnabled,
                        )
                      : null,
                  child: Text(state.outputsEnabled ? 'Disable' : 'Enable'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('DC setpoint (mV):'),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: state.deviceConnected
                      ? () => context.read<AppState>().sendSetOutputs(
                          enable: true,
                          dc_mV: 2500,
                        )
                      : null,
                  child: const Text('Set 2500 mV'),
                ),
              ],
            ),
            if (!state.deviceConnected)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Connect to change outputs.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
