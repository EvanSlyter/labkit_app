import 'package:flutter/material.dart';

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
                    const SnackBar(content: Text('Capture requested (placeholder)')),
                  );
                },
                child: const Text('Capture'),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sample rate: 20 kS/s   Points: 2048')),
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