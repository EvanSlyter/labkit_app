import 'package:flutter/material.dart';
import 'lab4_menu_screen.dart'; // sub-menu for Lab 4
import 'lab1_screen.dart';
import 'lab2_screen.dart';
import 'lab3_screen.dart';
import 'lab5_screen.dart';
import 'lab6_screen.dart';
import 'lab7_screen.dart';
import 'lab8_screen.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class _LabItem {
final String title;
final String? subtitle;
final IconData icon;
final WidgetBuilder builder; // (BuildContext) => Widget

_LabItem({
required this.title,
required this.icon,
required this.builder,
this.subtitle,
});
}

Future<bool> _confirmPrelab(BuildContext context) async {
return (await showDialog<bool>(
context: context,
builder: (ctx) => AlertDialog(
title: const Text('Prelab confirmation'),
content: const Text(
'Have you completed the prelab for this lab?\n\n'
'Prelabs provide context and setup. Some labs may be difficult or impossible to complete without them.',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx, false),
child: const Text('Cancel'),
),
TextButton(
onPressed: () => Navigator.pop(ctx, true),
child: const Text('Continue without prelab'),
),
ElevatedButton(
onPressed: () => Navigator.pop(ctx, true),
child: const Text('I completed the prelab'),
),
],
),
)) ??
false;
}

class LabListScreen extends StatelessWidget {
const LabListScreen({super.key});



@override
Widget build(BuildContext context) {
final items = <_LabItem>[
_LabItem(
title: 'Lab 1',
subtitle: 'Ohms Law and Kirchoffs Laws',
icon: Icons.filter_1,
builder: (context) => const Lab1Screen(),
),
_LabItem(
title: 'Lab 2',
subtitle: 'Node Voltages and Equivalent Circuits',
icon: Icons.filter_2,
builder: (context) => const Lab2Screen(),
),
_LabItem(
title: 'Lab 3',
subtitle: 'Introduction to Op Amps',
icon: Icons.filter_3,
builder: (context) => const Lab3Screen(),
),
_LabItem(
title: 'Lab 4',
subtitle: 'First Order RC and RL Transients',
icon: Icons.filter_4,
builder: (context) => const Lab4MenuScreen(), // submenu for 4.1 / 4.2
),
_LabItem(
title: 'Lab 5',
subtitle: 'Introduction to AC Signals',
icon: Icons.filter_5,
builder: (context) => const Lab5Screen(),
),
_LabItem(
title: 'Lab 6',
subtitle: 'Frequency Response',
icon: Icons.filter_6,
builder: (context) => const Lab6Screen(),
),
_LabItem(
title: 'Lab 7',
subtitle: 'Op-Amp Integrator and Active Filter',
icon: Icons.filter_7,
builder: (context) => const Lab7Screen(),
),
_LabItem(
title: 'Lab 8',
subtitle: 'Introduction to Logic Gates',
icon: Icons.filter_8,
builder: (context) => const Lab8Screen(),
),
];

return Scaffold(
appBar: AppBar(
title: const Text('Labs'),
actions: [
IconButton(
tooltip: 'Settings',
icon: const Icon(Icons.settings),
onPressed: () => Navigator.pushNamed(context, '/settings'),
),
IconButton(
tooltip: 'Export',
icon: const Icon(Icons.ios_share),
onPressed: () async {
final app = context.read<AppState>();
if ((app.studentEmail ?? '').isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Enter your email in Settings first.')),
);
return;
}
await app.shareExport(context);
},
),
IconButton(
tooltip: 'Open Meter',
icon: const Icon(Icons.speed),
onPressed: () {
final app = context.read<AppState>();
if (!app.deviceConnected) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Connect to use the meter.')),
);
return;
}
app.showMeterOverlay(context);
},
),
],
),
body: ListView.separated(
padding: const EdgeInsets.all(12),
itemCount: items.length,
separatorBuilder: (context, index) => const Divider(height: 1),
itemBuilder: (context, i) {
final it = items[i];
return Card(
child: ListTile(
leading: Icon(it.icon),
title: Text(it.title),
subtitle: it.subtitle != null ? Text(it.subtitle!) : null,
trailing: const Icon(Icons.chevron_right),
onTap: () async {
// 1) Ask for confirmation
final ok = await _confirmPrelab(context);

// 2) Ensure this context is still valid
if (!context.mounted || !ok) return;

// 3) Now it’s safe to use context
Navigator.push(context, MaterialPageRoute(builder: it.builder));
},
),
);
},
),
);
}
}

