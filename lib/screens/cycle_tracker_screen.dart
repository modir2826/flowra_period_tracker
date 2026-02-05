import 'package:flutter/material.dart';
import '../models/cycle_model.dart';
import '../services/cycle_service.dart';
import '../widgets/card_container.dart';
import '../widgets/primary_button.dart';
import 'sos_screen.dart';

class CycleTrackerScreen extends StatefulWidget {
  const CycleTrackerScreen({super.key});

  @override
  State<CycleTrackerScreen> createState() => _CycleTrackerScreenState();
}

class _CycleTrackerScreenState extends State<CycleTrackerScreen> {
  final CycleService _cycleService = CycleService();

  DateTime? _pickedDate;
  int _periodLength = 5;

  Future<void> _confirmSave() async {
    if (_pickedDate == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Save'),
        content: Text('Save period starting ${_pickedDate!.toLocal().toString().split(' ')[0]} with $_periodLength day(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
        await _savePeriod(_pickedDate!); // Extracted save logic
    }
  }

  Future<void> _savePeriod(DateTime start) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final existing = await _cycleService.fetchCyclesOnce();
      int cycleLen = 28;
      if (existing.isNotEmpty) {
        cycleLen = start.difference(existing.first.startDate).inDays;
        if (cycleLen <= 0) cycleLen = 28; // fallback for bad dates
      }
      final model = CycleModel(startDate: start, cycleLength: cycleLen, periodLength: _periodLength);
      await _cycleService.addCycle(model);
      if (!mounted) return;
      setState(() => _pickedDate = null);
      messenger.showSnackBar(const SnackBar(content: Text('Period saved!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed to save period: ${e.toString()}'), backgroundColor: Colors.red.shade700));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Cycles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CardContainer(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<List<CycleModel>>(
                stream: _cycleService.streamCycles(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Average Cycle', style: Theme.of(context).textTheme.bodySmall),
                              Text('$avg days', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (predicted != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Next Period', style: Theme.of(context).textTheme.bodySmall),
                                Text(predicted.toLocal().toString().split(' ')[0], style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            )
                          else
                            Text('No data yet', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent Cycles', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<List<CycleModel>>(
              stream: _cycleService.streamCycles(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                }
                final cycles = snap.data ?? [];
                if (cycles.isEmpty) {
                  return CardContainer(
                    child: Center(child: Text('No cycles recorded yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey))),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cycles.length,
                  itemBuilder: (context, idx) {
                    final c = cycles[idx];
                    return CardContainer(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start: ${c.startDate.toLocal().toString().split(' ')[0]}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${c.cycleLength}d cycle · ${c.periodLength}d period', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => c.id != null ? _cycleService.deleteCycle(c.id!) : null,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Add New Period', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_pickedDate == null ? 'Pick start date' : _pickedDate!.toLocal().toString().split(' ')[0]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Period days ($_periodLength)', hintText: 'e.g. 5'),
                    onChanged: (v) {
                      final parsed = int.tryParse(v) ?? 5;
                      setState(() => _periodLength = parsed.clamp(1, 14));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Save Period Start',
              onPressed: _pickedDate == null ? null : _confirmSave,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen()));
        },
        backgroundColor: Colors.red.shade600,
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
