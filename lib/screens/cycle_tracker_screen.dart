import 'package:flutter/material.dart';
import '../models/cycle_model.dart';

class CycleTrackerScreen extends StatelessWidget {
  const CycleTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cycle = CycleModel(
      lastPeriodDate: DateTime.now().subtract(const Duration(days: 5)),
      cycleLength: 28,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Cycle Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Last Period: ${cycle.lastPeriodDate.toLocal().toString().split(' ')[0]}",
            ),
            const SizedBox(height: 12),
            Text(
              "Next Expected Period: ${cycle.nextPeriodDate.toLocal().toString().split(' ')[0]}",
            ),
          ],
        ),
      ),
    );
  }
}
