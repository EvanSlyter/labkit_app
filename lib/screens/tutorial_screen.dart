import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart'; // adjust path if your file is elsewhere

class TutorialScreen extends StatelessWidget {
const TutorialScreen({super.key});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

return Scaffold(
appBar: AppBar(title: const Text('Tutorial')),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
// Section 1: Before you start
SectionCard(
title: 'Before you start',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Use this app together with your existing lab manual for best results.',
),
const SizedBox(height: 8),
Text(
'Prelabs, theory, and context are not included here and must be '
'completed beforehand. Follow your manual for setup diagrams, safety notes, '
'and calculations you need to bring into the lab.',
style: theme.textTheme.bodyMedium,
),
],
),
),
const SizedBox(height: 12),

// Section 2: Using the Meter
SectionCard(
title: 'Using the Meter overlay',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'You can open the meter as a floating overlay on top of any lab screen, '
'then insert the reading directly into a text field.',
),
const SizedBox(height: 8),
const Text('1) Tap the text box where you want the value.'),
const Text('2) Tap “Open Meter” (or the meter icon) to show the overlay.'),
const Text('3) Choose the mode (Voltage, Resistance, Capacitance, Inductance).'),
const Text('4) When a stable value appears, tap “Insert into field” (You may need to scroll down).'),
const SizedBox(height: 12),
Align(
alignment: Alignment.centerLeft,
child: ElevatedButton.icon(
icon: const Icon(Icons.speed),
label: const Text('Open Meter overlay'),
onPressed: () {
// Allow opening even if disconnected so users can see the overlay UI.
context.read<AppState>().showMeterOverlay(context);
},
),
),
const SizedBox(height: 8),
Text(
'Tip: The overlay floats above your current screen so you don’t have to navigate away.',
style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
),
],
),
),
const SizedBox(height: 12),

// Section 3: Static oscilloscope demo (not live)
SectionCard(
title: 'Oscilloscope Demo (static sample)',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: const [
Text(
'Below is a static (not live) example of a sine waveform. '
'In the labs the waveform will be collected mostly automatically. '
'You will need to connect the probes to the correct positions and press the save waveform button. ',
),
SizedBox(height: 12),
OscilloscopeDemo(),
],
),
),

const SizedBox(height: 24),

// Add more sections here as needed. The ListView will scroll, so you won’t get overflow.
// Example:
// SectionCard(
// title: 'Exporting your work',
// child: Text('Use Settings → Export to email a ZIP of your data (CSVs + JSON).'),
// ),
],
),
);
}
}

// Reusable section card
class SectionCard extends StatelessWidget {
final String title;
final Widget child;

const SectionCard({super.key, required this.title, required this.child});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
return Card(
elevation: 2,
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
const SizedBox(height: 12),
child,
],
),
),
);
}
}

// Static oscilloscope example (no animation, not live)
class OscilloscopeDemo extends StatelessWidget {
const OscilloscopeDemo({super.key});

// Fake static sine parameters
static const int sampleCount = 256;
static const double sampleRateHz = 2000; // x-axis in seconds
static const double freqHz = 10;
static const double amplitude = 1.0;
static const double phase = 0.0;

List<double> _generateSine() {
final twoPi = 2 * math.pi;
final dt = 1.0 / sampleRateHz;
return List<double>.generate(
sampleCount,
(i) => amplitude * math.sin(twoPi * freqHz * (i * dt) + phase),
);
}

@override
Widget build(BuildContext context) {
final samples = _generateSine();
final spots = List<FlSpot>.generate(
samples.length,
(i) => FlSpot(i / sampleRateHz, samples[i]),
);

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
SizedBox(
height: 180,
child: LineChart(
LineChartData(
minX: 0,
maxX: sampleCount / sampleRateHz,
minY: -1.2,
maxY: 1.2,
clipData: const FlClipData.all(),
gridData: FlGridData(show: true),
titlesData: FlTitlesData(
leftTitles: AxisTitles(
sideTitles: SideTitles(showTitles: true, reservedSize: 36),
),
bottomTitles: AxisTitles(
sideTitles: SideTitles(showTitles: true),
),
rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
),
lineBarsData: [
LineChartBarData(
spots: spots,
isCurved: false,
color: Colors.blue,
barWidth: 2,
dotData: FlDotData(show: false),
),
],
),
),
),
const SizedBox(height: 8),
Text(
'Static sine: f = ${freqHz.toStringAsFixed(0)} Hz, A = ${amplitude.toStringAsFixed(1)} V '
'(demo only, not a live feed)',
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
),
],
);
}
}