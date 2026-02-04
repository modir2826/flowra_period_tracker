import 'package:flutter/material.dart';
import 'cycle_tracker_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flowra 🌸")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Open Cycle Tracker"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CycleTrackerScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
