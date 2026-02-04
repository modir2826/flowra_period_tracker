import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/health_log_service.dart';
import '../services/analytics_service.dart';
import '../services/cycle_service.dart';
import '../services/ai_service.dart';
import '../models/health_log_model.dart';
import '../widgets/card_container.dart';
import 'sos_screen.dart';

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
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with refresh button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary Stats
                  Text('Summary (Last 14 days)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatCard(
                        label: 'Mood',
                        value: _summary.avgMood.toStringAsFixed(1),
                        icon: '😊',
                        color: Colors.purple,
                      ),
                      _StatCard(
                        label: 'Energy',
                        value: _summary.avgEnergy.toStringAsFixed(1),
                        icon: '⚡',
                        color: Colors.orange,
                      ),
                      _StatCard(
                        label: 'Pain',
                        value: _summary.avgPain.toStringAsFixed(1),
                        icon: '💔',
                        color: Colors.red,
                      ),
                      _StatCard(
                        label: 'Logs',
                        value: _summary.totalLogs.toString(),
                        icon: '📊',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Trends Chart
                  Text('14-Day Trends', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTrendsChart(),
                  const SizedBox(height: 24),

                  // Pain & Period Correlation
                  Text('Period Pain Analysis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildPainCorrelationWidget(),
                  const SizedBox(height: 24),

                  // Health Recommendations
                  Text('Wellness Recommendations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRecommendations(),
                  const SizedBox(height: 24),

                  // AI Insights
                  Text('AI-Powered Insights', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _aiLoading ? null : _generateAiInsights,
                      icon: _aiLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                      label: Text(_aiLoading ? 'Generating...' : 'Get AI Insights'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_aiResult != null)
                    CardContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text('AI Analysis', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _aiResult!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Recent Logs
                  Text('Recent Logs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _logs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No logs yet. Start logging to see insights!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          children: _logs.take(8).map((l) {
                            return CardContainer(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.timestamp.toLocal().toString().split(' ')[0],
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${l.painLocation.isNotEmpty ? l.painLocation : 'General'} discomfort',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          Text('${l.mood}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Text('😊', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text('${l.energy}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Text('⚡', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text('${l.painIntensity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Text('💔', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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
        label: const Text('Emergency SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPainCorrelationWidget() {
    final inPeriod = _painCorrelation['inPeriod'] ?? 0.0;
    final outPeriod = _painCorrelation['outPeriod'] ?? 0.0;
    final difference = (inPeriod - outPeriod).abs();

    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('During Period', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(
                      inPeriod.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.pink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outside Period', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(
                      outPeriod.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: inPeriod > 0 ? (inPeriod / 10) : 0,
              minHeight: 8,
              backgroundColor: Colors.pink.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            inPeriod > outPeriod
                ? '${difference.toStringAsFixed(1)} higher during period'
                : '${difference.toStringAsFixed(1)} lower during period',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: inPeriod > outPeriod ? Colors.red.shade600 : Colors.green.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = <Map<String, String>>[];

    if (_summary.avgMood < 4) {
      recommendations.add({
        'emoji': '🧘',
        'title': 'Boost Your Mood',
        'tip': 'Try meditation, yoga, or time in nature. Your mood tends to be lower recently.',
      });
    }
    if (_summary.avgEnergy < 4) {
      recommendations.add({
        'emoji': '😴',
        'title': 'Get More Rest',
        'tip': 'Your energy levels are low. Ensure 7-9 hours of sleep and stay hydrated.',
      });
    }
    if (_summary.avgPain > 5) {
      recommendations.add({
        'emoji': '🌡️',
        'title': 'Manage Pain',
        'tip': 'Consider heat therapy, light exercise, or consult a healthcare provider.',
      });
    }
    if (_summary.totalLogs < 5) {
      recommendations.add({
        'emoji': '📝',
        'title': 'Log More Data',
        'tip': 'Consistent logging helps with better insights and predictions.',
      });
    }

    if (recommendations.isEmpty) {
      recommendations.add({
        'emoji': '✨',
        'title': 'Great Job!',
        'tip': 'You\'re tracking consistently. Keep it up for better insights!',
      });
    }

    return Column(
      children: recommendations.map((rec) {
        return CardContainer(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rec['emoji']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(rec['tip']!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CardContainer(
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
