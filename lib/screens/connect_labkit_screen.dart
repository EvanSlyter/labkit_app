import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ConnectLabKitScreen extends StatefulWidget {
const ConnectLabKitScreen({super.key});

@override
State<ConnectLabKitScreen> createState() => _ConnectLabKitScreenState();
}

class _ConnectLabKitScreenState extends State<ConnectLabKitScreen> {
final _ble = FlutterReactiveBle();
StreamSubscription<DiscoveredDevice>? _scanSub;

bool _scanning = false;
final Map<String, DiscoveredDevice> _seen = {}; // key = deviceId

@override
void initState() {
super.initState();
_startScanFlow();
}

@override
void dispose() {
_stopScan();
super.dispose();
}

Future<void> _startScanFlow() async {
setState(() => _scanning = true);

// Android runtime permissions
if (Platform.isAndroid) {
await [
Permission.bluetoothScan,
Permission.bluetoothConnect,
Permission.locationWhenInUse,
].request();
}

// Start scanning (filter by name "LabKit")
_seen.clear();
_scanSub = _ble.scanForDevices(withServices: []).listen(
(d) {
final name = d.name.trim();
final looksLikeLabKit =
name.isNotEmpty && name.toLowerCase().contains('labkit');
if (looksLikeLabKit) {
setState(() {
_seen[d.id] = d;
});
}
},
onError: (_) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Scan failed. Try again.')),
);
}
setState(() => _scanning = false);
},
);

// Auto-stop after 10 seconds
Future.delayed(const Duration(seconds: 10), () {
if (mounted && _scanning) _stopScan();
});
}

void _stopScan() {
_scanSub?.cancel();
_scanSub = null;
if (mounted) setState(() => _scanning = false);
}

Future<void> _selectDevice(DiscoveredDevice d) async {
// Temporary “connect”: mark AppState and pop back to Start
_stopScan();
context.read<AppState>().setConnectedDevice(
id: d.id,
name: d.name.isEmpty ? 'LabKit' : d.name,
);
if (mounted) Navigator.pop(context);
}

void _markConnectedBypass() {
// Manual bypass: mark as connected and return to Start
context
.read<AppState>()
.setConnectedDevice(id: 'manual', name: 'LabKit (bypass)');
Navigator.pop(context);
}

@override
Widget build(BuildContext context) {
final devices = _seen.values.toList()
..sort((a, b) => (b.rssi).compareTo(a.rssi));

return Scaffold(
appBar: AppBar(
title: const Text('Connect to LabKit'),
actions: [
// Small bypass action in the AppBar (optional)
TextButton(
onPressed: _markConnectedBypass,
child: const Text('Mark connected', style: TextStyle(color: Colors.white)),
),
],
),
body: RefreshIndicator(
onRefresh: () async {
_stopScan();
await Future.delayed(const Duration(milliseconds: 200));
await _startScanFlow();
},
child: ListView(
padding: const EdgeInsets.all(12),
children: [
Card(
child: ListTile(
leading: Icon(_scanning ? Icons.bluetooth_searching : Icons.bluetooth),
title: Text(_scanning ? 'Scanning for LabKit…' : 'Scan for LabKit'),
subtitle: const Text('Keep the device powered and nearby.'),
trailing: _scanning
? const SizedBox(
width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
: TextButton(
onPressed: () {
_stopScan();
_startScanFlow();
},
child: const Text('Scan'),
),
onTap: () {
if (!_scanning) _startScanFlow();
},
),
),
const SizedBox(height: 8),

// Device list
if (devices.isEmpty)
const Padding(
padding: EdgeInsets.all(12),
child: Text(
'No LabKit devices found yet.\n\nTips:\n• Ensure the LabKit is powered and advertising.\n• Keep it within a few meters.\n• Tap Scan to try again.',
),
),
for (final d in devices)
Card(
child: ListTile(
leading: const Icon(Icons.developer_board),
title: Text(d.name.isEmpty ? 'LabKit' : d.name),
subtitle: Text('RSSI: ${d.rssi} • ID: ${d.id}'),
trailing: const Icon(Icons.chevron_right),
onTap: () => _selectDevice(d),
),
),

const SizedBox(height: 16),

// Big bypass button (prominent)
Card(
color: const Color(0xFFF8FAFF),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
const Text(
'Trouble scanning or BLE not set up yet?\nYou can skip for now and mark the device as connected to continue.',
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
ElevatedButton.icon(
icon: const Icon(Icons.check_circle),
label: const Text('Skip BLE and mark as connected'),
onPressed: _markConnectedBypass,
),
],
),
),
),
],
),
),
floatingActionButton: _scanning
? FloatingActionButton.small(
tooltip: 'Stop scan',
onPressed: _stopScan,
child: const Icon(Icons.stop),
)
: null,
);
}
}