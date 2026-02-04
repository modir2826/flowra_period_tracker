import 'package:flutter/material.dart';
import '../models/cycle_model.dart';
import '../services/cycle_service.dart';

class CycleTrackerScreen extends StatefulWidget {
  const CycleTrackerScreen({super.key});

  @override
  State<CycleTrackerScreen> createState() => _CycleTrackerScreenState();
}

class _CycleTrackerScreenState extends State<CycleTrackerScreen> {
  final CycleService _cycleService = CycleService();

  DateTime? _pickedDate;
  int _periodLength = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your cycles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Stream of cycles
            Expanded(
              child: StreamBuilder<List<CycleModel>>(
                stream: _cycleService.streamCycles(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cycles = snap.data ?? [];

                  final avg = _cycleService.averageCycleLength(cycles).toStringAsFixed(1);
                  final predicted = _cycleService.predictNextCycleStart(cycles);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Average cycle length: $avg days'),
                          if (predicted != null)
                            Text('Next: ${predicted.toLocal().toString().split(' ')[0]}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: cycles.isEmpty
                            ? const Center(child: Text('No cycles recorded yet'))
                            : ListView.builder(
                                itemCount: cycles.length,
                                itemBuilder: (context, idx) {
                                  final c = cycles[idx];
                                  return Card(
                                    child: ListTile(
                                      title: Text('Start: ${c.lastPeriodDate.toLocal().toString().split(' ')[0]}'),
                                      subtitle: Text('Cycle: ${c.cycleLength} days · Period: ${c.periodLength} days'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          if (c.id != null) await _cycleService.deleteCycle(c.id!);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Add new cycle
            const SizedBox(height: 8),
            const Text('Add new period start', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year - 2),
                        lastDate: now,
                      );
                      if (picked != null) setState(() => _pickedDate = picked);
                    },
                    child: Text(_pickedDate == null ? 'Pick start date' : _pickedDate!.toLocal().toString().split(' ')[0]),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Period days'),
                    onChanged: (v) {
                      final parsed = int.tryParse(v) ?? 5;
                      setState(() => _periodLength = parsed.clamp(1, 14));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pickedDate == null
                    ? null
                    : () async {
                        final last = _pickedDate!;
                        // compute cycle length using last recorded cycle if available
                        final existing = await _cycleService.fetchCyclesOnce();
                        int cycleLen = 28;
                        if (existing.isNotEmpty) {
                          final mostRecent = existing.first;
                          cycleLen = last.difference(mostRecent.lastPeriodDate).inDays;
                        }

                        final model = CycleModel(
                          lastPeriodDate: last,
                          cycleLength: cycleLen,
                          periodLength: _periodLength,
                        );

                        await _cycleService.addCycle(model);
                        setState(() => _pickedDate = null);
                      },
                child: const Text('Save Period Start'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
