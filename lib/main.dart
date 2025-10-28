import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

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

class Lab4Progress {
  // Part A.1
  double? rOhm_A1; // resistor value (Ω)
  double? c_uF_A1; // capacitor value (µF)
  // Part A.2
  bool circuitBuilt_41 = false;

  // Part B (1 µF)
  bool vinSaved_1uF = false;
  bool voutSaved_1uF = false;

  // Part C (10 µF)
  bool vinSaved_10uF = false;
  bool voutSaved_10uF = false;

  // Part D (100 µF)
  bool vinSaved_100uF = false;
  bool voutSaved_100uF = false;

  // Part E (tau)
  double? tauMs;

  // Part F (notes)
  String? notesCompare;
}

class Lab4_2Progress {
  // Part A: measured inductors and resistor
  double? L1_mH; // inductance of inductor 1 (mH)
  double? RL1_Ohm; // resistance of inductor 1 (Ω)
  double? L2_mH;
  double? RL2_Ohm;
  double? L3_mH;
  double? RL3_Ohm;
  double? R_Ohm; // resistor R (Ω)

  // Part B: built confirmation
  bool circuitBuilt_42 = false;

  // Part C: saved flags
  bool vinSaved_42 = false;
  bool voutSaved_42 = false;

  // Part D: tau measured from waveform cursor (ms)
  double? tauGraph_ms;

  // Part E: tau calculated via L/(R+RL) (ms), and prelab tau for comparison
  double? tauCalc_ms;
  double? tauPrelab_ms;
  String? notesCompare; // optional notes on comparison
}

class Lab5Progress {
  // Part A: potentiometer min/max resistance (Ω)
  double? rPotMinOhm;
  double? rPotMaxOhm;

  // Part B: built confirmation and notes on phase shift
  bool circuitBuilt_5 = false;
  bool vinMinSaved = false;
  bool voutMinSaved = false;
  bool vinMaxSaved = false;
  bool voutMaxSaved = false;
  String? notesPhaseShift; // compare phase shift as resistance changes

  // Part C: analysis of Vin_max/Vout_max
  double? timeShiftMsMax; // measured time shift (ms)
  double? phaseShiftDegMax; // calculated phase shift (degrees)

  // Part D: RMS measurements
  double? vrmsSource; // RMS of source (V)
  double? vrmsPot; // RMS across potentiometer (V)
  double? vrmsCap; // RMS across capacitor (V)

  // Part E: KVL check
  bool? kvlApplies; // optional yes/no
  String? notesKVL; // explanation / missing info
}

class Lab6Row {
  final int fHz;
  double? vin_mV; // measured Vin RMS (mV)
  double? vout_mV; // measured Vout RMS (mV)
  double? ratio; // Vout/Vin (unitless)
  Lab6Row({required this.fHz, this.vin_mV, this.vout_mV, this.ratio});
}

class Lab6Progress {
  bool circuitBuilt_6 = false; // Part A: checkbox after building
  // Part E: -3 dB frequency and theoretical f0
  double? fMinus3dBApproxHz; // from drawn Bode plot
  double? f0TheoryHz; // from 1/(2πRC)
  double? R_Ohm; // for f0 calc
  double? C_uF; // for f0 calc (µF; converted to F in calc)
  // Part F: high/low pass and explanation
  bool? isHighPass; // true=High-pass, false=Low-pass, null=unset
  String? notesHighLow;
}

class Lab7Progress {
  // Part A: components and build confirmation
  double? r1Ohm;
  double? r2Ohm;
  double? r3Ohm;
  double? c_uF;
  bool circuitBuilt_7 = false;

  // Part B: sine analysis (amplitudes and phase)
  bool vinSineSaved = false;
  bool voutSineSaved = false;
  double? vinAmpSine_V;
  double? voutAmpSine_V;
  double? phaseDegSine;

  // Part C: square analysis
  bool vinSquareSaved = false;
  bool voutSquareSaved = false;
  double? vinAmpSquare_V;
  double? voutAmpSquare_V;
  double? phaseDegSquare;

  // Part D: triangle analysis
  bool vinTriSaved = false;
  bool voutTriSaved = false;
  double? vinAmpTri_V;
  double? voutAmpTri_V;
  double? phaseDegTri;
}

class Lab8Progress {
  bool builtAND = false; // Part A
  bool builtOR = false; // Part B
  bool builtComplex = false; // Part C

  // Measured outputs (Volts) for truth tables
  // AND 7408: (A,B) = (0,0), (0,5), (5,0), (5,5)
  final List<double?> andVout = List<double?>.filled(4, null);

  // OR 7432: same input combos
  final List<double?> orVout = List<double?>.filled(4, null);

  // Complex 3-input: (A,B,C) eight combos as in your screenshot
  final List<double?> complexVout = List<double?>.filled(8, null);

  // Notes (comparison with prelab/simulations)
  String? notesCompare;
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

  Future<void> sendEnableSignalGeneratorSine({
    required int freqHz, // e.g., 1000
    required int amplitude_mVpp, // e.g., 1000 (1.0 Vpp)
    int offset_mV = 0,
    int phase_mdeg = 0,
  }) async {
    // TODO (BLE): Build and send SetOutputs or a dedicated command to enable the signal generator.
    // Example intent: waveform=sine, freq=freqHz, amplitude=amplitude_mVpp, offset=offset_mV, phase=phase_mdeg.
    // On Ack OK, you could set a local flag if you want to reflect generator state in the UI.
  }

  Future<void> sendEnableSignalGeneratorSquare({
    required int freqHz,
    required int amplitude_mVpp,
    int offset_mV = 0,
    int phase_mdeg = 0,
    int duty_per_mille = 500, // 50% by default
  }) async {
    // TODO: send waveform command (square)
  }

