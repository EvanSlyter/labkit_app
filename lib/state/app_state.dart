import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert' show utf8;
import 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  double? rA1Ohm;
  double? rA2Ohm;
  bool circuitBuilt = false;
  double? vCVolt;
  double? v1VoltCalc;
  double? v1VoltMeasure;
  double? v2VoltCalc;
  double? v2VoltMeasure;
  String? notesD;
  String? notesF;
}

class Lab2Progress {
  double? r1Ohm;
  double? r2Ohm;
  double? r3Ohm;
  double? r4Ohm;
  double? rLOhm;
  bool circuitBuilt = false;
  double? iL_mA;
  double? vxyVolt;
  double? vlCalcVolt;
  double? vocVolt;
  double? isc_mA;
  double? ilTh_mA;
  double? ilSim_mA;
  double? pd_meas_th_pct;
  double? pd_meas_sim_pct;
  double? pd_th_sim_pct;
}

class Lab3Progress {
  double? r1Ohm;
  double? r2Ohm;
  double? r3Ohm;
  bool circuitBuilt = false;
  double? vinVoltDC;
  double? voutVoltDC;
  String? notesC;
  double? scalingFactorDC;
  String? notesD;
  bool acVinSaved = false;
  bool acVoutSaved = false;
  double? vinAmp;
  double? voutAmp;
  double? scalingFactorAC;
  String? notesF;
  double? timeShiftMs;
}

class Lab4Progress {
  double? rOhm_A1;
  double? c_uF_A1;
  bool circuitBuilt_41 = false;

  bool vinSaved_1uF = false;
  bool voutSaved_1uF = false;

  bool vinSaved_10uF = false;
  bool voutSaved_10uF = false;

  bool vinSaved_100uF = false;
  bool voutSaved_100uF = false;

  double? tauMs;
  String? notesCompare;
}

class Lab4_2Progress {
  double? L1_mH;
  double? RL1_Ohm;
  double? L2_mH;
  double? RL2_Ohm;
  double? L3_mH;
  double? RL3_Ohm;
  double? R_Ohm;

  bool circuitBuilt_42 = false;

  bool vinSaved_42 = false;
  bool voutSaved_42 = false;

  double? tauGraph_ms;
  double? tauCalc_ms;
  double? tauPrelab_ms;

  String? notesCompare;
}

class Lab5Progress {
  double? rPotMinOhm;
  double? rPotMaxOhm;

  bool circuitBuilt_5 = false;

  bool vinMinSaved = false;
  bool voutMinSaved = false;
  bool vinMaxSaved = false;
  bool voutMaxSaved = false;

  String? notesPhaseShift;

  double? timeShiftMsMax;
  double? phaseShiftDegMax;

  double? vrmsSource;
  double? vrmsPot;
  double? vrmsCap;

  bool? kvlApplies;
  String? notesKVL;
}

class Lab6Row {
  final int fHz;
  double? vin_mV;
  double? vout_mV;
  double? ratio;
  Lab6Row({required this.fHz, this.vin_mV, this.vout_mV, this.ratio});
}

class Lab6Progress {
  bool circuitBuilt_6 = false;

  double? fMinus3dBApproxHz;
  double? f0TheoryHz;
  double? R_Ohm;
  double? C_uF;

  bool? isHighPass;
  String? notesHighLow;
}

class Lab7Progress {
  double? r1Ohm;
  double? r2Ohm;
  double? r3Ohm;
  double? c_uF;
  bool circuitBuilt_7 = false;

  bool vinSineSaved = false;
  bool voutSineSaved = false;
  double? vinAmpSine_V;
  double? voutAmpSine_V;
  double? phaseDegSine;

  bool vinSquareSaved = false;
  bool voutSquareSaved = false;
  double? vinAmpSquare_V;
  double? voutAmpSquare_V;
  double? phaseDegSquare;

  bool vinTriSaved = false;
  bool voutTriSaved = false;
  double? vinAmpTri_V;
  double? voutAmpTri_V;
  double? phaseDegTri;
}

class Lab8Progress {
  bool builtAND = false;
  bool builtOR = false;
  bool builtComplex = false;

  final List<double?> andVout = List<double?>.filled(4, null);
  final List<double?> orVout = List<double?>.filled(4, null);
  final List<double?> complexVout = List<double?>.filled(8, null);

  String? notesCompare;
}

class AppState extends ChangeNotifier {
  // --------------------
  // App mode / high-level state
  // --------------------
  AppMode mode = AppMode.none;

  // --------------------
  // BLE (connection + writes)
  // --------------------
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connSub;

  DeviceConnectionState bleConnectionState = DeviceConnectionState.disconnected;

  bool deviceConnected = false;
  bool outputsEnabled = false;

  String? connectedDeviceId;
  String? connectedDeviceName;

  bool get isBypass =>
      deviceConnected &&
      (connectedDeviceId == 'manual' || connectedDeviceId == null);

