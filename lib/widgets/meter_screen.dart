import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/connection_warning.dart';


class MeterScreen extends StatefulWidget {
  const MeterScreen({super.key});
  @override
  State<MeterScreen> createState() => _MeterScreenState();
}

class _MeterScreenState extends State<MeterScreen> {
  @override
  void initState() {
    super.initState();
    // Optional: ensure the meter is enabled and configured on first open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      if (!app.meterEnabled) {
        app.sendMeterConfigure(app.meterMode); // starts "waiting" state
      }
    });
  }

  // Thresholds for “significant” readings (tune as needed)
  bool _isSignificant(AppState app) {
    final v = app.meterReading;
    if (v == null) return false;
    final a = v.abs();
    switch (app.meterMode) {
      case MeterMode.voltage:
        return a >= 1e-3; // ≥ 1 mV
      case MeterMode.resistance:
        return a >= 0.5; // ≥ 0.5 Ω
      case MeterMode.capacitance:
        return a >= 1e-9; // ≥ 1 nF
      case MeterMode.inductance:
        return a >= 1e-6; // ≥ 1 µH
    }
  }

  // Format numbers with SI prefixes and units
  String _formatReading(AppState app) {
    final value = app.meterReading ?? 0.0;
    final unit = switch (app.meterMode) {
      MeterMode.voltage => 'V',
      MeterMode.resistance => 'Ω',
      MeterMode.capacitance => 'F',
      MeterMode.inductance => 'H',
    };
    return _formatSI(value, unit);
  }

  String _formatSI(double x, String unit) {
    final ax = x.abs();
    String prefix;
    double scaled;
    if (ax >= 1e6) {
      prefix = 'M';
      scaled = x / 1e6;
    } else if (ax >= 1e3) {
      prefix = 'k';
      scaled = x / 1e3;
    } else if (ax >= 1.0) {
      prefix = '';
      scaled = x;
    } else if (ax >= 1e-3) {
      prefix = 'm';
      scaled = x * 1e3;
    } else if (ax >= 1e-6) {
      prefix = 'µ';
      scaled = x * 1e6;
    } else if (ax >= 1e-9) {
      prefix = 'n';
      scaled = x * 1e9;
    } else {
      prefix = 'p';
      scaled = x * 1e12;
    }
    // Choose decimals based on magnitude
    final str = (scaled.abs() >= 100)
        ? scaled.toStringAsFixed(0)
        : (scaled.abs() >= 10)
        ? scaled.toStringAsFixed(1)
        : scaled.toStringAsFixed(3);
    return '$str $prefix$unit';
  }

  // Mode selector chip
  Widget _modeChip({
    required AppState app,
    required MeterMode mode,
    required String label,
    required IconData icon,
  }) {
    final selected = app.meterMode == mode;
    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      onSelected: (v) {
        if (v) app.setMeterMode(mode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = app.deviceConnected;

    String headline;
    String subline = '';
    if (!app.meterEnabled) {
      headline = 'Meter off';
      if (!connected) subline = 'Connect to the device to take measurements.';
    } else if (!_isSignificant(app)) {
      headline = 'Meter on: waiting for stable reading…';
      if (!connected)
        subline = 'Note: not connected — showing mock/wait state.';
    } else {
      headline = _formatReading(app);
      final t = app.meterReadingAt;
      if (t != null) {
        subline = 'Updated ${TimeOfDay.fromDateTime(t).format(context)}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meter'),
        actions: [
          if (app.meterEnabled)
            TextButton(
              onPressed: () => app.sendMeterStop(),
              child: const Text('Stop', style: TextStyle(color: Colors.white)),
            )
          else
            TextButton(
              onPressed: () => app.sendMeterConfigure(app.meterMode),
              child: const Text('Start', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!connected) const ConnectionWarning(),

          // Mode selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _modeChip(
                    app: app,
                    mode: MeterMode.voltage,
                    label: 'Voltage',
                    icon: Icons.bolt,
                  ),
                  _modeChip(
                    app: app,
                    mode: MeterMode.resistance,
                    label: 'Resistance',
                    icon: Icons.speed,
                  ),
                  _modeChip(
                    app: app,
                    mode: MeterMode.capacitance,
                    label: 'Capacitance',
                    icon: Icons.sensors,
                  ),
                  _modeChip(
                    app: app,
                    mode: MeterMode.inductance,
                    label: 'Inductance',
                    icon: Icons.auto_graph,
                  ),
                ],
              ),
            ),
          ),

          // Big reading display
          Card(
            child: Container(
              height: 160,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: app.meterEnabled && _isSignificant(app)
                          ? 44
                          : 20,
                      fontWeight: app.meterEnabled && _isSignificant(app)
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (subline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(subline, style: const TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
            ),
          ),

          // Small hint line
          const SizedBox(height: 8),
          const Text(
            'Tip: Select a measurement mode first. The display updates automatically when data arrives.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}