import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class MeterOverlayCard extends StatelessWidget {
const MeterOverlayCard({super.key});

bool _isSignificant(AppState app) {
final v = app.meterReading;
if (v == null) return false;
final a = v.abs();
switch (app.meterMode) {
case MeterMode.voltage: return a >= 1e-3;
case MeterMode.resistance: return a >= 0.5;
case MeterMode.capacitance: return a >= 1e-9;
case MeterMode.inductance: return a >= 1e-6;
}
}

String _unitForMode(MeterMode m) {
switch (m) {
case MeterMode.voltage: return 'V';
case MeterMode.resistance: return 'Ω';
case MeterMode.capacitance: return 'F';
case MeterMode.inductance: return 'H';
}
}

String _formatSI(double x, String unit) {
final ax = x.abs();
String prefix;
double scaled;
if (ax >= 1e6) { prefix = 'M'; scaled = x / 1e6; }
else if (ax >= 1e3) { prefix = 'k'; scaled = x / 1e3; }
else if (ax >= 1.0) { prefix = ''; scaled = x; }
else if (ax >= 1e-3){ prefix = 'm'; scaled = x * 1e3; }
else if (ax >= 1e-6){ prefix = 'µ'; scaled = x * 1e6; }
else if (ax >= 1e-9){ prefix = 'n'; scaled = x * 1e9; }
else { prefix = 'p'; scaled = x * 1e12; }

final str = (scaled.abs() >= 100)
? scaled.toStringAsFixed(0)
: (scaled.abs() >= 10)
? scaled.toStringAsFixed(1)
: scaled.toStringAsFixed(3);
return '$str $prefix$unit';
}

@override
Widget build(BuildContext context) {
final app = context.watch<AppState>();
final connected = app.deviceConnected;

final unit = _unitForMode(app.meterMode);
final hasReading = _isSignificant(app);
final headline = hasReading && app.meterReading != null
? _formatSI(app.meterReading!, unit)
: (app.meterEnabled ? 'Meter: waiting for stable reading…' : 'Meter off');

return Container(
color: Colors.white,
padding: const EdgeInsets.all(10), // slightly tighter
child: SingleChildScrollView( // scroll if content ever exceeds panel height
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Title row with Close
Row(
children: [
const Text('Meter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
const Spacer(),
IconButton(
tooltip: 'Close',
icon: const Icon(Icons.close),
onPressed: () => context.read<AppState>().hideMeterOverlay(),
),
],
),
const SizedBox(height: 4),

// Mode chips
Wrap(
spacing: 6,
runSpacing: 4,
children: [
ChoiceChip(
selected: app.meterMode == MeterMode.voltage,
label: const Text('Voltage'),
onSelected: (v) { if (v) context.read<AppState>().setMeterMode(MeterMode.voltage); },
),
ChoiceChip(
selected: app.meterMode == MeterMode.resistance,
label: const Text('Resistance'),
onSelected: (v) { if (v) context.read<AppState>().setMeterMode(MeterMode.resistance); },
),
ChoiceChip(
selected: app.meterMode == MeterMode.capacitance,
label: const Text('Capacitance'),
onSelected: (v) { if (v) context.read<AppState>().setMeterMode(MeterMode.capacitance); },
),
ChoiceChip(
selected: app.meterMode == MeterMode.inductance,
label: const Text('Inductance'),
onSelected: (v) { if (v) context.read<AppState>().setMeterMode(MeterMode.inductance); },
),
],
),

const SizedBox(height: 6),

// Bounded reading area with scaling
SizedBox(
height: 80, // reduced from 100 to avoid overflow
child: Center(
child: FittedBox(
fit: BoxFit.scaleDown,
child: Text(
headline,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: hasReading ? 32 : 16, // slightly smaller
fontWeight: hasReading ? FontWeight.w600 : FontWeight.w400,
),
),
),
),
),

const SizedBox(height: 6),

// Actions
Row(
children: [
ElevatedButton(
onPressed: hasReading && app.activeInsertTarget != null
? () => context.read<AppState>().insertCurrentReadingIntoActiveTarget()
: null,
child: const Text('Insert into field'),
),
const SizedBox(width: 8),
OutlinedButton(
onPressed: () {
if (!connected) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Connect to enable meter.')),
);
return;
}
if (!app.meterEnabled) {
context.read<AppState>().sendMeterConfigure(app.meterMode);
} else {
context.read<AppState>().sendMeterStop();
}
},
child: Text(app.meterEnabled ? 'Stop' : 'Start'),
),
],
),
],
),
),
);
}
}