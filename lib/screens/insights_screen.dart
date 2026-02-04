import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/health_log_service.dart';
import '../services/analytics_service.dart';
import '../services/cycle_service.dart';
import '../services/ai_service.dart';
import '../models/health_log_model.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final HealthLogService _logService = HealthLogService();
  final CycleService _cycleService = CycleService();
  final AnalyticsService _analytics = AnalyticsService();
  final AiService _ai = AiService();

  bool _loading = true;
  List<HealthLogModel> _logs = [];
  Map<String, double> _painCorrelation = {};
  late HealthSummary _summary;
  Map<String, dynamic>? _daily;
  String? _aiResult;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize summary with default values to avoid LateInitializationError
    _summary = HealthSummary(avgMood: 0.0, avgEnergy: 0.0, avgPain: 0.0, totalLogs: 0);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final logs = await _logService.fetchLogsOnce();
      final cycles = await _cycleService.fetchCyclesOnce();
      final summary = _analytics.computeSummary(logs);
      final correlation = _analytics.correlatePainWithCycles(cycles, logs);
      final daily = _analytics.computeDailyAverages(logs, days: 14);

      setState(() {
        _logs = logs;
        _summary = summary;
        _painCorrelation = correlation;
        _daily = daily;
      });
    } catch (e) {
      // ignore errors for now
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateAiInsights() async {
    setState(() {
      _aiLoading = true;
      _aiResult = null;
    });
    try {
      final cycles = await _cycleService.fetchCyclesOnce();
      final result = await _ai.generateInsights(_logs, cycles);
      setState(() => _aiResult = result);
    } catch (e) {
      setState(() => _aiResult = 'Error generating AI insights: $e');
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Insights')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatCard(label: 'Avg Mood', value: _summary.avgMood.toStringAsFixed(1)),
                      _StatCard(label: 'Avg Energy', value: _summary.avgEnergy.toStringAsFixed(1)),
                      _StatCard(label: 'Avg Pain', value: _summary.avgPain.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Trends (14d)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildTrendsChart(),
                  const SizedBox(height: 16),
                  // AI Insights
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _aiLoading ? null : _generateAiInsights,
                      child: _aiLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate AI Insights'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_aiResult != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_aiResult!),
                      ),
                    ),
                  Text('Pain & Period Correlation', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Avg pain during period: ${_painCorrelation['inPeriod']?.toStringAsFixed(1) ?? '0.0'}'),
                          const SizedBox(height: 6),
                          Text('Avg pain outside period: ${_painCorrelation['outPeriod']?.toStringAsFixed(1) ?? '0.0'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Recent Logs', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _logs.isEmpty
                      ? const Center(child: Text('No logs yet'))
                      : Column(
                          children: _logs.take(6).map((l) {
                            return ListTile(
                              title: Text('${l.timestamp.toLocal().toString().split(' ')[0]} — Mood ${l.mood}'),
                              subtitle: Text('Energy ${l.energy} · Pain ${l.painIntensity} · ${l.painLocation}'),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildTrendsChart() {
    if (_daily == null) return const SizedBox.shrink();
    final days = (_daily!['days'] as List<DateTime>);
    final mood = List<double>.from(_daily!['mood'] as List);
    final energy = List<double>.from(_daily!['energy'] as List);
    final pain = List<double>.from(_daily!['pain'] as List);

    List<FlSpot> spots(List<double> data) {
      return List<FlSpot>.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    }

    final moodSpots = spots(mood);
    final energySpots = spots(energy);
    final painSpots = spots(pain);

    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2, getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                  final d = days[idx];
                  return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10));
                })),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              ),
              lineBarsData: [
                LineChartBarData(spots: moodSpots, isCurved: true, color: Colors.purple, barWidth: 2),
                LineChartBarData(spots: energySpots, isCurved: true, color: Colors.orange, barWidth: 2),
                LineChartBarData(spots: painSpots, isCurved: true, color: Colors.red, barWidth: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
