import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

enum WaveShape { sine, triangle, square }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // BLE debug controls
  final _bleTextCtrl = TextEditingController();
  bool _sending = false;

  // DAC voltage controls
  final _dacVoltCtrl = TextEditingController(text: '0.00');

  // Signal generator controls
  final _freqCtrl = TextEditingController(text: '1000');
  WaveShape _shape = WaveShape.sine;

  // UUIDs
  static final _serviceUuid =
      Uuid.parse("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
  static final _ctrlUuid =
      Uuid.parse("6e400002-b5a3-f393-e0a9-e50e24dcca9e");

  @override
  void initState() {
    super.initState();

    // Show debug-only warning once when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDebugWarningDialog();
    });
  }

  @override
  void dispose() {
    _bleTextCtrl.dispose();
    _dacVoltCtrl.dispose();
    _freqCtrl.dispose();
    super.dispose();
  }

  void _showDebugWarningDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Debug Settings'),
        content: const Text(
          'The Settings screen is intended only for testing and debugging the LabKit hardware.\n\n'
          'Do not change these settings during labs unless specifically instructed by your instructor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I understand'),
          ),
        ],
      ),
    );
  }

  QualifiedCharacteristic _ctrlChar(String deviceId) =>
      QualifiedCharacteristic(
        serviceId: _serviceUuid,
        characteristicId: _ctrlUuid,
        deviceId: deviceId,
      );

  Future<void> _writeUtf8ToCtrl(String msg) async {
    final app = context.read<AppState>();
    final deviceId = app.connectedDeviceId;
    if (deviceId == null || !app.deviceConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to LabKit.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final ble = FlutterReactiveBle();
      final bytes = utf8.encode(msg);
      await ble.writeCharacteristicWithResponse(
        _ctrlChar(deviceId),
        value: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent: $msg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BLE send failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendBleDebug() async {
    final msg = _bleTextCtrl.text;
    if (msg.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a message to send.')),
      );
      return;
    }
    await _writeUtf8ToCtrl(msg);
  }

  Future<void> _sendDacVoltage() async {
    final raw = _dacVoltCtrl.text.trim();
    final v = double.tryParse(raw);
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number (e.g. 2.50).')),
      );
      return;
    }
    if (v < 0.0 || v > 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voltage must be between 0.00 and 5.00 V.')),
      );
      return;
    }
    final cmd = 'V=${v.toStringAsFixed(2)}';
    await _writeUtf8ToCtrl(cmd);
  }

  String _shapeToCmd(WaveShape s) {
    switch (s) {
      case WaveShape.sine:
        return 'W=SINE';
      case WaveShape.triangle:
        return 'W=TRI';
      case WaveShape.square:
        return 'W=SQUARE';
    }
  }

  Future<void> _sendFrequency() async {
    final raw = _freqCtrl.text.trim();
    final f = int.tryParse(raw);
    if (f == null || f <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid frequency in Hz (e.g. 1000).')),
      );
      return;
    }
    await _writeUtf8ToCtrl('F=$f');
  }

  Future<void> _sendWaveShape() async {
    await _writeUtf8ToCtrl(_shapeToCmd(_shape));
  }

  Future<void> _sendWaveGenAll() async {
    await _sendWaveShape();
    await _sendFrequency();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings (Debug Only)')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Warning banner in the body as well
          Card(
            color: const Color(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Warning',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This Settings screen is for debugging and testing only.\n'
                    'Do not change these values during labs unless your instructor '
                    'explicitly tells you to.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 12),

          const Text('BLE Debug',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            app.deviceConnected
                ? 'Connected to: ${app.connectedDeviceName ?? app.connectedDeviceId}'
                : 'Not connected',
            style: TextStyle(
              color: app.deviceConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),

          // DAC voltage section
          const Text('DAC Voltage',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dacVoltCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Volts (0.00–5.00)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _sending ? null : _sendDacVoltage,
                child: const Text('Set'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Signal generator section
          const Text('Signal Generator',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _freqCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  decoration: const InputDecoration(
                    labelText: 'Frequency (Hz)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _sending ? null : _sendFrequency,
                child: const Text('Set F'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<WaveShape>(
            value: _shape,
            decoration: const InputDecoration(
              labelText: 'Wave shape',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: WaveShape.sine, child: Text('Sine')),
              DropdownMenuItem(value: WaveShape.triangle, child: Text('Triangle')),
              DropdownMenuItem(value: WaveShape.square, child: Text('Square')),
            ],
            onChanged: _sending
                ? null
                : (v) {
                    if (v == null) return;
                    setState(() => _shape = v);
                  },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: _sending ? null : _sendWaveShape,
                child: const Text('Set Shape'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _sending ? null : _sendWaveGenAll,
                child: const Text('Set Both'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Free-form BLE message
          TextField(
            controller: _bleTextCtrl,
            decoration: const InputDecoration(
              labelText: 'Message to send to LabKit (UTF-8)',
              hintText: 'e.g. V=2.50 or F=1000 or W=SINE',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: _sending ? null : _sendBleDebug,
                child: Text(_sending ? 'Sending…' : 'Send over BLE'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _sending ? null : () => _bleTextCtrl.clear(),
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}