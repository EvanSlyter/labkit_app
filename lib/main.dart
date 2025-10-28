import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'state/app_state.dart'; // or ../../state/app_state.dart from /screens/labs
import 'screens/lab_list_screen.dart';
import 'widgets/meter_screen.dart';


void main() {
WidgetsFlutterBinding.ensureInitialized();
runApp(const LabKitApp());
}

class LabKitApp extends StatelessWidget {
const LabKitApp({super.key});

@override
Widget build(BuildContext context) {
return ChangeNotifierProvider(
create: (_) => AppState(),
child: MaterialApp(
title: 'LabKit',
debugShowCheckedModeBanner: false,
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
useMaterial3: true,
),
// Root is gone; start on the lab list
home: const LabListScreen(),
// Register any named routes you use (Meter in your case)
routes: {
'/meter': (_) => const MeterScreen(),
},
),
);
}
}



