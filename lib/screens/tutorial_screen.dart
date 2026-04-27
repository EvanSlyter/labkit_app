import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/waveform_viewer.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  WaveformData _demoSineWave() {
    const int sampleCount = 512;
    const double sampleRateHz = 2000.0;
    const double freqHz = 10.0;
    const double amplitude = 1.0;
    const double phase = 0.0;

    final twoPi = 2 * math.pi;
    final dt = 1.0 / sampleRateHz;

    final samples = List<double>.generate(
      sampleCount,
      (i) => amplitude * math.sin(twoPi * freqHz * (i * dt) + phase),
    );

    return WaveformData(
      label: 'Tutorial demo sine',
      samples: samples,
      sampleRateHz: sampleRateHz,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = context.watch<AppState>().deviceConnected;

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

          // Op-amp power warning
          SectionCard(
            title: 'Important: Op-amp power rails are always active',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'In this version of LabKit, the op-amp power rails (+5 V / −5 V) are not switchable in the app '
                  'and should be treated as ALWAYS ON whenever the LabKit is powered.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Safety tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                    '• Only ever use the op amp cables (clearly marked on the box) for powering op amps. Never use them to power your circuit.'),
                const Text('• Double-check polarity/orientation before applying input signals.'),
                const Text(
                    '• Ensure the circuit is not powered when connecting or disconnecting probes from the op amp.'),
                const SizedBox(height: 8),
                Text(
                  'Feel free to measure the op amp cables with the multimeter to confirm voltages.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
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
                const Text('1) Tap the download icon next to the text field you want to fill.'),
                const Text('2) The app opens the meter overlay and targets that field.'),
                const Text(
                    '3) Choose the mode (Voltage, Current, Resistance, Capacitance, Inductance).'),
                const Text(
                    '4) When a stable value appears, tap “Insert into field” in the meter overlay.'),
                const SizedBox(height: 8),
                Text(
                  'Tip: You can keep the meter overlay open while you move between lab fields. The download icon tells the meter which field to fill.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: In some labs you may see a meter icon next to multiple fields (e.g., resistor or RMS measurements). Each icon sets a different target for insertion.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Section 3: Oscilloscope demo using WaveformViewer
          SectionCard(
            title: 'Oscilloscope Demo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This demo shows a static, fake sine waveform using the same viewer you will use in the labs.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'In the labs, the waveform will be captured automatically when you press a "Save waveform" button. '
                  'Here you can practice zooming, panning, and reading values from the viewer.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.show_chart),
                    label: const Text('Open oscilloscope demo'),
                    onPressed: () {
                      final demo = _demoSineWave();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WaveformViewer(
                            data: demo,
                            title: 'Oscilloscope Demo',
                            onSaved: null, // view-only demo
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try:\n'
                  '• Adjusting the Window slider to change how many seconds are visible.\n'
                  '• Using the Position slider to pan left/right.\n'
                  '• Using "Save PNG" if available, to capture an image of the waveform.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
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
            Text(
              title,
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}