  Future<void> sendEnableSignalGeneratorTriangle({
    required int freqHz,
    required int amplitude_mVpp,
    int offset_mV = 0,
    int phase_mdeg = 0,
  }) async {
    // TODO: send waveform command (triangle)
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

  final lab4_1 = Lab4Progress();

  // Reuse WaveformData from earlier; if you don’t have it, add the same class you used for Lab 3.
  // Per‑stage saved waveforms for Lab 4.1
  WaveformData? lab4Vin_1uF;
  WaveformData? lab4Vout_1uF;
  WaveformData? lab4Vin_10uF;
  WaveformData? lab4Vout_10uF;
  WaveformData? lab4Vin_100uF;
  WaveformData? lab4Vout_100uF;

  void setLab4Vin_1uF(WaveformData w) {
    lab4Vin_1uF = w;
    lab4_1.vinSaved_1uF = true;
    notifyListeners();
  }

  void setLab4Vout_1uF(WaveformData w) {
    lab4Vout_1uF = w;
    lab4_1.voutSaved_1uF = true;
    notifyListeners();
  }

  void setLab4Vin_10uF(WaveformData w) {
    lab4Vin_10uF = w;
    lab4_1.vinSaved_10uF = true;
    notifyListeners();
  }

  void setLab4Vout_10uF(WaveformData w) {
    lab4Vout_10uF = w;
    lab4_1.voutSaved_10uF = true;
    notifyListeners();
  }

  void setLab4Vin_100uF(WaveformData w) {
    lab4Vin_100uF = w;
    lab4_1.vinSaved_100uF = true;
    notifyListeners();
  }

  void setLab4Vout_100uF(WaveformData w) {
    lab4Vout_100uF = w;
    lab4_1.voutSaved_100uF = true;
    notifyListeners();
  }

  void updateLab4({
    bool? circuitBuilt_41,
    double? tauMs,
    String? notesCompare,
    double? rOhm_A1,
    double? c_uF_A1,
  }) {
    if (circuitBuilt_41 != null) lab4_1.circuitBuilt_41 = circuitBuilt_41;
    if (tauMs != null) lab4_1.tauMs = tauMs;
    if (notesCompare != null) lab4_1.notesCompare = notesCompare;
    if (rOhm_A1 != null) lab4_1.rOhm_A1 = rOhm_A1;
    if (c_uF_A1 != null) lab4_1.c_uF_A1 = c_uF_A1;
    notifyListeners();
  }

  // Optional placeholders to wire to BLE later
  Future<void> sendCaptureVin() async {
    // TODO: trigger Vin snapshot via BLE and call setLab4Vin_* for the current stage
  }
  Future<void> sendCaptureVout() async {
    // TODO: trigger Vout snapshot via BLE and call setLab4Vout_* for the current stage
  }

  final lab4_2 = Lab4_2Progress();

  WaveformData? lab4_2VinWaveform;
  WaveformData? lab4_2VoutWaveform;

  void setLab4_2VinWaveform(WaveformData w) {
    lab4_2VinWaveform = w;
    lab4_2.vinSaved_42 = true;
    notifyListeners();
  }

  void setLab4_2VoutWaveform(WaveformData w) {
    lab4_2VoutWaveform = w;
    lab4_2.voutSaved_42 = true;
    notifyListeners();
  }

  void updateLab4_2({
    double? L1_mH,
    double? RL1_Ohm,
    double? L2_mH,
    double? RL2_Ohm,
    double? L3_mH,
    double? RL3_Ohm,
    double? R_Ohm,
    bool? circuitBuilt_42,
    bool? vinSaved_42,
    bool? voutSaved_42,
    double? tauGraph_ms,
    double? tauCalc_ms,
    double? tauPrelab_ms,
    String? notesCompare,
  }) {
    if (L1_mH != null) lab4_2.L1_mH = L1_mH;
    if (RL1_Ohm != null) lab4_2.RL1_Ohm = RL1_Ohm;
    if (L2_mH != null) lab4_2.L2_mH = L2_mH;
    if (RL2_Ohm != null) lab4_2.RL2_Ohm = RL2_Ohm;
    if (L3_mH != null) lab4_2.L3_mH = L3_mH;
    if (RL3_Ohm != null) lab4_2.RL3_Ohm = RL3_Ohm;
    if (R_Ohm != null) lab4_2.R_Ohm = R_Ohm;

    if (circuitBuilt_42 != null) lab4_2.circuitBuilt_42 = circuitBuilt_42;
    if (vinSaved_42 != null) lab4_2.vinSaved_42 = vinSaved_42;
    if (voutSaved_42 != null) lab4_2.voutSaved_42 = voutSaved_42;

    if (tauGraph_ms != null) lab4_2.tauGraph_ms = tauGraph_ms;
    if (tauCalc_ms != null) lab4_2.tauCalc_ms = tauCalc_ms;
    if (tauPrelab_ms != null) lab4_2.tauPrelab_ms = tauPrelab_ms;
    if (notesCompare != null) lab4_2.notesCompare = notesCompare;

    notifyListeners();
  }

  final lab5 = Lab5Progress();

  // Saved waveforms for Lab 5 (min/max potentiometer settings)
  WaveformData? lab5VinMinWaveform;
  WaveformData? lab5VoutMinWaveform;
  WaveformData? lab5VinMaxWaveform;
  WaveformData? lab5VoutMaxWaveform;

  void setLab5VinMinWaveform(WaveformData w) {
    lab5VinMinWaveform = w;
    lab5.vinMinSaved = true;
    notifyListeners();
  }

  void setLab5VoutMinWaveform(WaveformData w) {
    lab5VoutMinWaveform = w;
    lab5.voutMinSaved = true;
    notifyListeners();
  }

  void setLab5VinMaxWaveform(WaveformData w) {
    lab5VinMaxWaveform = w;
    lab5.vinMaxSaved = true;
    notifyListeners();
  }

  void setLab5VoutMaxWaveform(WaveformData w) {
    lab5VoutMaxWaveform = w;
    lab5.voutMaxSaved = true;
    notifyListeners();
  }

  void updateLab5({
    double? rPotMinOhm,
    double? rPotMaxOhm,
    bool? circuitBuilt_5,
    String? notesPhaseShift,
    double? timeShiftMsMax,
    double? phaseShiftDegMax,
    double? vrmsSource,
    double? vrmsPot,
    double? vrmsCap,
    bool? kvlApplies,
    String? notesKVL,
  }) {
    if (rPotMinOhm != null) lab5.rPotMinOhm = rPotMinOhm;
    if (rPotMaxOhm != null) lab5.rPotMaxOhm = rPotMaxOhm;
    if (circuitBuilt_5 != null) lab5.circuitBuilt_5 = circuitBuilt_5;
    if (notesPhaseShift != null) lab5.notesPhaseShift = notesPhaseShift;
    if (timeShiftMsMax != null) lab5.timeShiftMsMax = timeShiftMsMax;
    if (phaseShiftDegMax != null) lab5.phaseShiftDegMax = phaseShiftDegMax;
    if (vrmsSource != null) lab5.vrmsSource = vrmsSource;
    if (vrmsPot != null) lab5.vrmsPot = vrmsPot;
    if (vrmsCap != null) lab5.vrmsCap = vrmsCap;
    if (kvlApplies != null) lab5.kvlApplies = kvlApplies;
    if (notesKVL != null) lab5.notesKVL = notesKVL;
    notifyListeners();
  }

  // Lab 6
  final lab6 = Lab6Progress();

  // Table rows (frequencies matching your image)
  final List<Lab6Row> lab6Rows = [
    for (final f in [
      1,
      2,
      10,
      20,
      50,
      100,
      200,
      250,
      300,
      350,
      400,
      450,
      500,
      800,
      1000,
      1200,
    ])
      Lab6Row(fHz: f),
  ];

  void updateLab6Build({required bool built}) {
    lab6.circuitBuilt_6 = built;
    notifyListeners();
  }

  // Update a single row (by index) with new values; auto-computes ratio
  void updateLab6Row({required int index, double? vin_mV, double? vout_mV}) {
    final row = lab6Rows[index];
    if (vin_mV != null) row.vin_mV = vin_mV;
    if (vout_mV != null) row.vout_mV = vout_mV;
    if ((row.vin_mV ?? 0) > 0 && row.vout_mV != null) {
      row.ratio = row.vout_mV! / row.vin_mV!;
    }
    notifyListeners();
  }

  // Part E updates (+ compute f0 when R/C known)
  void updateLab6Bode({
    double? fMinus3dBApproxHz,
    double? R_Ohm,
    double? C_uF,
  }) {
    if (fMinus3dBApproxHz != null) lab6.fMinus3dBApproxHz = fMinus3dBApproxHz;
    if (R_Ohm != null) lab6.R_Ohm = R_Ohm;
    if (C_uF != null) lab6.C_uF = C_uF;
    if (lab6.R_Ohm != null &&
        lab6.C_uF != null &&
        lab6.R_Ohm! > 0 &&
        lab6.C_uF! > 0) {
      final cF = lab6.C_uF! * 1e-6; // µF → F
      lab6.f0TheoryHz = 1.0 / (2.0 * 3.141592653589793 * lab6.R_Ohm! * cF);
    }
    notifyListeners();
  }

  // Part F (high/low pass)
  void updateLab6HighLow({bool? isHighPass, String? notes}) {
    if (isHighPass != null) lab6.isHighPass = isHighPass;
    if (notes != null) lab6.notesHighLow = notes;
    notifyListeners();
  }

  // Lab 7 progress
  final lab7 = Lab7Progress();

  // Saved waveforms for Lab 7
  WaveformData? lab7VinSine;
  WaveformData? lab7VoutSine;
  WaveformData? lab7VinSquare;
  WaveformData? lab7VoutSquare;
  WaveformData? lab7VinTri;
  WaveformData? lab7VoutTri;

  void setLab7VinSine(WaveformData w) {
    lab7VinSine = w;
    lab7.vinSineSaved = true;
    notifyListeners();
  }

  void setLab7VoutSine(WaveformData w) {
    lab7VoutSine = w;
    lab7.voutSineSaved = true;
    notifyListeners();
  }

  void setLab7VinSquare(WaveformData w) {
    lab7VinSquare = w;
    lab7.vinSquareSaved = true;
    notifyListeners();
  }

  void setLab7VoutSquare(WaveformData w) {
    lab7VoutSquare = w;
    lab7.voutSquareSaved = true;
    notifyListeners();
  }

  void setLab7VinTri(WaveformData w) {
    lab7VinTri = w;
    lab7.vinTriSaved = true;
    notifyListeners();
  }

  void setLab7VoutTri(WaveformData w) {
    lab7VoutTri = w;
    lab7.voutTriSaved = true;
    notifyListeners();
  }

  void updateLab7Components({
    double? r1Ohm,
    double? r2Ohm,
    double? r3Ohm,
    double? c_uF,
  }) {
    if (r1Ohm != null) lab7.r1Ohm = r1Ohm;
    if (r2Ohm != null) lab7.r2Ohm = r2Ohm;
    if (r3Ohm != null) lab7.r3Ohm = r3Ohm;
    if (c_uF != null) lab7.c_uF = c_uF;
    notifyListeners();
  }

  void setLab7Built(bool built) {
    lab7.circuitBuilt_7 = built;
    notifyListeners();
  }

  void updateLab7Sine({double? vinAmp_V, double? voutAmp_V, double? phaseDeg}) {
    if (vinAmp_V != null) lab7.vinAmpSine_V = vinAmp_V;
    if (voutAmp_V != null) lab7.voutAmpSine_V = voutAmp_V;
    if (phaseDeg != null) lab7.phaseDegSine = phaseDeg;
    notifyListeners();
  }

  void updateLab7Square({
    double? vinAmp_V,
    double? voutAmp_V,
    double? phaseDeg,
  }) {
    if (vinAmp_V != null) lab7.vinAmpSquare_V = vinAmp_V;
    if (voutAmp_V != null) lab7.voutAmpSquare_V = voutAmp_V;
    if (phaseDeg != null) lab7.phaseDegSquare = phaseDeg;
    notifyListeners();
  }

  void updateLab7Tri({double? vinAmp_V, double? voutAmp_V, double? phaseDeg}) {
    if (vinAmp_V != null) lab7.vinAmpTri_V = vinAmp_V;
    if (voutAmp_V != null) lab7.voutAmpTri_V = voutAmp_V;
    if (phaseDeg != null) lab7.phaseDegTri = phaseDeg;
    notifyListeners();
  }

  // Lab 8 progress
  final lab8 = Lab8Progress();

  // Build-state setters
  void setLab8BuiltAND(bool v) {
    lab8.builtAND = v;
    notifyListeners();
  }

  void setLab8BuiltOR(bool v) {
    lab8.builtOR = v;
    notifyListeners();
  }

  void setLab8BuiltComplex(bool v) {
    lab8.builtComplex = v;
    notifyListeners();
  }

  // Table updates
  void updateLab8AndRow(int index, {double? voutV}) {
    if (index >= 0 && index < lab8.andVout.length && voutV != null) {
      lab8.andVout[index] = voutV;
      notifyListeners();
    }
  }

  void updateLab8OrRow(int index, {double? voutV}) {
    if (index >= 0 && index < lab8.orVout.length && voutV != null) {
      lab8.orVout[index] = voutV;
      notifyListeners();
    }
  }

  void updateLab8ComplexRow(int index, {double? voutV}) {
    if (index >= 0 && index < lab8.complexVout.length && voutV != null) {
      lab8.complexVout[index] = voutV;
      notifyListeners();
    }
  }

  void updateLab8Notes(String? notes) {
    lab8.notesCompare = notes;
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
      'Lab 4.1: First Order RC and RL Transients',
      'Lab 4.2: First Order RC and RL Transients',
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
        return const Lab4_1Screen();
      case 5:
        return const Lab4_2Screen();
      case 6:
        return const Lab5Screen();
      case 7:
        return const Lab6Screen();
      case 8:
        return const Lab7Screen();
      case 9:
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

class Lab4_1Screen extends StatefulWidget {
  const Lab4_1Screen({super.key});
  @override
  State<Lab4_1Screen> createState() => _Lab4_1ScreenState();
}

class _Lab4_1ScreenState extends State<Lab4_1Screen> {
  final _tauCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _rA1Ctrl = TextEditingController();
  final _cA1Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab4_1;
    _tauCtrl.text = s.tauMs?.toString() ?? '';
    _notesCtrl.text = s.notesCompare ?? '';
    _rA1Ctrl.text = s.rOhm_A1?.toString() ?? '';
    _cA1Ctrl.text = s.c_uF_A1?.toString() ?? '';
  }

  @override
  void dispose() {
    _tauCtrl.dispose();
    _notesCtrl.dispose();
    _rA1Ctrl.dispose();
    _cA1Ctrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _save() {
    context.read<AppState>().updateLab4(
      tauMs: _parseDouble(_tauCtrl.text),
      notesCompare: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lab 4.1 progress saved')));
  }

  // Helper to add dummy data until BLE is wired
  WaveformData _dummyWave(String label, double amp, double phase) {
    final n = 1024;
    final sr = 20000.0;
    final samples = List<double>.generate(
      n,
      (i) => amp * math.sin(2 * math.pi * i / 64 + phase),
    );
    return WaveformData(label: label, samples: samples, sampleRateHz: sr);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 4.1: RC Response with Different Capacitors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Build circuit 4.1
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A.1 — Record Component Values',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Record the resistor and capacitor values used in Circuit 4.1.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rA1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Resistor R (Ω)',
                    ),
                    onChanged: (text) {
                      final v = double.tryParse(text.trim());
                      if (v != null)
                        context.read<AppState>().updateLab4(rOhm_A1: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cA1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Capacitor C (µF)',
                    ),
                    onChanged: (text) {
                      final v = double.tryParse(text.trim());
                      if (v != null)
                        context.read<AppState>().updateLab4(c_uF_A1: v);
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
                    'Part A.2 — Build Circuit 4.1 and Enable Signal Generator',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit per the diagram. The only input is the signal generator. '
                    'Enable the signal generator with the specified output.',
                  ),
                  const SizedBox(height: 12),

                  // Diagram (lab4_circuit1.png)
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
                        'assets/images/labs/lab4_circuit1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: context.watch<AppState>().lab4_1.circuitBuilt_41,
                        onChanged: (v) => context.read<AppState>().updateLab4(
                          circuitBuilt_41: v ?? false,
                        ),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header label
                  Row(
                    children: [
                      Icon(
                        Icons.ssid_chart,
                        color: context.watch<AppState>().deviceConnected
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Enable signal generator input'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Enable signal generator with specific output (example settings)
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
                        if (!context.read<AppState>().lab4_1.circuitBuilt_41) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
                            ),
                          );
                          return;
                        }
                        // Example output: sine, 1 kHz, 1.0 Vpp, 0 V offset
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
                      child: const Text(
                        'Enable signal generator (sine 1 kHz, 1.0 Vpp)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Disable outputs (safety)
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

          // Part B — Save input/output waveforms (1 µF)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Save Vin/Vout (Capacitor = 1 µF)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture and save the input (Vin) and output (Vout) waveforms.',
                  ),
                  const SizedBox(height: 12),
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
                        // TODO: replace with real BLE snapshot for Vin (1 µF)
                        context.read<AppState>().setLab4Vin_1uF(
                          _dummyWave('Vin (1 µF)', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin (1 µF) saved')),
                        );
                      },
                      child: const Text('Save Vin (1 µF)'),
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
                        // TODO: replace with real BLE snapshot for Vout (1 µF)
                        context.read<AppState>().setLab4Vout_1uF(
                          _dummyWave('Vout (1 µF)', 0.7, 0.2),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout (1 µF) saved')),
                        );
                      },
                      child: const Text('Save Vout (1 µF)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_1.vinSaved_1uF ? '✓' : '—'} | Vout ${app.lab4_1.voutSaved_1uF ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part C — Replace 1 µF with 10 µF and save waveforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Replace Capacitor with 10 µF and Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Replace the 1 µF capacitor with 10 µF, then save Vin and Vout again.',
                  ),
                  const SizedBox(height: 12),
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
                        context.read<AppState>().setLab4Vin_10uF(
                          _dummyWave('Vin (10 µF)', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin (10 µF) saved')),
                        );
                      },
                      child: const Text('Save Vin (10 µF)'),
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
                        context.read<AppState>().setLab4Vout_10uF(
                          _dummyWave('Vout (10 µF)', 0.8, 0.4),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout (10 µF) saved')),
                        );
                      },
                      child: const Text('Save Vout (10 µF)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_1.vinSaved_10uF ? '✓' : '—'} | Vout ${app.lab4_1.voutSaved_10uF ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part D — Replace 10 µF with 100 µF and save waveforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — Replace Capacitor with 100 µF and Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Replace the 10 µF capacitor with 100 µF, then save Vin and Vout again.',
                  ),
                  const SizedBox(height: 12),
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
                        context.read<AppState>().setLab4Vin_100uF(
                          _dummyWave('Vin (100 µF)', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin (100 µF) saved')),
                        );
                      },
                      child: const Text('Save Vin (100 µF)'),
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
                        context.read<AppState>().setLab4Vout_100uF(
                          _dummyWave('Vout (100 µF)', 0.9, 0.7),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout (100 µF) saved')),
                        );
                      },
                      child: const Text('Save Vout (100 µF)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_1.vinSaved_100uF ? '✓' : '—'} | Vout ${app.lab4_1.voutSaved_100uF ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part E — Measure tau using τ = R × C
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — Time Constant τ = R × C',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compute τ = R × C for your circuit and enter the value (in milliseconds).',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tauCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'τ (ms)'),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null)
                        context.read<AppState>().updateLab4(tauMs: v);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part F — Compare saved waveforms and explain differences using τ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part F — Compare Waveforms (1 µF, 10 µF, 100 µF)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Open the saved waveforms for each capacitor value and explain differences using τ.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vin_1uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (1 µF)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vout_1uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (1 µF)'),
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
                            final w = context.read<AppState>().lab4Vin_10uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (10 µF)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vout_10uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (10 µF)'),
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
                            final w = context.read<AppState>().lab4Vin_100uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (100 µF)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab4Vout_100uF;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (100 µF)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes: Explain differences using τ',
                    ),
                    onChanged: (text) {
                      context.read<AppState>().updateLab4(
                        notesCompare: text.trim().isEmpty ? null : text.trim(),
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

class Lab4_2Screen extends StatefulWidget {
  const Lab4_2Screen({super.key});
  @override
  State<Lab4_2Screen> createState() => _Lab4_2ScreenState();
}

class _Lab4_2ScreenState extends State<Lab4_2Screen> {
  // Controllers (A: inductors/resistor; D/E: tau values; E notes)
  final _L1Ctrl = TextEditingController();
  final _RL1Ctrl = TextEditingController();
  final _L2Ctrl = TextEditingController();
  final _RL2Ctrl = TextEditingController();
  final _L3Ctrl = TextEditingController();
  final _RL3Ctrl = TextEditingController();
  final _RCtrl = TextEditingController();

  final _tauGraphCtrl = TextEditingController(); // Part D
  final _tauCalcCtrl = TextEditingController(); // Part E
  final _tauPrelabCtrl = TextEditingController(); // Part E
  final _notesECtrl = TextEditingController(); // Part E comparison notes

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab4_2;
    _L1Ctrl.text = s.L1_mH?.toString() ?? '';
    _RL1Ctrl.text = s.RL1_Ohm?.toString() ?? '';
    _L2Ctrl.text = s.L2_mH?.toString() ?? '';
    _RL2Ctrl.text = s.RL2_Ohm?.toString() ?? '';
    _L3Ctrl.text = s.L3_mH?.toString() ?? '';
    _RL3Ctrl.text = s.RL3_Ohm?.toString() ?? '';
    _RCtrl.text = s.R_Ohm?.toString() ?? '';
    _tauGraphCtrl.text = s.tauGraph_ms?.toString() ?? '';
    _tauCalcCtrl.text = s.tauCalc_ms?.toString() ?? '';
    _tauPrelabCtrl.text = s.tauPrelab_ms?.toString() ?? '';
    _notesECtrl.text = s.notesCompare ?? '';
  }

  @override
  void dispose() {
    _L1Ctrl.dispose();
    _RL1Ctrl.dispose();
    _L2Ctrl.dispose();
    _RL2Ctrl.dispose();
    _L3Ctrl.dispose();
    _RL3Ctrl.dispose();
    _RCtrl.dispose();
    _tauGraphCtrl.dispose();
    _tauCalcCtrl.dispose();
    _tauPrelabCtrl.dispose();
    _notesECtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  WaveformData _dummyWave(String label, double amp, double phase) {
    final n = 1024;
    final sr = 20000.0;
    final samples = List<double>.generate(
      n,
      (i) => amp * math.sin(2 * math.pi * i / 64 + phase),
    );
    return WaveformData(label: label, samples: samples, sampleRateHz: sr);
  }

  void _saveAll() {
    final app = context.read<AppState>();
    app.updateLab4_2(
      L1_mH: _parseDouble(_L1Ctrl.text),
      RL1_Ohm: _parseDouble(_RL1Ctrl.text),
      L2_mH: _parseDouble(_L2Ctrl.text),
      RL2_Ohm: _parseDouble(_RL2Ctrl.text),
      L3_mH: _parseDouble(_L3Ctrl.text),
      RL3_Ohm: _parseDouble(_RL3Ctrl.text),
      R_Ohm: _parseDouble(_RCtrl.text),
      tauGraph_ms: _parseDouble(_tauGraphCtrl.text),
      tauCalc_ms: _parseDouble(_tauCalcCtrl.text),
      tauPrelab_ms: _parseDouble(_tauPrelabCtrl.text),
      notesCompare: _notesECtrl.text.trim().isEmpty
          ? null
          : _notesECtrl.text.trim(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lab 4.2 progress saved')));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 4.2: RL Response with Inductors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Measure inductance and resistance of 3 inductors + resistor R
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — Measure Inductors and Resistor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure the inductance (mH) and internal resistance (Ω) of three inductors, and the resistance of the resistor R. Record the values below.',
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the meter.'),
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
                  // Inductor 1
                  TextField(
                    controller: _L1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'L1 (mH)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(L1_mH: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _RL1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R_L1 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(RL1_Ohm: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Inductor 2
                  TextField(
                    controller: _L2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'L2 (mH)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(L2_mH: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _RL2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R_L2 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(RL2_Ohm: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Inductor 3
                  TextField(
                    controller: _L3Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'L3 (mH)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(L3_mH: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _RL3Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R_L3 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(RL3_Ohm: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Resistor R
                  TextField(
                    controller: _RCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null) app.updateLab4_2(R_Ohm: v);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part B — Build circuit and enable signal generator (same specs), with tip text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Build Circuit and Enable Signal Generator',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build the circuit per the diagram. The input is provided by the signal generator.\n\n'
                    'Tips:\n'
                    '• Use the three inductors in series to create a 360 mH inductor.\n'
                    '• The 420 Ω resistor is the sum of the internal resistances of the inductors; NOT an external resistor. \n',
                  ),
                  const SizedBox(height: 12),
                  // Diagram placeholder (replace with your asset if available)
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
                        'assets/images/labs/lab4_circuit2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab4_2.circuitBuilt_42,
                        onChanged: (v) => context.read<AppState>().updateLab4_2(
                          circuitBuilt_42: v ?? false,
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
                        child: Text('Enable signal generator input'),
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
                        if (!app.lab4_2.circuitBuilt_42) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
                            ),
                          );
                          return;
                        }
                        // Same specs as before: sine 1 kHz, 1.0 Vpp, 0 V offset
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
                      child: const Text(
                        'Enable signal generator (sine 1 kHz, 1.0 Vpp)',
                      ),
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

          // Part C — Measure and save input/output waveforms
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Save Vin and Vout Waveforms',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture and save the input (Vin) and output (Vout) waveforms.',
                  ),
                  const SizedBox(height: 12),
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
                        // TODO: replace dummy with real snapshot via BLE
                        context.read<AppState>().setLab4_2VinWaveform(
                          _dummyWave('Vin (4.2)', 1.0, 0.0),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vin waveform saved')),
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
                        // TODO: replace dummy with real snapshot via BLE
                        context.read<AppState>().setLab4_2VoutWaveform(
                          _dummyWave('Vout (4.2)', 0.7, 0.3),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vout waveform saved')),
                        );
                      },
                      child: const Text('Save Vout waveform'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saved: Vin ${app.lab4_2.vinSaved_42 ? '✓' : '—'} | Vout ${app.lab4_2.voutSaved_42 ? '✓' : '—'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Part D — Measure tau using cursor on saved waveforms (as in prelab)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — τ from Waveform Cursor (ms)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use the waveform cursor method (as in prelab) to determine τ from a saved waveform. Enter τ (in ms).',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final w = context
                                .read<AppState>()
                                .lab4_2VinWaveform;
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
                            final w = context
                                .read<AppState>()
                                .lab4_2VoutWaveform;
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
                  TextField(
                    controller: _tauGraphCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'τ (ms) — from cursor measurement',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) app.updateLab4_2(tauGraph_ms: v);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part E — Calculate τ = L / (R + RL) and compare
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part E — τ = L / (R + RL) (ms) and Comparison',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compute τ using τ = L / (R + RL), where L is total inductance, R is the resistor, and RL is the total resistance of the inductor(s).\n'
                    'Enter your calculated τ and the prelab τ, then write a note comparing these values with τ from Part D.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tauCalcCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'τ_calc (ms) — L / (R + RL)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) app.updateLab4_2(tauCalc_ms: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tauPrelabCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'τ_prelab (ms)',
                    ),
                    onChanged: (text) {
                      final v = _parseDouble(text);
                      if (v != null) app.updateLab4_2(tauPrelab_ms: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesECtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText:
                          'Notes: Compare τ_calc, τ_prelab, and τ_cursor (Part D)',
                    ),
                    onChanged: (text) {
                      app.updateLab4_2(
                        notesCompare: text.trim().isEmpty ? null : text.trim(),
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
                onPressed: _saveAll,
                child: const Text('Save Progress'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the meter.'),
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
                    controller: _rPotMinCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'R_pot_min (Ω)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab5(rPotMinOhm: v);
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
                      if (v != null)
                        context.read<AppState>().updateLab5(rPotMaxOhm: v);
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
                                builder: (_) => Lab3WaveformViewer(data: w),
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
                                builder: (_) => Lab3WaveformViewer(data: w),
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
                                builder: (_) => Lab3WaveformViewer(data: w),
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
                                builder: (_) => Lab3WaveformViewer(data: w),
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
                                builder: (_) => Lab3WaveformViewer(data: w),
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
                                builder: (_) => Lab3WaveformViewer(data: w),
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
                      if (v != null)
                        context.read<AppState>().updateLab5(timeShiftMsMax: v);
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
                      if (v != null)
                        context.read<AppState>().updateLab5(
                          phaseShiftDegMax: v,
                        );
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use the meter.'),
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
                    controller: _vrmsSourceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'V_RMS (source, V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab5(vrmsSource: v);
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
                      if (v != null)
                        context.read<AppState>().updateLab5(vrmsPot: v);
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
                      if (v != null)
                        context.read<AppState>().updateLab5(vrmsCap: v);
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
    for (final c in _vinCtrls) c.dispose();
    for (final c in _voutCtrls) c.dispose();
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
                  // Diagram (lab6_circuit1.png)
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
                              content: Text(
                                'Connect to the device to change inputs.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (!app.lab6.circuitBuilt_6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Check the box after building first.',
                              ),
                            ),
                          );
                          return;
                        }
                        // NOTE: If “amplitude = 2 V” means 2 V peak-to-peak, pass 2000 mVpp; if 2 V peak, pass 4000 mVpp.
                        context.read<AppState>().sendEnableSignalGeneratorSine(
                          freqHz: 1,
                          amplitude_mVpp: 2000, // adjust to 4000 if 2 V = peak
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

          // Part C — Fill the rest of the table for all other frequencies
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

          // Part D — Explain how to draw a Bode plot
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
                    'Using the data from your table, create a Bode Plot of the magnitude response. \n'
                    'Remember that the horizontal axis of the plot will be log(frequency), and the vertical axis will be decibels.\n'
                    'Decibels (dB) can be calculated using dB = 20log(Vout/Vin)',
                  ),
                ],
              ),
            ),
          ),

          // Part E — Record –3 dB frequency and compare to f0 = 1/(2πRC)
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'f_–3dB (Hz)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab6Bode(
                          fMinus3dBApproxHz: v,
                        );
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab6Bode(R_Ohm: v);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'C (µF)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab6Bode(C_uF: v);
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
                          ? 'Δ = ${(fPlot - f0).toStringAsFixed(2)} Hz (relative: ${((fPlot - f0) / f0 * 100).toStringAsFixed(1)} %)'
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

          // Part F — High-pass or Low-pass?
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
                      setState(
                        () => _isHighPass = (checked ?? false) ? true : null,
                      );
                      context.read<AppState>().updateLab6HighLow(
                        isHighPass: _isHighPass,
                      );
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Low-pass'),
                    value: _isHighPass == false && _isHighPass != null,
                    onChanged: (checked) {
                      setState(
                        () => _isHighPass = (checked ?? false) ? false : null,
                      );
                      context.read<AppState>().updateLab6HighLow(
                        isHighPass: _isHighPass,
                      );
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesHL,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Explanation'),
                    onChanged: (t) {
                      context.read<AppState>().updateLab6HighLow(
                        notes: t.trim().isEmpty ? null : t.trim(),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Lab 6 progress saved (values persist in memory)',
                      ),
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

  // Helper: one table row (frequency, Vin/Vout inputs, ratio, set generator button)
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
                    // Keep same amplitude spec as Part A (adjust if your firmware expects peak vs p–p)
                    amplitude_mVpp: 2000, // adjust to 4000 if 2 V = peak
                    offset_mV: 0,
                    phase_mdeg: 0,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generator set to ${row.fHz} Hz')),
                  );
                },
                child: const Text('Set generator'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: vinCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Vin (mV RMS)'),
                onChanged: (t) {
                  final v = _parseDouble(t);
                  if (v != null) app.updateLab6Row(index: index, vin_mV: v);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: voutCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Vout (mV RMS)'),
                onChanged: (t) {
                  final v = _parseDouble(t);
                  if (v != null) app.updateLab6Row(index: index, vout_mV: v);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text(
                'Vout/Vin: ${row.ratio != null ? row.ratio!.toStringAsFixed(3) : '—'}',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Lab7Screen extends StatefulWidget {
  const Lab7Screen({super.key});
  @override
  State<Lab7Screen> createState() => _Lab7ScreenState();
}

class _Lab7ScreenState extends State<Lab7Screen> {
  // Part A controllers
  final _r1Ctrl = TextEditingController();
  final _r2Ctrl = TextEditingController();
  final _r3Ctrl = TextEditingController();
  final _cCtrl = TextEditingController();

  // Part B (sine) controllers
  final _vinAmpSineCtrl = TextEditingController();
  final _voutAmpSineCtrl = TextEditingController();
  final _phaseSineCtrl = TextEditingController();

  // Part C (square) controllers
  final _vinAmpSquareCtrl = TextEditingController();
  final _voutAmpSquareCtrl = TextEditingController();
  final _phaseSquareCtrl = TextEditingController();

  // Part D (triangle) controllers
  final _vinAmpTriCtrl = TextEditingController();
  final _voutAmpTriCtrl = TextEditingController();
  final _phaseTriCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().lab7;
    _r1Ctrl.text = s.r1Ohm?.toString() ?? '';
    _r2Ctrl.text = s.r2Ohm?.toString() ?? '';
    _r3Ctrl.text = s.r3Ohm?.toString() ?? '';
    _cCtrl.text = s.c_uF?.toString() ?? '';

    _vinAmpSineCtrl.text = s.vinAmpSine_V?.toString() ?? '';
    _voutAmpSineCtrl.text = s.voutAmpSine_V?.toString() ?? '';
    _phaseSineCtrl.text = s.phaseDegSine?.toString() ?? '';

    _vinAmpSquareCtrl.text = s.vinAmpSquare_V?.toString() ?? '';
    _voutAmpSquareCtrl.text = s.voutAmpSquare_V?.toString() ?? '';
    _phaseSquareCtrl.text = s.phaseDegSquare?.toString() ?? '';

    _vinAmpTriCtrl.text = s.vinAmpTri_V?.toString() ?? '';
    _voutAmpTriCtrl.text = s.voutAmpTri_V?.toString() ?? '';
    _phaseTriCtrl.text = s.phaseDegTri?.toString() ?? '';
  }

  @override
  void dispose() {
    _r1Ctrl.dispose();
    _r2Ctrl.dispose();
    _r3Ctrl.dispose();
    _cCtrl.dispose();
    _vinAmpSineCtrl.dispose();
    _voutAmpSineCtrl.dispose();
    _phaseSineCtrl.dispose();
    _vinAmpSquareCtrl.dispose();
    _voutAmpSquareCtrl.dispose();
    _phaseSquareCtrl.dispose();
    _vinAmpTriCtrl.dispose();
    _voutAmpTriCtrl.dispose();
    _phaseTriCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  WaveformData _dummyWave(String label, double amp, double phase) {
    final n = 1024, sr = 20000;
    final samples = List<double>.generate(
      n,
      (i) => amp * math.sin(2 * math.pi * i / 64 + phase),
    );
    return WaveformData(
      label: label,
      samples: samples,
      sampleRateHz: sr.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 7: Waveforms with Op-Amp'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Part A — Measure components and build circuit (with diagram)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part A — Measure Components and Build Circuit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Measure R1, R2, R3 (Ω) and C (µF), then build the circuit per the diagram. \n'
                    'Note: The 5k resistor R2 should be made with two 10k resistors in parallel.',
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
                        'assets/images/labs/lab7_circuit1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use meter.'),
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
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Components(r1Ohm: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _r2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R2 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Components(r2Ohm: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _r3Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'R3 (Ω)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Components(r3Ohm: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'C (µF)'),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Components(c_uF: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: app.lab7.circuitBuilt_7,
                        onChanged: (v) =>
                            context.read<AppState>().setLab7Built(v ?? false),
                      ),
                      const Text('I have built the circuit as shown'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Part B — Sine: enable rails + generator, save Vin/Vout, measure amplitudes and phase
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part B — Sine Wave (f = 30 Hz, 0°, 0 V offset, 0.5 V amplitude)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable op-amp rails (+/− 5 V), set the generator to sine. Save Vin and Vout snapshots. Measure amplitudes and phase between waves.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.power,
                        color: connected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Enable op-amp rails (+/− 5 V)'),
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
                              content: Text('Connect to change outputs.'),
                            ),
                          );
                          return;
                        }
                        if (!app.lab7.circuitBuilt_7) {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Op-amp rails enabled')),
                        );
                      },
                      child: const Text('Enable rails'),
                    ),
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
                          'Set generator: sine, 30 Hz, 0°, 0 V offset, 0.5 V amplitude',
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
                              content: Text('Connect to set generator.'),
                            ),
                          );
                          return;
                        }
                        // NOTE: amplitude interpretation:
                        // If 0.5 V means peak-to-peak, pass 500 mVpp; if 0.5 V peak, pass 1000 mVpp.
                        context.read<AppState>().sendEnableSignalGeneratorSine(
                          freqHz: 30,
                          amplitude_mVpp: 500,
                          offset_mV: 0,
                          phase_mdeg: 0,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generator set: sine 30 Hz, 0.5 V'),
                          ),
                        );
                      },
                      child: const Text('Enable sine generator'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VinSine(
                              _dummyWave('Vin (sine)', 0.25, 0.0),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vin (sine) saved')),
                            );
                          },
                          child: const Text('Save Vin (sine)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VoutSine(
                              _dummyWave('Vout (sine)', 0.20, 0.3),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vout (sine) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vout (sine)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VinSine;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (sine)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VoutSine;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (sine)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vinAmpSineCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vin amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Sine(vinAmp_V: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voutAmpSineCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vout amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Sine(voutAmp_V: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseSineCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Phase shift (degrees)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Sine(phaseDeg: v);
                    },
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

          // Part C — Square wave
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part C — Square Wave (f = 30 Hz, 0°, 0 V offset, 0.5 V amplitude)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set the generator to square. Save Vin and Vout snapshots. Measure amplitudes and phase shift.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to set generator.'),
                            ),
                          );
                          return;
                        }
                        context
                            .read<AppState>()
                            .sendEnableSignalGeneratorSquare(
                              freqHz: 30,
                              amplitude_mVpp: 500,
                              offset_mV: 0,
                              phase_mdeg: 0,
                              duty_per_mille: 500,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generator set: square 30 Hz, 0.5 V'),
                          ),
                        );
                      },
                      child: const Text('Enable square generator'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VinSquare(
                              _dummyWave('Vin (square)', 0.25, 0.0),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vin (square) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vin (square)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VoutSquare(
                              _dummyWave('Vout (square)', 0.20, 0.3),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vout (square) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vout (square)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VinSquare;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (square)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VoutSquare;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (square)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vinAmpSquareCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vin amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Square(vinAmp_V: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voutAmpSquareCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vout amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Square(voutAmp_V: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseSquareCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Phase shift (degrees)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Square(phaseDeg: v);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Part D — Triangle wave
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Part D — Triangle Wave (f = 30 Hz, 0°, 0 V offset, 0.5 V amplitude)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set the generator to triangle. Save Vin and Vout snapshots. Measure amplitudes and phase shift.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!connected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connect to set generator.'),
                            ),
                          );
                          return;
                        }
                        context
                            .read<AppState>()
                            .sendEnableSignalGeneratorTriangle(
                              freqHz: 30,
                              amplitude_mVpp: 500,
                              offset_mV: 0,
                              phase_mdeg: 0,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Generator set: triangle 30 Hz, 0.5 V',
                            ),
                          ),
                        );
                      },
                      child: const Text('Enable triangle generator'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VinTri(
                              _dummyWave('Vin (triangle)', 0.25, 0.0),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vin (triangle) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vin (triangle)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!connected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connect to capture waveforms.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<AppState>().setLab7VoutTri(
                              _dummyWave('Vout (triangle)', 0.20, 0.3),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vout (triangle) saved'),
                              ),
                            );
                          },
                          child: const Text('Save Vout (triangle)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VinTri;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vin (triangle)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final w = context.read<AppState>().lab7VoutTri;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Lab3WaveformViewer(data: w),
                              ),
                            );
                          },
                          child: const Text('Open Vout (triangle)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vinAmpTriCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vin amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Tri(vinAmp_V: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voutAmpTriCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Measured Vout amplitude (V)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Tri(voutAmp_V: v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phaseTriCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Phase shift (degrees)',
                    ),
                    onChanged: (t) {
                      final v = _parseDouble(t);
                      if (v != null)
                        context.read<AppState>().updateLab7Tri(phaseDeg: v);
                    },
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
                      'Lab 7 progress saved (values persist in memory)',
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
}

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
    for (final c in _andVoutCtrls) c.dispose();
    for (final c in _orVoutCtrls) c.dispose();
    for (final c in _complexVoutCtrls) c.dispose();
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use meter.'),
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
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect to use meter.'),
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
