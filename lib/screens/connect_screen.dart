import 'package:flutter/material.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanning... (placeholder)')),
              );
            },
            child: const Text('Scan'),
          ),
          const SizedBox(height: 12),
          const Text('Devices:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: const [
                ListTile(leading: Icon(Icons.bluetooth), title: Text('LabKit-1234'), subtitle: Text('RSSI: -60')),
                ListTile(leading: Icon(Icons.bluetooth), title: Text('LabKit-5678'), subtitle: Text('RSSI: -72')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Status: Disconnected'),
        ],
      ),
    );
  }
}