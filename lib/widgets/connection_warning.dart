import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ConnectionWarning extends StatelessWidget {
const ConnectionWarning({super.key});
@override
Widget build(BuildContext context) {
final connected = context.watch<AppState>().deviceConnected;
if (connected) return const SizedBox.shrink();
return Container(
color: const Color(0xFFFFF3F3),
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
child: Row(
children: [
const Icon(Icons.warning_amber_rounded, color: Colors.red),
const SizedBox(width: 8),
const Expanded(child: Text('Not connected. Connect to the LabKit device to use measurement tools.', style: TextStyle(color: Colors.red))),
TextButton(
onPressed: () => context.read<AppState>().setDeviceConnected(true), // placeholder
child: const Text('Connect now'),
),
],
),
);
}
}