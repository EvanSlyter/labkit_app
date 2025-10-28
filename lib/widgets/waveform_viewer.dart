import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart'; // for WaveformData

class WaveformViewer extends StatelessWidget {
final WaveformData? data; // pass null-safe; viewer handles "no data"
const WaveformViewer({super.key, required this.data});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text(data?.label ?? 'Waveform')),
body: Padding(
padding: const EdgeInsets.all(12),
child: data == null
? const Center(child: Text('No saved waveform to display.'))
: LineChart(
LineChartData(
minX: 0,
lineBarsData: [
LineChartBarData(
spots: List<FlSpot>.generate(
data!.samples.length,
(i) => FlSpot(i / data!.sampleRateHz, data!.samples[i]),
),
isCurved: false,
dotData: FlDotData(show: false),
color: Colors.blue,
barWidth: 2,
),
],
gridData: FlGridData(show: true),
titlesData: FlTitlesData(
leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
),
),
),
),
);
}
}