  // LabKit BLE UUIDs (service + control characteristic)
  static final Uuid _serviceUuid = Uuid.parse(
    "6e400001-b5a3-f393-e0a9-e50e24dcca9e",
  );
  static final Uuid _ctrlUuid = Uuid.parse(
    "6e400002-b5a3-f393-e0a9-e50e24dcca9e",
  );

  void _requireHardwareConnected() {
    if (!deviceConnected ||
        connectedDeviceId == null ||
        connectedDeviceId == 'manual') {
      throw StateError('LabKit hardware not connected');
    }
  }

  Future<void> _writeCtrlUtf8(String msg) async {
    _requireHardwareConnected();

    final characteristic = QualifiedCharacteristic(
      deviceId: connectedDeviceId!,
      serviceId: _serviceUuid,
      characteristicId: _ctrlUuid,
    );

    await _ble.writeCharacteristicWithResponse(
      characteristic,
      value: utf8.encode(msg),
    );
  }

  Future<void> connectToDevice({
    required String id,
    required String name,
  }) async {
    connectedDeviceId = id;
    connectedDeviceName = name;

    await _connSub?.cancel();
    _connSub = null;

    bleConnectionState = DeviceConnectionState.connecting;
    deviceConnected = false;
    notifyListeners();

    _connSub = _ble
        .connectToDevice(id: id, connectionTimeout: const Duration(seconds: 10))
        .listen(
          (update) {
            bleConnectionState = update.connectionState;
            deviceConnected =
                (update.connectionState == DeviceConnectionState.connected);

            if (update.connectionState == DeviceConnectionState.disconnected) {
              outputsEnabled = false;
              meterEnabled = false;
              meterReading = null;
            }
            notifyListeners();
          },
          onError: (_) {
            bleConnectionState = DeviceConnectionState.disconnected;
            deviceConnected = false;
            outputsEnabled = false;
            meterEnabled = false;
            meterReading = null;
            notifyListeners();
          },
        );
  }

  void setConnectedDeviceBypass({String name = 'LabKit (bypass)'}) {
    _connSub?.cancel();
    _connSub = null;

    connectedDeviceId = 'manual';
    connectedDeviceName = name;

    bleConnectionState = DeviceConnectionState.disconnected;
    deviceConnected = true;
    notifyListeners();
  }

  Future<void> disconnectFromDevice() async {
    await _connSub?.cancel();
    _connSub = null;

    bleConnectionState = DeviceConnectionState.disconnected;
    clearConnectedDevice();
  }

  void setConnectedDevice({required String id, required String name}) {
    unawaited(connectToDevice(id: id, name: name));
  }

  void clearConnectedDevice() {
    connectedDeviceId = null;
    connectedDeviceName = null;
    deviceConnected = false;
    notifyListeners();
  }

  // --------------------
  // Output control (UPDATED to actually talk to MCP4921 via BLE)
  // --------------------
  void setOutputsEnabled(bool enabled) {
    outputsEnabled = enabled;
    notifyListeners();
  }

  Future<void> sendSetPositiveSupply5V() async {
    await _writeCtrlUtf8('V=5.00');
    setOutputsEnabled(true);
  }

  Future<void> sendDisableOutputs() async {
    await _writeCtrlUtf8('V=0.00');
    setOutputsEnabled(false);
  }

  // Optional: generic voltage setter you can reuse in other labs
  Future<void> sendSetSupplyVoltage(double volts) async {
    final v = volts.clamp(0.0, 5.0);
    await _writeCtrlUtf8('V=${v.toStringAsFixed(2)}');
    setOutputsEnabled(v > 0.0);
  }

  // Stubs for later (still present so other screens compile)
  Future<void> sendSetOutputs({
    required bool enable,
    int? dc_mV,
    int? freq_mHz,
    int? amplitude_mV,
    int? offset_mV,
  }) async {
    setOutputsEnabled(enable);
  }

  Future<void> sendEnableOpAmpRailsPlusMinus5() async {
    // implement later
    setOutputsEnabled(true);
  }

  Future<void> sendSetInputDc500mV() async {
    await sendSetSupplyVoltage(0.50); // uses the helper we added earlier
  }

  Future<void> sendEnableSignalGeneratorSine({
    required int freqHz,
    required int amplitude_mVpp,
    int offset_mV = 0,
    int phase_mdeg = 0,
  }) async {}

  Future<void> sendEnableSignalGeneratorSquare({
    required int freqHz,
    required int amplitude_mVpp,
    int offset_mV = 0,
    int phase_mdeg = 0,
    int duty_per_mille = 500,
  }) async {}

  Future<void> sendEnableSignalGeneratorTriangle({
    required int freqHz,
    required int amplitude_mVpp,
    int offset_mV = 0,
    int phase_mdeg = 0,
  }) async {}

