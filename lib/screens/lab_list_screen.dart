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

class LabListScreen extends StatelessWidget {
const LabListScreen({super.key});



@override
Widget build(BuildContext context) {
final items = <_LabItem>[
_LabItem(
title: 'Lab 1',
subtitle: 'Basic measurements and procedure',
icon: Icons.filter_1,
builder: (context) => const Lab1Screen(),
),
_LabItem(
title: 'Lab 2',
subtitle: 'Node voltages and equivalent circuits',
icon: Icons.filter_2,
builder: (context) => const Lab2Screen(),
),
_LabItem(
title: 'Lab 3',
subtitle: 'RC circuit: DC/AC, scaling, time shift',
icon: Icons.filter_3,
builder: (context) => const Lab3Screen(),
),
_LabItem(
title: 'Lab 4',
subtitle: 'Select 4.1 (RC) or 4.2 (RL)',
icon: Icons.filter_4,
builder: (context) => const Lab4MenuScreen(), // submenu for 4.1 / 4.2
),
_LabItem(
title: 'Lab 5',
subtitle: 'Potentiometer and phase shift',
icon: Icons.filter_5,
builder: (context) => const Lab5Screen(),
),
_LabItem(
title: 'Lab 6',
subtitle: 'Frequency response and Bode plot',
icon: Icons.filter_6,
builder: (context) => const Lab6Screen(),
),
_LabItem(
title: 'Lab 7',
subtitle: 'Op-amp with sine/square/triangle',
icon: Icons.filter_7,
builder: (context) => const Lab7Screen(),
),
_LabItem(
title: 'Lab 8',
subtitle: 'Logic gates and truth tables',
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
onTap: () {
Navigator.push(
context,
MaterialPageRoute(builder: it.builder),
);
},
),
);
},
),
);
}
}

