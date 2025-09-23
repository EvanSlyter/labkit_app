import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const LabKitApp());

enum AppMode { none, free, lab }

enum ToolRequirement { meter, scope }

class AppState extends ChangeNotifier {
  AppMode mode = AppMode.none;
  bool deviceConnected = false;

  void setMode(AppMode m) {
    mode = m;
    notifyListeners();
  }

  void setDeviceConnected(bool connected) {
    deviceConnected = connected;
    notifyListeners();
  }
}

class LabKitApp extends StatelessWidget {
  const LabKitApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'LabKit',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const Root(),
      ),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    switch (state.mode) {
      case AppMode.none:
        return const ModeSelectScreen();
      case AppMode.free:
        return const FreeModeRoot();
      case AppMode.lab:
        return const LabModeRoot();
    }
  }
}

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('LabKit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Choose a mode',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Lab Mode'),
              subtitle: Text(
                state.deviceConnected
                    ? 'Device connected. Start labs.'
                    : 'Connect to the LabKit before starting labs.',
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  final state = context.read<AppState>();
                  if (!state.deviceConnected) {
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Device not connected'),
                        content: const Text(
                          'You can open Lab Mode now, but some steps require connecting to the LabKit device.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Continue'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              state.setMode(
                                AppMode.free,
                              ); // optional quick path to connect
                            },
                            child: const Text('Go to Connect'),
                          ),
                        ],
                      ),
                    );
                  }
                  state.setMode(AppMode.lab);
                },
                child: const Text('Start'),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Free Mode'),
              subtitle: const Text('Explore tools with tabs (no manual flow).'),
              trailing: ElevatedButton(
                onPressed: () => state.setMode(AppMode.free),
                child: const Text('Start'),
              ),
            ),
            const Spacer(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      state.deviceConnected ? Icons.check_circle : Icons.cancel,
                      color: state.deviceConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.deviceConnected
                            ? 'Connected to device'
                            : 'Not connected',
                      ),
                    ),
                    // Placeholder connect button for testing. Replace with your BLE connect flow.
                    ElevatedButton(
                      onPressed: () {
                        state.setDeviceConnected(!state.deviceConnected);
                      },
                      child: Text(
                        state.deviceConnected ? 'Disconnect' : 'Connect',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================
Free Mode (bottom tabs)
========================== */

class FreeModeRoot extends StatefulWidget {
  const FreeModeRoot({super.key});
  @override
  State<FreeModeRoot> createState() => _FreeModeRootState();
}

class _FreeModeRootState extends State<FreeModeRoot> {
  int _index = 0;

  final _pages = const [
    FreeConnectScreen(),
    MeterScreen(),
    ScopeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LabKit — Free Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<AppState>().setMode(AppMode.none),
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Connect',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Meter'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Scope'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class FreeConnectScreen extends StatelessWidget {
  const FreeConnectScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () {
              // TODO: Replace with BLE scan/connect.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanning… (placeholder)')),
              );
            },
            child: const Text('Scan'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Devices:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: const Text('LabKit-1234'),
                  subtitle: const Text('RSSI: -60'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Placeholder connect toggle
                      context.read<AppState>().setDeviceConnected(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connected (placeholder)'),
                        ),
                      );
                    },
                    child: const Text('Connect'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: const Text('LabKit-5678'),
                  subtitle: const Text('RSSI: -72'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${state.deviceConnected ? 'Connected' : 'Disconnected'}',
          ),
        ],
      ),
    );
  }
}

class MeterScreen extends StatelessWidget {
  const MeterScreen({super.key});

