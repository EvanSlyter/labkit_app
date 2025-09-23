import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _mockMode = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SwitchListTile(
          title: const Text('Mock data mode'),
          value: _mockMode,
          onChanged: (v) => setState(() => _mockMode = v),
        ),
        const SizedBox(height: 12),
        const Text('Log:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('[Placeholder] Events will appear here.'),
      ],
    );
  }
}