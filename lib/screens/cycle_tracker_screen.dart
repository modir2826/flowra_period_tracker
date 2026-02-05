import 'package:flutter/material.dart';
import '../models/cycle_model.dart';
import '../services/cycle_service.dart';

class CycleTrackerScreen extends StatefulWidget {
  const CycleTrackerScreen({super.key});

  @override
  State<CycleTrackerScreen> createState() => _CycleTrackerScreenState();
}

class _CycleTrackerScreenState extends State<CycleTrackerScreen> {
  
String _selectedHistoryTab = "All";

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
                  

//history
                  DateTime today = DateTime.now();

                  DateTime? lastPeriod;
                  int cycleLength = 28;
                  int periodLength = 5;

                  if (cycles.isNotEmpty) {
                    lastPeriod = cycles.first.lastPeriodDate;
                    cycleLength = cycles.first.cycleLength;
                    periodLength = cycles.first.periodLength;
                  }

                DateTime? ovulationDate =
                  lastPeriod?.add(Duration(days: cycleLength ~/ 2));

                DateTime? fertileStart =
                  ovulationDate?.subtract(const Duration(days: 3));

                DateTime? fertileEnd =
                ovulationDate?.add(const Duration(days: 1));


                  final avg = _cycleService.averageCycleLength(cycles).toStringAsFixed(1);
                  final predicted = _cycleService.predictNextCycleStart(cycles);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Average cycle length: $avg days'),

                          //add something
                          


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
                     
                      
const SizedBox(height: 16),

// HISTORY CARD
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text("History",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

      const SizedBox(height: 12),

      // TABS
      Row(
        children: ["All", "Period", "Ovulation", "Fertile"].map((tab) {
          final selected = _selectedHistoryTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedHistoryTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? Colors.pink : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),

      const SizedBox(height: 16),

      // ANIMATED BAR
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 18,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              flex: periodLength,
              child: Container(
                decoration: BoxDecoration(
                  color: (_selectedHistoryTab == "Period" ||
                          _selectedHistoryTab == "All")
                      ? Colors.pink.shade400
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                color: (_selectedHistoryTab == "Fertile" ||
                        _selectedHistoryTab == "All")
                    ? Colors.yellow.shade600
                    : Colors.transparent,
              ),
            ),
            Expanded(
              flex: cycleLength - periodLength - 5,
              child: Container(),
            ),
          ],
        ),
      ),
    ],
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
Widget buildHistoryBar(
  DateTime lastPeriod,
  int cycleLength,
  int periodLength,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("History",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),

      Container(
        height: 18,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              flex: periodLength,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.pink.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(color: Colors.yellow.shade600),
            ),
            Expanded(
              flex: cycleLength - periodLength - 5,
              child: Container(),
            ),
          ],
        ),
      ),
    ],
  );
}



