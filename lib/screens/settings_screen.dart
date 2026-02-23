import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailCtrl = TextEditingController();

  // BLE debug controls
  final _bleTextCtrl = TextEditingController();
  bool _sending = false;

  // NEW: DAC voltage controls
  final _dacVoltCtrl = TextEditingController(text: '0.00');

  // UUIDs
  static final _serviceUuid =
      Uuid.parse("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
  static final _ctrlUuid =
      Uuid.parse("6e400002-b5a3-f393-e0a9-e50e24dcca9e");

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _emailCtrl.text = app.studentEmail ?? '';
    app.loadSettings();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _bleTextCtrl.dispose();
    _dacVoltCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String s) {
    final t = s.trim();
    return t.contains('@') && t.contains('.') && t.length >= 5;
  }

  QualifiedCharacteristic _ctrlChar(String deviceId) => QualifiedCharacteristic(
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
      await ble.writeCharacteristicWithResponse(_ctrlChar(deviceId), value: bytes);

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

    // Format to 2 decimals (change to 3 if you want finer UI granularity)
    final cmd = 'V=${v.toStringAsFixed(2)}';
    await _writeUtf8ToCtrl(cmd);
  }

    @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Student email (used for export)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'name@example.com'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final email = _emailCtrl.text.trim();
                  if (!_looksLikeEmail(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid email.')),
                    );
                    return;
                  }
                  await app.saveStudentEmail(email);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved: ${app.studentEmail}')),
                  );
                },
                child: const Text('Save'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () async {
                  if ((app.studentEmail ?? '').isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter and save your email first.')),
                    );
                    return;
                  }
                  await app.shareExport(context);
                },
                child: const Text('Export now'),
              ),
            ],
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 12),

          const Text('BLE Debug', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            app.deviceConnected
                ? 'Connected to: ${app.connectedDeviceName ?? app.connectedDeviceId}'
                : 'Not connected',
            style: TextStyle(color: app.deviceConnected ? Colors.green : Colors.red),
          ),
          const SizedBox(height: 8),

          // NEW: DAC voltage section
          const Text('DAC Voltage', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dacVoltCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

          // Existing free-form message sender
          TextField(
            controller: _bleTextCtrl,
            decoration: const InputDecoration(
              labelText: 'Message to send to LabKit (UTF-8)',
              hintText: 'e.g. V=2.50 or hello 123',
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