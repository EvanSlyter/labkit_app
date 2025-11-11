import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../widgets/meter_overlay.dart';

enum AppMode { none, free, lab }

enum ToolRequirement { meter, scope }

enum MeterMode { voltage, resistance, capacitance, inductance }

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

  // Meter state
  MeterMode meterMode = MeterMode.voltage; // default mode
  bool meterEnabled = false; // true when the device is sending data
  double? meterReading; // latest reading in SI base units (V, Ω, F, H)
  DateTime? meterReadingAt; // when it was updated (optional)

  // Set mode (and configure device)
  void setMeterMode(MeterMode m) {
    meterMode = m;
    notifyListeners();
    // Optional: auto-enable and reconfigure meter on the device
    sendMeterConfigure(m);
  }

  // Enable/disable meter locally (you can call this on BLE connect/disconnect)
  void setMeterEnabled(bool enabled) {
    meterEnabled = enabled;
    if (!enabled) meterReading = null;
    notifyListeners();
  }

  // Called by your BLE layer when a new reading arrives (in base SI units)
  void updateMeterReading(double value) {
    meterReading = value;
    meterReadingAt = DateTime.now();
    notifyListeners();
  }

  // BLE stubs — wire these later
  Future<void> sendMeterConfigure(MeterMode m) async {
    // TODO: send a command over BLE (e.g., SetMeterMode + Start)
    // For now, just mark enabled so the UI shows "waiting".
    meterEnabled = true;
    notifyListeners();
  }

  Future<void> sendMeterStop() async {
    // TODO: stop meter on the device
    meterEnabled = false;
    meterReading = null;
    notifyListeners();
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

// Student email (persisted)
String? studentEmail;
// Call this once at app start (e.g., in main/home) to load stored email
Future<void> loadSettings() async {
final prefs = await SharedPreferences.getInstance();
studentEmail = prefs.getString('studentEmail');
notifyListeners();
}

Future<void> saveStudentEmail(String email) async {
studentEmail = email.trim();
final prefs = await SharedPreferences.getInstance();
await prefs.setString('studentEmail', studentEmail!);
notifyListeners();
}

// Build a ZIP with JSON/CSVs and return its path
Future<String> buildExportZip() async {
final tmpDir = await getTemporaryDirectory();
final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
final workDir = io.Directory('${tmpDir.path}/labkit_export_$stamp');
await workDir.create(recursive: true);

// 1) Write summary.json (add more fields from your labs as desired)
// 1) Write summary.json (add more fields from your labs as desired)
final summary = {
'generated_at': DateTime.now().toIso8601String(),
'student_email': studentEmail ?? '',
'labs': {
// Lab 1 (adjust names if yours differ)
'lab1': {
'rA1Ohm': lab1.rA1Ohm,
'rA2Ohm': lab1.rA2Ohm,
'circuitBuilt': lab1.circuitBuilt,
'vCVolt': lab1.vCVolt,
'vE1VoltCalc': lab1.v1VoltCalc,
'vE1VoltMeasure': lab1.v1VoltMeasure,
'vE2VoltCalc': lab1.v2VoltCalc,
'vE2VoltMeasure': lab1.v2VoltMeasure,
'notesD': lab1.notesD,
'notesF': lab1.notesF,
},

// Lab 2
'lab2': {
'r1Ohm': lab2.r1Ohm,
'r2Ohm': lab2.r2Ohm,
'r3Ohm': lab2.r3Ohm,
'r4Ohm': lab2.r4Ohm,
'rLOhm': lab2.rLOhm,
'circuitBuilt': lab2.circuitBuilt,
'iL_mA': lab2.iL_mA,
'vxyVolt': lab2.vxyVolt,
'vlCalcVolt': lab2.vlCalcVolt,
'vocVolt': lab2.vocVolt,
'isc_mA': lab2.isc_mA,
'ilTh_mA': lab2.ilTh_mA,
'ilSim_mA': lab2.ilSim_mA,
'pd_meas_th_pct': lab2.pd_meas_th_pct,
'pd_meas_sim_pct': lab2.pd_meas_sim_pct,
'pd_th_sim_pct': lab2.pd_th_sim_pct,
},

// Lab 3
'lab3': {
'r1Ohm': lab3.r1Ohm,
'r2Ohm': lab3.r2Ohm,
'r3Ohm': lab3.r3Ohm,
'circuitBuilt': lab3.circuitBuilt,
'vinVoltDC': lab3.vinVoltDC,
'voutVoltDC': lab3.voutVoltDC,
'notesC': lab3.notesC,
'scalingFactorDC': lab3.scalingFactorDC,
'notesD': lab3.notesD,
'acVinSaved': lab3.acVinSaved,
'acVoutSaved': lab3.acVoutSaved,
'vinAmp': lab3.vinAmp,
'voutAmp': lab3.voutAmp,
'scalingFactorAC': lab3.scalingFactorAC,
'notesF': lab3.notesF,
'timeShiftMs': lab3.timeShiftMs,
},

// Lab 4.1
'lab4_1': {
'rOhm_A1': lab4_1.rOhm_A1,
'c_uF_A1': lab4_1.c_uF_A1,
'circuitBuilt_41': lab4_1.circuitBuilt_41,
'vinSaved_1uF': lab4_1.vinSaved_1uF,
'voutSaved_1uF': lab4_1.voutSaved_1uF,
'vinSaved_10uF': lab4_1.vinSaved_10uF,
'voutSaved_10uF': lab4_1.voutSaved_10uF,
'vinSaved_100uF': lab4_1.vinSaved_100uF,
'voutSaved_100uF': lab4_1.voutSaved_100uF,
'tauMs': lab4_1.tauMs,
'notesCompare': lab4_1.notesCompare,
},

// Lab 4.2
'lab4_2': {
'L1_mH': lab4_2.L1_mH,
'RL1_Ohm': lab4_2.RL1_Ohm,
'L2_mH': lab4_2.L2_mH,
'RL2_Ohm': lab4_2.RL2_Ohm,
'L3_mH': lab4_2.L3_mH,
'RL3_Ohm': lab4_2.RL3_Ohm,
'R_Ohm': lab4_2.R_Ohm,
'circuitBuilt_42': lab4_2.circuitBuilt_42,
'vinSaved_42': lab4_2.vinSaved_42,
'voutSaved_42': lab4_2.voutSaved_42,
'tauGraph_ms': lab4_2.tauGraph_ms,
'tauCalc_ms': lab4_2.tauCalc_ms,
'tauPrelab_ms': lab4_2.tauPrelab_ms,
'notesCompare': lab4_2.notesCompare,
},

// Lab 5
'lab5': {
'rPotMinOhm': lab5.rPotMinOhm,
'rPotMaxOhm': lab5.rPotMaxOhm,
'notesPhaseShift': lab5.notesPhaseShift,
'timeShiftMsMax': lab5.timeShiftMsMax,
'phaseShiftDegMax': lab5.phaseShiftDegMax,
'vrmsSource': lab5.vrmsSource,
'vrmsPot': lab5.vrmsPot,
'vrmsCap': lab5.vrmsCap,
'kvlApplies': lab5.kvlApplies,
'notesKVL': lab5.notesKVL,
},

// Lab 6 (table exported separately as CSV; keep the scalars in JSON)
'lab6': {
'fMinus3dBApproxHz': lab6.fMinus3dBApproxHz,
'f0TheoryHz': lab6.f0TheoryHz,
'R_Ohm': lab6.R_Ohm,
'C_uF': lab6.C_uF,
'rowCount': lab6Rows.length,
},

// Lab 7
'lab7': {
'r1Ohm': lab7.r1Ohm,
'r2Ohm': lab7.r2Ohm,
'r3Ohm': lab7.r3Ohm,
'c_uF': lab7.c_uF,
'circuitBuilt_7': lab7.circuitBuilt_7,
// Sine
'vinAmpSine_V': lab7.vinAmpSine_V,
'voutAmpSine_V': lab7.voutAmpSine_V,
'phaseDegSine': lab7.phaseDegSine,
// Square
'vinAmpSquare_V': lab7.vinAmpSquare_V,
'voutAmpSquare_V': lab7.voutAmpSquare_V,
'phaseDegSquare': lab7.phaseDegSquare,
// Triangle
'vinAmpTri_V': lab7.vinAmpTri_V,
'voutAmpTri_V': lab7.voutAmpTri_V,
'phaseDegTri': lab7.phaseDegTri,
},

// Lab 8 (you already export CSVs; include scalars/notes in JSON too)
'lab8': {
'builtAND': lab8.builtAND,
'builtOR': lab8.builtOR,
'builtComplex': lab8.builtComplex,
'andVout': lab8.andVout,
'orVout': lab8.orVout,
'complexVout': lab8.complexVout,
'notes': lab8.notesCompare,
},
}
};
final prettyJson = const convert.JsonEncoder.withIndent(' ').convert(summary);
await _writeTextFile(workDir, 'summary.json', '$prettyJson\n');

// 2) Write Lab 6 table as CSV if present
if (lab6Rows.isNotEmpty) {
final rows = <List<String>>[
['f_hz', 'vin_mV', 'vout_mV', 'ratio'],
for (final r in lab6Rows)
[
r.fHz.toString(),
(r.vin_mV ?? '').toString(),
(r.vout_mV ?? '').toString(),
(r.ratio ?? '').toString(),
],
];
await _writeCsv(workDir, 'lab6_table.csv', rows);
}

// 3) Write Lab 8 truth tables as CSVs
final andRows = <List<String>>[
['A_V', 'B_V', 'Vout_V'],
['0', '0', (lab8.andVout[0] ?? '').toString()],
['0', '5', (lab8.andVout[1] ?? '').toString()],
['5', '0', (lab8.andVout[2] ?? '').toString()],
['5', '5', (lab8.andVout[3] ?? '').toString()],
];
await _writeCsv(workDir, 'lab8_and.csv', andRows);

final orRows = <List<String>>[
['A_V', 'B_V', 'Vout_V'],
['0', '0', (lab8.orVout[0] ?? '').toString()],
['0', '5', (lab8.orVout[1] ?? '').toString()],
['5', '0', (lab8.orVout[2] ?? '').toString()],
['5', '5', (lab8.orVout[3] ?? '').toString()],
];
await _writeCsv(workDir, 'lab8_or.csv', orRows);

final complexRows = <List<String>>[
['A_V', 'B_V', 'C_V', 'Vout_V'],
['0', '0', '0', (lab8.complexVout[0] ?? '').toString()],
['0', '0', '5', (lab8.complexVout[1] ?? '').toString()],
['0', '5', '0', (lab8.complexVout[2] ?? '').toString()],
['0', '5', '5', (lab8.complexVout[3] ?? '').toString()],
['5', '0', '0', (lab8.complexVout[4] ?? '').toString()],
['5', '0', '5', (lab8.complexVout[5] ?? '').toString()],
['5', '5', '0', (lab8.complexVout[6] ?? '').toString()],
['5', '5', '5', (lab8.complexVout[7] ?? '').toString()],
];
await _writeCsv(workDir, 'lab8_complex.csv', complexRows);

// 4) Write waveform CSVs (time,value) for any saved waveforms you have
final waveforms = <MapEntry<String, WaveformData?>>[
MapEntry('lab3_vin', lab3VinWaveform),
MapEntry('lab3_vout', lab3VoutWaveform),
MapEntry('lab4_1_vin_1uF', lab4Vin_1uF),
MapEntry('lab4_1_vout_1uF', lab4Vout_1uF),
MapEntry('lab4_1_vin_10uF', lab4Vin_10uF),
MapEntry('lab4_1_vout_10uF', lab4Vout_10uF),
MapEntry('lab4_1_vin_100uF', lab4Vin_100uF),
MapEntry('lab4_1_vout_100uF', lab4Vout_100uF),
MapEntry('lab4_2_vin', lab4_2VinWaveform),
MapEntry('lab4_2_vout', lab4_2VoutWaveform),
MapEntry('lab5_vin_min', lab5VinMinWaveform),
MapEntry('lab5_vout_min', lab5VoutMinWaveform),
MapEntry('lab5_vin_max', lab5VinMaxWaveform),
MapEntry('lab5_vout_max', lab5VoutMaxWaveform),
MapEntry('lab7_vin_sine', lab7VinSine),
MapEntry('lab7_vout_sine', lab7VoutSine),
MapEntry('lab7_vin_square', lab7VinSquare),
MapEntry('lab7_vout_square', lab7VoutSquare),
MapEntry('lab7_vin_tri', lab7VinTri),
MapEntry('lab7_vout_tri', lab7VoutTri),
];

for (final entry in waveforms) {
final w = entry.value;
if (w == null) continue;
final rows = <List<String>>[
['time_s', 'value'],
for (int i = 0; i < w.samples.length; i++)
[(i / w.sampleRateHz).toStringAsFixed(6), w.samples[i].toString()],
];
await _writeCsv(workDir, '${entry.key}.csv', rows);
}

// 5) Zip everything in workDir
final archive = Archive();
for (final entity in workDir.listSync(recursive: false)) {
if (entity is io.File) {
final bytes = await entity.readAsBytes();
final name = p.basename(entity.path); // from package:path
archive.addFile(ArchiveFile(name, bytes.length, bytes));
}
}
final zipBytes = ZipEncoder().encode(archive);
final zipPath = '${workDir.path}.zip';
final zipFile = io.File(zipPath);
await zipFile.writeAsBytes(zipBytes, flush: true);

return zipPath;
}

// Helper: write text file
Future<void> _writeTextFile(io.Directory dir, String name, String content) async {
final file = io.File('${dir.path}/$name');
await file.writeAsString(content);
}

// Helper: write CSV
Future<void> _writeCsv(io.Directory dir, String name, List<List<String>> rows) async {
final buf = StringBuffer();
for (final row in rows) {
buf.writeln(row.map(_escapeCsv).join(','));
}
await _writeTextFile(dir, name, buf.toString());
}

String _escapeCsv(String s) {
if (s.contains(',') || s.contains('"') || s.contains('\n')) {
return '"${s.replaceAll('"', '""')}"';
}
return s;
}

// Share helper: build and open email/share sheet
Future<void> shareExport(BuildContext context) async {
final zipPath = await buildExportZip();
final xfile = XFile(zipPath);
await Share.shareXFiles(
[xfile],
subject: 'LabKit export',
text: studentEmail != null && studentEmail!.isNotEmpty
? 'Export for $studentEmail attached.'
: 'LabKit export attached.',
);
}

// Overlay entry for the floating meter
// Overlay management
OverlayEntry? _meterOverlay;

// Target for "Insert into field" (set by the active TextField)
ValueSetter<double>? activeInsertTarget;
void setActiveInsertTarget(ValueSetter<double>? target) {
activeInsertTarget = target;
}

// Show the floating meter overlay (use the SafeArea version you already added)
void showMeterOverlay(BuildContext context) {
if (_meterOverlay != null) return;
if (!meterEnabled) sendMeterConfigure(meterMode);

final screenH = MediaQuery.of(context).size.height;
// Use up to 35% of the screen height, but cap at 260 px
final maxH = screenH * 0.35;
final boundedMaxH = maxH.clamp(220.0, 260.0);

_meterOverlay = OverlayEntry(
builder: (ctx) => SafeArea(
minimum: const EdgeInsets.only(right: 12, bottom: 12),
child: Align(
alignment: Alignment.bottomRight,
child: Material(
elevation: 8,
borderRadius: BorderRadius.circular(12),
clipBehavior: Clip.antiAlias,
child: ConstrainedBox(
constraints: BoxConstraints(
maxWidth: 320,
maxHeight: boundedMaxH, // dynamically bounded
),
child: const MeterOverlayCard(),
),
),
),
),
);

Overlay.of(context, rootOverlay: true).insert(_meterOverlay!);
notifyListeners();
}

// Hide the overlay
void hideMeterOverlay() {
_meterOverlay?.remove();
_meterOverlay = null;
notifyListeners();
}

// Insert current reading into the active target
void insertCurrentReadingIntoActiveTarget() {
final v = meterReading;
final target = activeInsertTarget;
if (v != null && target != null) {
target(v);
}
}

// Simulated connect/disconnect (replace with real BLE connect later)
Future<void> requestConnect() async {
// TODO: replace with BLE scan/connect flow; this is just a placeholder
deviceConnected = true;
notifyListeners();
}

Future<void> requestDisconnect() async {
// TODO: replace with real BLE disconnect
deviceConnected = false;
notifyListeners();
}

}

