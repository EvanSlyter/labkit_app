import 'package:flutter/material.dart';

class MeterScreen extends StatelessWidget {
  const MeterScreen({super.key});

  Widget _metricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _metricCard('DC', '1.23 V'),
        _metricCard('RMS', '0.87 V'),
        _metricCard('Frequency', '1000 Hz'),
        _metricCard('Peak-to-Peak', '2.00 V'),
      ],
    );
  }
}