  // --------------------
  // Meter state (unchanged stubs)
  // --------------------
  MeterMode meterMode = MeterMode.voltage;
  bool meterEnabled = false;
  double? meterReading;
  DateTime? meterReadingAt;

  void setMeterMode(MeterMode m) {
    meterMode = m;
    notifyListeners();
    unawaited(sendMeterConfigure(m));
  }

  void setMeterEnabled(bool enabled) {
    meterEnabled = enabled;
    if (!enabled) meterReading = null;
    notifyListeners();
  }

  void updateMeterReading(double value) {
    meterReading = value;
    meterReadingAt = DateTime.now();
    notifyListeners();
  }

  Future<void> sendMeterConfigure(MeterMode m) async {
    meterEnabled = true;
    notifyListeners();
  }

  Future<void> sendMeterStop() async {
    meterEnabled = false;
    meterReading = null;
    notifyListeners();
  }

  // --------------------
  // Lab progress state (same structure you had)
  // --------------------
  final lab1 = Lab1Progress();
  final lab2 = Lab2Progress();
  final lab3 = Lab3Progress();
  final lab4_1 = Lab4Progress();
  final lab4_2 = Lab4_2Progress();
  final lab5 = Lab5Progress();
  final lab6 = Lab6Progress();
  final lab7 = Lab7Progress();
  final lab8 = Lab8Progress();

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

  // Waveforms (as in your earlier file)
  WaveformData? lab3VinWaveform;
  WaveformData? lab3VoutWaveform;

  void setLab3VinWaveform(WaveformData w) {
    lab3VinWaveform = w;
    notifyListeners();
  }

  void setLab3VoutWaveform(WaveformData w) {
    lab3VoutWaveform = w;
    notifyListeners();
  }

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

  // Lab5 setters (as before)
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

  // Lab6 rows
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

  void updateLab6Row({required int index, double? vin_mV, double? vout_mV}) {
    final row = lab6Rows[index];
    if (vin_mV != null) row.vin_mV = vin_mV;
    if (vout_mV != null) row.vout_mV = vout_mV;
    if ((row.vin_mV ?? 0) > 0 && row.vout_mV != null) {
      row.ratio = row.vout_mV! / row.vin_mV!;
    }
    notifyListeners();
  }

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
      final cF = lab6.C_uF! * 1e-6;
      lab6.f0TheoryHz = 1.0 / (2.0 * 3.141592653589793 * lab6.R_Ohm! * cF);
    }
    notifyListeners();
  }

  void updateLab6HighLow({bool? isHighPass, String? notes}) {
    if (isHighPass != null) lab6.isHighPass = isHighPass;
    if (notes != null) lab6.notesHighLow = notes;
    notifyListeners();
  }

  // Lab7
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

  // Lab8
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

  // --------------------
  // Student email + export
  // --------------------
  String? studentEmail;

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

  Future<String> buildExportZip() async {
    final tmpDir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final workDir = io.Directory('${tmpDir.path}/labkit_export_$stamp');
    await workDir.create(recursive: true);

    final summary = {
      'generated_at': DateTime.now().toIso8601String(),
      'student_email': studentEmail ?? '',
      'labs': {
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
        // (Keep the rest of your export mapping as needed)
      },
    };

    final prettyJson = const convert.JsonEncoder.withIndent(
      ' ',
    ).convert(summary);
    await _writeTextFile(workDir, 'summary.json', '$prettyJson\n');

    final archive = Archive();
    for (final entity in workDir.listSync(recursive: false)) {
      if (entity is io.File) {
        final bytes = await entity.readAsBytes();
        final name = p.basename(entity.path);
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    final zipPath = '${workDir.path}.zip';
    final zipFile = io.File(zipPath);
    await zipFile.writeAsBytes(zipBytes, flush: true);
    return zipPath;
  }

  Future<void> _writeTextFile(
    io.Directory dir,
    String name,
    String content,
  ) async {
    final file = io.File('${dir.path}/$name');
    await file.writeAsString(content);
  }

  // If you still need CSV helpers, add them back from your previous version.
  String _escapeCsv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

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

  // --------------------
  // Meter overlay UI
  // --------------------
  OverlayEntry? _meterOverlay;
  ValueSetter<double>? activeInsertTarget;

  void setActiveInsertTarget(ValueSetter<double>? target) {
    activeInsertTarget = target;
  }

  void showMeterOverlay(BuildContext context) {
    if (_meterOverlay != null) return;
    if (!meterEnabled) unawaited(sendMeterConfigure(meterMode));

    final screenH = MediaQuery.of(context).size.height;
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
                maxHeight: boundedMaxH,
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

  void hideMeterOverlay() {
    _meterOverlay?.remove();
    _meterOverlay = null;
    notifyListeners();
  }

  void insertCurrentReadingIntoActiveTarget() {
    final v = meterReading;
    final target = activeInsertTarget;
    if (v != null && target != null) {
      target(v);
    }
  }
}