  Widget _metricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
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

class ScopeScreen extends StatelessWidget {
  const ScopeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Capture requested (placeholder)'),
                    ),
                  );
                },
                child: const Text('Capture'),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sample rate: 20 kS/s Points: 2048')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('Chart goes here'),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SwitchListTile(
          title: const Text('Mock data mode'),
          value: true,
          onChanged: (_) {},
        ),
        ListTile(
          leading: Icon(
            state.deviceConnected ? Icons.check_circle : Icons.cancel,
            color: state.deviceConnected ? Colors.green : Colors.red,
          ),
          title: Text(
            state.deviceConnected ? 'Connected to device' : 'Not connected',
          ),
          subtitle: const Text('Real BLE connect goes in the Connect tab.'),
          trailing: ElevatedButton(
            onPressed: () => context.read<AppState>().setDeviceConnected(
              !state.deviceConnected,
            ),
            child: Text(state.deviceConnected ? 'Disconnect' : 'Connect'),
          ),
        ),
      ],
    );
  }
}

/* ==========================
Lab Mode (9 labs, gated)
========================== */

class LabModeRoot extends StatelessWidget {
  const LabModeRoot({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('LabKit — Lab Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<AppState>().setMode(AppMode.none),
        ),
      ),
      body: state.deviceConnected
          ? const LabListScreen()
          : const LabConnectionGate(),
    );
  }
}

class LabConnectionGate extends StatelessWidget {
  const LabConnectionGate({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Connect to the LabKit device to begin the labs.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Placeholder: in real app, navigate to a connect flow or start BLE connect.
                context.read<AppState>().setDeviceConnected(true);
              },
              child: const Text('Connect Device (placeholder)'),
            ),
          ],
        ),
      ),
    );
  }
}

class LabListScreen extends StatelessWidget {
  const LabListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final labs = List.generate(9, (i) => 'Lab ${i + 1}');
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: labs.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (ctx, i) {
        return ListTile(
          leading: const Icon(Icons.menu_book),
          title: Text(labs[i]),
          subtitle: const Text('Tap to open'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LabDetailScreen(labIndex: i + 1),
              ),
            );
          },
        );
      },
    );
  }
}

class LabStep {
  final String title;
  final String text;
  final ToolRequirement? tool;
  LabStep({required this.title, required this.text, this.tool});
}

class LabDetailScreen extends StatelessWidget {
  final int labIndex;
  const LabDetailScreen({super.key, required this.labIndex});

  List<LabStep> _loadSteps(int index) {
    // Placeholder steps; replace with real manual content per lab.
    return [
      LabStep(title: 'Objective', text: 'Understand basic DC measurements.'),
      LabStep(
        title: 'Setup',
        text: 'Connect the circuit as shown in the manual.',
      ),
      LabStep(
        title: 'Measure DC voltage',
        text: 'Use the multimeter to measure Vout.',
        tool: ToolRequirement.meter,
      ),
      LabStep(
        title: 'Observe waveform',
        text: 'Capture a snapshot of the output sine.',
        tool: ToolRequirement.scope,
      ),
      LabStep(
        title: 'Analysis',
        text: 'Compute RMS and compare with theoretical.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final steps = _loadSteps(labIndex);

    return Scaffold(
      appBar: AppBar(title: Text('Lab $labIndex')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: steps.length,
        itemBuilder: (ctx, i) {
          final s = steps[i];
          final needsTool = s.tool != null;
          final connected = state.deviceConnected;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(s.text),
                  if (needsTool) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          s.tool == ToolRequirement.meter
                              ? Icons.speed
                              : Icons.show_chart,
                          color: connected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.tool == ToolRequirement.meter
                                ? 'Requires Multimeter'
                                : 'Requires Oscilloscope Snapshot',
                            style: TextStyle(
                              color: connected ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: connected
                              ? () {
                                  // TODO: open the appropriate tool view or trigger action
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        s.tool == ToolRequirement.meter
                                            ? 'Opening Meter (placeholder)'
                                            : 'Capturing Snapshot (placeholder)',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            s.tool == ToolRequirement.meter
                                ? 'Open Meter'
                                : 'Capture',
                          ),
                        ),
                      ],
                    ),
                    if (!connected)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Connect to the device to use this tool.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Labs'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Placeholder submit/complete step
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress saved (placeholder)')),
                );
              },
              child: const Text('Save Progress'),
            ),
          ],
        ),
      ),
    );
  }
}
