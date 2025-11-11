import 'package:flutter/material.dart';
import 'lab4_1_screen.dart';
import 'lab4_2_screen.dart';

class Lab4MenuScreen extends StatelessWidget {
const Lab4MenuScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Lab 4: Select section')),
body: ListView(
padding: const EdgeInsets.all(12),
children: [
Card(
child: ListTile(
leading: const Icon(Icons.science),
title: const Text('Lab 4.1 — RC response with different capacitors'),
//subtitle: const Text('Build 4.1, save waveforms (1µF, 10µF, 100µF), compute τ'),
trailing: const Icon(Icons.chevron_right),
onTap: () => Navigator.push(
context,
MaterialPageRoute(builder: (context) => const Lab4_1Screen()),
),
),
),
Card(
child: ListTile(
leading: const Icon(Icons.science_outlined),
title: const Text('Lab 4.2 — RL response with inductors'),
//subtitle: const Text('Measure L & R, build 4.2, save waveforms, find τ'),
trailing: const Icon(Icons.chevron_right),
onTap: () => Navigator.push(
context,
MaterialPageRoute(builder: (context) => const Lab4_2Screen()),
),
),
),
],
),
);
}
}