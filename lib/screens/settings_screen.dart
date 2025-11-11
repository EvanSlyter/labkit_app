import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
const SettingsScreen({super.key});
@override
State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
final _emailCtrl = TextEditingController();

@override
void initState() {
super.initState();
final app = context.read<AppState>();
_emailCtrl.text = app.studentEmail ?? '';
// load stored email if not already loaded
app.loadSettings();
}

@override
void dispose() {
_emailCtrl.dispose();
super.dispose();
}

bool _looksLikeEmail(String s) {
final t = s.trim();
return t.contains('@') && t.contains('.') && t.length >= 5;
}

@override
Widget build(BuildContext context) {
final app = context.watch<AppState>();

return Scaffold(
appBar: AppBar(title: const Text('Settings')),
body: ListView(
padding: const EdgeInsets.all(12),
children: [
const Text('Student email (used for export)', style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
TextField(
controller: _emailCtrl,
keyboardType: TextInputType.emailAddress,
decoration: const InputDecoration(hintText: 'name@example.com'),
onChanged: (t) {},
),
const SizedBox(height: 12),
Row(
children: [
ElevatedButton(
onPressed: () async {
final email = _emailCtrl.text.trim();
if (!_looksLikeEmail(email)) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Please enter a valid email.')),
);
return;
}
await app.saveStudentEmail(email);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Saved: ${app.studentEmail}')),
);
},
child: const Text('Save'),
),
const SizedBox(width: 12),
OutlinedButton(
onPressed: () async {
if ((app.studentEmail ?? '').isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Enter and save your email first.')),
);
return;
}
await app.shareExport(context);
},
child: const Text('Export now'),
),
],
),
const SizedBox(height: 24),
const Text(
'Export creates a ZIP with summary.json, tables (CSV), and waveform CSVs. '
'The email composer opens via the share sheet; choose your mail app.',
style: TextStyle(color: Colors.grey),
),
],
),
);
}
}