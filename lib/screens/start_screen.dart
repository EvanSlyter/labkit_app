import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'lab_list_screen.dart';
import 'tutorial_screen.dart';

class StartScreen extends StatelessWidget {
const StartScreen({super.key});

@override
Widget build(BuildContext context) {
final app = context.watch<AppState>();
final connected = app.deviceConnected;

return Scaffold(
appBar: AppBar(
title: const Text('LabKit'),
),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
// Connection card
Card(
child: Padding(
padding: const EdgeInsets.all(16),
child: Row(
children: [
Icon(
connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
color: connected ? Colors.green : Colors.red,
size: 28,
),
const SizedBox(width: 12),
Expanded(
child: Text(
connected ? 'Connected to LabKit' : 'Not connected',
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
),
),
ElevatedButton(
onPressed: () async {
if (!connected) {
// Placeholder connect (replace with BLE connect later)
await context.read<AppState>().requestConnect();
} else {
await context.read<AppState>().requestDisconnect();
}
},
child: Text(connected ? 'Disconnect' : 'Connect'),
),
],
),
),
),
const SizedBox(height: 16),

// Labs button (requires connection)
Card(
elevation: 2,
child: InkWell(
onTap: () {
if (!connected) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Connect to the device to enter Labs.')),
);
return;
}
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const LabListScreen()),
);
},
child: Padding(
padding: const EdgeInsets.all(20),
child: Row(
children: [
Icon(Icons.science, size: 28, color: connected ? Colors.blue : Colors.grey),
const SizedBox(width: 12),
Expanded(
child: Text(
'Labs',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
color: connected ? Colors.black : Colors.black54,
),
),
),
const Icon(Icons.chevron_right),
],
),
),
),
),
const SizedBox(height: 12),

// Tutorial button (always allowed)
Card(
elevation: 2,
child: InkWell(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const TutorialScreen()),
);
},
child: const Padding(
padding: EdgeInsets.all(20),
child: Row(
children: [
Icon(Icons.menu_book, size: 28, color: Colors.blue),
SizedBox(width: 12),
Expanded(
child: Text(
'Tutorial (Getting Started)',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
),
),
Icon(Icons.chevron_right),
],
),
),
),
),
const SizedBox(height: 24),

// Small hint
const Text(
'Tip: Connect first to unlock the Labs screen. Tutorial is available any time.',
style: TextStyle(color: Colors.grey),
),
],
),
);
}
}