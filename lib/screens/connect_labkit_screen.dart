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

  // NEW: track when each device was last seen + prune timer
  final Map<String, DateTime> _lastSeen = {};
  Timer? _pruneTimer;

  @override
  void initState() {
    super.initState();
    _startScanFlow();

    // NEW: periodically remove devices that haven't been seen recently
    _pruneTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      const ttl = Duration(seconds: 3);

      final gone = _lastSeen.entries
          .where((e) => now.difference(e.value) > ttl)
          .map((e) => e.key)
          .toList();

      if (gone.isNotEmpty && mounted) {
        setState(() {
          for (final id in gone) {
            _lastSeen.remove(id);
            _seen.remove(id);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pruneTimer?.cancel(); // NEW
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
    _lastSeen.clear(); // NEW

    _scanSub = _ble
        .scanForDevices(withServices: [])
        .listen(
          (d) {
            final name = d.name.trim();
            final looksLikeLabKit =
                name.isNotEmpty && name.toLowerCase().contains('labkit');

            if (looksLikeLabKit) {
              _lastSeen[d.id] = DateTime.now(); // NEW
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
    _stopScan();

    final appState = context.read<AppState>();

    // Start connecting (async). We’ll wait until it reports connected or disconnected.
    await appState.connectToDevice(
      id: d.id,
      name: d.name.isEmpty ? 'LabKit' : d.name,
    );

    // Wait briefly for connection result (connected or disconnected/fail)
    // If you want, adjust timeout.
    final timeoutAt = DateTime.now().add(const Duration(seconds: 10));

    while (mounted && DateTime.now().isBefore(timeoutAt)) {
      if (appState.bleConnectionState == DeviceConnectionState.connected &&
          appState.deviceConnected) {
        Navigator.pop(context);
        return;
      }

      if (appState.bleConnectionState == DeviceConnectionState.disconnected &&
          !appState.deviceConnected) {
        // failed (or immediately disconnected)
        break;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to connect to LabKit.')),
    );
  }

  void _markConnectedBypass() {
    context.read<AppState>().setConnectedDeviceBypass(name: 'LabKit (bypass)');
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
            child: const Text(
              'Mark connected',
              style: TextStyle(color: Colors.white),
            ),
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
                leading: Icon(
                  _scanning ? Icons.bluetooth_searching : Icons.bluetooth,
                ),
                title: Text(
                  _scanning ? 'Scanning for LabKit…' : 'Scan for LabKit',
                ),
                subtitle: const Text('Keep the device powered and nearby.'),
                trailing: _scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
