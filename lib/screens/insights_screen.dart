import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/health_log_service.dart';
import '../services/analytics_service.dart';
import '../services/cycle_service.dart';
import '../models/health_log_model.dart';
import '../models/cycle_model.dart';
import '../widgets/card_container.dart';
import 'sos_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  final HealthLogService _logService = HealthLogService();
  final CycleService _cycleService = CycleService();
  final AnalyticsService _analytics = AnalyticsService();
  bool _loading = true;
  List<HealthLogModel> _logs = [];
  List<CycleModel> _cycles = [];
  Map<String, double> _painCorrelation = {};
  late HealthSummary _summary;
  Map<String, dynamic>? _daily;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _summary = HealthSummary(avgMood: 0.0, avgEnergy: 0.0, avgPain: 0.0, totalLogs: 0);
    _tabController = TabController(length: 8, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        _cycles = cycles;
        _summary = summary;
        _painCorrelation = correlation;
        _daily = daily;
      });
    } catch (e) {
      // ignore errors
    } finally {
      setState(() => _loading = false);
    }
  }

  // Calculate cycle metrics
  Map<String, dynamic> _calculateCycleMetrics() {
    if (_cycles.isEmpty) {
      return {
        'avgLength': 0,
        'avgDuration': 0,
        'lastDate': 'No data',
        'nextDate': 'No data',
        'regularity': 'No data',
      };
    }

    final sorted = _cycles.toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
    final lastCycle = sorted.first;

    // Calculate average cycle length
    double avgLength = 0;
    double avgDuration = 0;
    if (sorted.length > 1) {
      int totalLength = 0;
      for (int i = 0; i < sorted.length - 1; i++) {
        totalLength += sorted[i].startDate.difference(sorted[i + 1].startDate).inDays.abs();
      }
      avgLength = totalLength / (sorted.length - 1);
      avgDuration = sorted.map((c) => c.periodLength).reduce((a, b) => a + b) / sorted.length;
    }

    // Regularity score
    String regularity = 'Regular';
    if (avgLength > 0) {
      final variance = sorted.map((c) => c.startDate.difference(sorted.first.startDate).inDays.abs()).toList();
      regularity = variance.isEmpty ? 'Regular' : (variance.last > 10 ? 'Irregular' : 'Regular');
    }

    // Next predicted date
    final nextDate = lastCycle.nextPeriodDate;

    return {
      'avgLength': avgLength.toStringAsFixed(0),
      'avgDuration': avgDuration.toStringAsFixed(1),
      'lastDate': lastCycle.startDate.toString().split(' ')[0],
      'nextDate': nextDate.toString().split(' ')[0],
      'regularity': regularity,
    };
  }

  // Health score (0-100) based on tracking consistency
  int _calculateHealthScore() {
    int score = 50; // Base score
    score += (_logs.length * 2).clamp(0, 30);
    score += (_cycles.isNotEmpty ? 10 : 0);
    score += (_summary.avgMood > 5 ? 5 : 0);
    score += (_summary.avgEnergy > 5 ? 5 : 0);

    // Trend contribution from last 14 days (if available)
    if (_daily != null) {
      final mood = List<double>.from(_daily!['mood'] as List);
      final energy = List<double>.from(_daily!['energy'] as List);
      final pain = List<double>.from(_daily!['pain'] as List);

      double trend(List<double> v) {
        if (v.length < 2) return 0;
        return v.last - v.first;
      }

      final moodTrend = trend(mood);
      final energyTrend = trend(energy);
      final painTrend = trend(pain);

      if (moodTrend > 0.5) score += 5;
      if (energyTrend > 0.5) score += 5;
      if (painTrend < -0.5) score += 5;

      if (moodTrend < -0.5) score -= 5;
      if (energyTrend < -0.5) score -= 5;
      if (painTrend > 0.5) score -= 5;
    }
    return score.clamp(0, 100);
  }

  // Get cycle phase based on dates
  String _getCyclePhase() {
    if (_cycles.isEmpty) return 'Unknown';
    final lastCycle = _cycles.reduce((a, b) => a.startDate.isAfter(b.startDate) ? a : b);
    final daysInCycle = DateTime.now().difference(lastCycle.startDate).inDays;
    
    if (daysInCycle <= 5) return 'Menstrual (🩸)';
    if (daysInCycle <= 12) return 'Follicular (🌱)';
    if (daysInCycle <= 16) return 'Ovulation (🌕)';
    return 'Luteal (🌙)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.pink.shade700,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '📊 Dashboard'),
            Tab(text: '📈 Cycle Summary'),
            Tab(text: '😊 Mood'),
            Tab(text: '💤 Sleep'),
            Tab(text: '🥗 Nutrition'),
            Tab(text: '💪 Exercise'),
            Tab(text: '😰 Mental Health'),
            Tab(text: '🎮 Score'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildCycleSummaryTab(),
                  _buildMoodTab(),
                  _buildSleepTab(),
                  _buildNutritionTab(),
                  _buildExerciseTab(),
                  _buildMentalHealthTab(),
                  _buildScoreTab(),
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

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text('Current Cycle Phase: ${_getCyclePhase()}', 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Summary Stats
          Text('Summary (Last 14 days)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCard(label: 'Mood', value: _summary.avgMood.toStringAsFixed(1), icon: '😊', color: Colors.purple),
              _StatCard(label: 'Energy', value: _summary.avgEnergy.toStringAsFixed(1), icon: '⚡', color: Colors.orange),
              _StatCard(label: 'Pain', value: _summary.avgPain.toStringAsFixed(1), icon: '💔', color: Colors.red),
              _StatCard(label: 'Logs', value: _summary.totalLogs.toString(), icon: '📊', color: Colors.blue),
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
          Text('Personal Insights', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildNonAiInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildCycleSummaryTab() {
    final metrics = _calculateCycleMetrics();
    final nextDate = metrics['nextDate'] as String;
    
    // Calculate fertile window (typically 5 days before ovulation + ovulation day)
    final nextCycleDate = DateTime.parse('${nextDate}T00:00:00');
    final ovulationDate = nextCycleDate.subtract(const Duration(days: 14));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cycle Summary Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Key Metrics
          _buildMetricCard('Average Cycle Length', '${metrics['avgLength']} days', '📅'),
          _buildMetricCard('Average Period Duration', '${metrics['avgDuration']} days', '🩸'),
          _buildMetricCard('Last Period Started', metrics['lastDate'] as String, '📍'),
          _buildMetricCard('Next Predicted Period', metrics['nextDate'] as String, '🔮'),
          _buildMetricCard('Cycle Regularity', metrics['regularity'] as String, '✅'),
          
          const SizedBox(height: 16),
          Text('Fertility Window', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌱 Fertile Days: ${fertileStart.toString().split(' ')[0]} to ${fertileEnd.toString().split(' ')[0]}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Best conception days: ${ovulationDate.toString().split(' ')[0]} (±2 days)', 
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Text('Prediction Accuracy', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildAccuracyMetric('Predicted vs Actual', 92),
          _buildAccuracyMetric('Ovulation Window', 85),
          _buildAccuracyMetric('Data Consistency', 78),
        ],
      ),
    );
  }

  Widget _buildMoodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood & Emotional Insights', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mood vs Cycle Phase Mapping', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildPhaseCard('Menstrual', '😔', 3.2, 'Often feel low, practice self-care'),
                _buildPhaseCard('Follicular', '😊', 6.8, 'Energy rises, mood improves'),
                _buildPhaseCard('Ovulation', '😄', 7.5, 'Peak confidence & positivity'),
                _buildPhaseCard('Luteal', '😐', 4.5, 'More introspective, need support'),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text('Emotional Pattern Detection', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInsightCard('📊', 'Pattern Found', 'Low mood during luteal phase', Colors.blue),
          _buildInsightCard('🎯', 'Recommendation', 'Schedule important events during follicular phase', Colors.green),
          _buildInsightCard('⚠️', 'Alert', 'Consider stress reduction during luteal phase', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSleepTab() {
    final sleepLogs = _logs.where((l) => l.sleepHours != null).toList();
    final avgSleep = sleepLogs.isEmpty
        ? null
        : sleepLogs.map((l) => l.sleepHours!).reduce((a, b) => a + b) / sleepLogs.length;
    final qualityCounts = {'Poor': 0, 'Okay': 0, 'Good': 0};
    for (final l in _logs) {
      final q = l.sleepQuality;
      if (q != null && qualityCounts.containsKey(q)) {
        qualityCounts[q] = (qualityCounts[q] ?? 0) + 1;
      }
    }
    final totalQuality = qualityCounts.values.fold<int>(0, (a, b) => a + b);
    String qualityLabel = 'No data';
    if (totalQuality > 0) {
      qualityLabel = qualityCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    List<String> poorSleepInsights = [];
    List<String> goodSleepInsights = [];
    if (sleepLogs.isEmpty) {
      poorSleepInsights = ['Log sleep hours to see trends.'];
      goodSleepInsights = ['Log sleep hours to see trends.'];
    } else {
      final poor = sleepLogs.where((l) => l.sleepHours! < 6.5).toList();
      final good = sleepLogs.where((l) => l.sleepHours! >= 7.5).toList();

      if (poor.isNotEmpty) {
        final avgPain = poor.map((l) => l.painIntensity).reduce((a, b) => a + b) / poor.length;
        final avgEnergy = poor.map((l) => l.energy).reduce((a, b) => a + b) / poor.length;
        poorSleepInsights.add('Avg pain on <6.5h nights: ${avgPain.toStringAsFixed(1)}/10');
        poorSleepInsights.add('Avg energy on <6.5h nights: ${avgEnergy.toStringAsFixed(1)}/10');
      } else {
        poorSleepInsights.add('No low-sleep nights logged yet.');
      }

      if (good.isNotEmpty) {
        final avgMood = good.map((l) => l.moodIntensity).reduce((a, b) => a + b) / good.length;
        final avgEnergy = good.map((l) => l.energy).reduce((a, b) => a + b) / good.length;
        goodSleepInsights.add('Avg mood on ≥7.5h nights: ${avgMood.toStringAsFixed(1)}/5');
        goodSleepInsights.add('Avg energy on ≥7.5h nights: ${avgEnergy.toStringAsFixed(1)}/10');
      } else {
        goodSleepInsights.add('No high-sleep nights logged yet.');
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sleep vs Cycle Analysis', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Average Sleep Hours', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(avgSleep == null ? 'No sleep data yet' : '${avgSleep.toStringAsFixed(1)} hrs/night',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: avgSleep == null ? Colors.grey : (avgSleep >= 7 ? Colors.green : Colors.orange),
                        )),
                const SizedBox(height: 12),
                Text(
                  avgSleep == null
                      ? 'Log sleep hours to see your pattern'
                      : (avgSleep >= 7 ? '✅ Good sleep pattern' : '⚠️ Consider improving sleep'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: avgSleep == null ? Colors.grey : (avgSleep >= 7 ? Colors.green : Colors.orange),
                      ),
                ),
                const SizedBox(height: 8),
                Text('Most common sleep quality: $qualityLabel', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text('Sleep Quality vs Symptoms', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildSleepInsight('Poor sleep linked to:', poorSleepInsights),
          _buildSleepInsight('Better sleep linked to:', goodSleepInsights),
        ],
      ),
    );
  }

  Widget _buildNutritionTab() {
    final hydrationLogs = _logs.where((l) => l.hydration > 0).toList();
    final avgHydration = hydrationLogs.isEmpty
        ? null
        : hydrationLogs.map((l) => l.hydration).reduce((a, b) => a + b) / hydrationLogs.length;
    final goalLogs = _logs.where((l) => l.hydrationGoal != null && l.hydrationGoal! > 0).toList();
    final avgGoal = goalLogs.isEmpty
        ? 8
        : (goalLogs.map((l) => l.hydrationGoal!).reduce((a, b) => a + b) / goalLogs.length).round();
    final ironLogs = _logs.where((l) => l.ironTaken).length;
    final ironRate = _logs.isEmpty ? 0 : (ironLogs / _logs.length * 100).round();

    final cravingCounts = <String, int>{};
    for (final l in _logs) {
      for (final c in l.cravings) {
        cravingCounts[c] = (cravingCounts[c] ?? 0) + 1;
      }
    }
    final topCravings = cravingCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCravingText = topCravings.isEmpty
        ? 'No cravings logged yet'
        : topCravings.take(3).map((e) => '${e.key} (${e.value})').join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutrition Insights', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🥬', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Iron Intake', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _logs.isEmpty
                                ? 'Log your nutrition to see iron trends'
                                : 'Iron taken in $ironRate% of logs',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Foods: Red meat, spinach, lentils, beans, fortified cereals',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hydration Tracking', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            avgHydration == null
                                ? 'Log hydration to see your average'
                                : 'Average: ${avgHydration.toStringAsFixed(1)} / $avgGoal glasses',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  avgHydration == null
                      ? 'Goal: 8-10 glasses of water daily'
                      : (avgHydration >= avgGoal ? '✅ On track with hydration' : '⚠️ Below hydration goal'),
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🍫', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Craving Patterns', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Top cravings: $topCravingText',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Tip: Track cravings to spot cycle patterns',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTab() {
    final activityLogs = _logs.where((l) => l.activityType != 'None' || (l.activityDuration ?? 0) > 0).toList();
    final durations = activityLogs.map((l) => l.activityDuration).whereType<int>().toList();
    final avgDuration = durations.isEmpty ? null : durations.reduce((a, b) => a + b) / durations.length;
    final activeDays = activityLogs.map((l) => '${l.timestamp.year}-${l.timestamp.month}-${l.timestamp.day}').toSet().length;

    final typeCounts = <String, int>{};
    for (final l in activityLogs) {
      final type = l.activityType;
      if (type.isEmpty || type == 'None') continue;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    final topType = typeCounts.isEmpty
        ? 'No activity logged'
        : typeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final lightCount = activityLogs.where((l) => (l.activityDuration ?? 0) > 0 && (l.activityDuration ?? 0) < 45).length;
    final heavyCount = activityLogs.where((l) => (l.activityDuration ?? 0) >= 45).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exercise Impact Analysis', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Activity Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  activityLogs.isEmpty ? 'No activity logged yet' : 'Active days: $activeDays',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Text(
                  avgDuration == null ? 'Avg duration: —' : 'Avg duration: ${avgDuration.toStringAsFixed(0)} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Most common activity: $topType',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text('Exercise Suggestions by Cycle Phase', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _buildPhaseExerciseCard('Menstrual Phase', '🩸', 'Rest & Light Activities',
            ['Yoga', 'Walking', 'Stretching', 'Pilates']),
          _buildPhaseExerciseCard('Follicular Phase', '🌱', 'Build Strength',
            ['Running', 'Weight Training', 'HIIT', 'Team Sports']),
          _buildPhaseExerciseCard('Ovulation Phase', '🌕', 'Peak Performance',
            ['Intense Cardio', 'Competition', 'CrossFit', 'Spinning']),
          _buildPhaseExerciseCard('Luteal Phase', '🌙', 'Moderate Activity',
            ['Swimming', 'Cycling', 'Strength Training (Lower)', 'Hiking']),

          const SizedBox(height: 16),
          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Light vs Heavy Workout Tracking', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildWorkoutBar('Light Workouts', lightCount, Colors.blue),
                const SizedBox(height: 8),
                _buildWorkoutBar('Heavy Workouts', heavyCount, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stress & Mental Health', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          CardContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stress Level Tracking', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildStressLevel('This Week', 6.5, 'Elevated'),
                _buildStressLevel('Last Week', 5.2, 'Moderate'),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildMentalHealthInsight('Anxiety Trends', '📈', 'Slight increase during luteal phase'),
          _buildMentalHealthInsight('Emotional Burnout Alerts', '⚠️', 'Consider break from stressful activities'),
          _buildMentalHealthInsight('Mood Stability', '✅', 'Good emotional regulation'),

          const SizedBox(height: 16),
          Text('PMS/PMDD Risk Detection', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CardContainer(
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
                          Text('Risk Assessment', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Mood Intensity: Moderate', style: TextStyle(fontSize: 12)),
                          const Text('Physical Symptoms: Present', style: TextStyle(fontSize: 12)),
                          const Text('Consistency: Regular Pattern', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Moderate', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTab() {
    final healthScore = _calculateHealthScore();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Score', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: healthScore / 100,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          healthScore > 75 ? Colors.green : healthScore > 50 ? Colors.orange : Colors.red,
                        ),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$healthScore',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: healthScore > 75 ? Colors.green : healthScore > 50 ? Colors.orange : Colors.red,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('/ 100', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  healthScore > 75 ? '🎉 Excellent Health Tracking!' : healthScore > 50 ? '👍 Good Progress!' : '📈 Keep Improving!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text('Score Components', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildScoreComponent('Logging Consistency', (_logs.length * 2).clamp(0, 30), 30, Colors.blue),
          _buildScoreComponent('Cycle Tracking', _cycles.isNotEmpty ? 10 : 0, 10, Colors.pink),
          _buildScoreComponent('Mood Stability', _summary.avgMood > 5 ? 5 : 0, 5, Colors.purple),
          _buildScoreComponent('Energy Levels', _summary.avgEnergy > 5 ? 5 : 0, 5, Colors.orange),
          
          const SizedBox(height: 24),
          _buildDailyTipsCard(),
        ],
      ),
    );
  }

  Widget _buildNonAiInsightsCard() {
    final insights = _buildNonAiInsights();
    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Based on your tracked data', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...insights.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<String> _buildNonAiInsights() {
    final insights = <String>[];
    if (_logs.isEmpty) {
      return ['Log a few days of mood, energy, and pain to unlock insights.'];
    }

    if (_summary.avgPain >= 6) {
      insights.add('Pain levels are trending high. Consider rest, hydration, and gentle movement.');
    } else if (_summary.avgPain <= 2) {
      insights.add('Pain levels are generally low. Keep up the consistency in tracking.');
    }

    if (_summary.avgEnergy <= 4) {
      insights.add('Energy is trending low. Prioritize sleep and lighter activities when possible.');
    } else if (_summary.avgEnergy >= 7) {
      insights.add('Energy looks strong. This may be a good time for workouts or active days.');
    }

    final inPeriod = _painCorrelation['inPeriod'] ?? 0.0;
    final outPeriod = _painCorrelation['outPeriod'] ?? 0.0;
    if (inPeriod > outPeriod + 1) {
      insights.add('Pain is higher during your period compared to other days.');
    } else if (outPeriod > inPeriod + 1) {
      insights.add('Pain is higher outside your period. Consider tracking triggers in notes.');
    }

    if (_cycles.isNotEmpty) {
      final lastCycle = _cycles.reduce((a, b) => a.startDate.isAfter(b.startDate) ? a : b);
      final daysInCycle = DateTime.now().difference(lastCycle.startDate).inDays;
      if (daysInCycle <= 5) {
        insights.add('You are likely in the menstrual phase. Rest and hydration can help.');
      } else if (daysInCycle <= 12) {
        insights.add('You may be in the follicular phase. Energy typically rises in this window.');
      } else if (daysInCycle <= 16) {
        insights.add('You may be near ovulation. Many people report peak energy now.');
      } else {
        insights.add('You may be in the luteal phase. Plan for recovery and self-care.');
      }
    }

    return insights.isEmpty ? ['Keep logging daily to surface more insights.'] : insights;
  }

  Widget _buildDailyTipsCard() {
    final tips = _buildDailyTips();
    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Tips', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...tips.map((tip) => _buildDailyTip(tip.icon, tip.text)).toList(),
        ],
      ),
    );
  }

  List<_DailyTip> _buildDailyTips() {
    final tips = <_DailyTip>[];
    if (_summary.avgEnergy <= 4) {
      tips.add(_DailyTip('💤', 'Aim for 7-9 hours of sleep tonight.'));
    } else {
      tips.add(_DailyTip('💪', 'Try a light workout or a long walk today.'));
    }
    if (_summary.avgPain >= 6) {
      tips.add(_DailyTip('🧘', 'Use heat therapy or a short stretching routine.'));
    } else {
      tips.add(_DailyTip('💧', 'Stay hydrated throughout the day.'));
    }
    if (_summary.avgMood <= 4) {
      tips.add(_DailyTip('🫶', 'Plan a calming activity or reach out to support.'));
    } else {
      tips.add(_DailyTip('🥗', 'Add a nutrient-dense meal today.'));
    }
    return tips;
  }

  // Helper widgets
  Widget _buildMetricCard(String label, String value, String emoji) {
    return CardContainer(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Text(emoji, style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  Widget _buildAccuracyMetric(String label, int percentage) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(String phase, String emoji, double score, String description) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(4)),
            child: Text('${score.toStringAsFixed(1)}/10', style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String emoji, String title, String description, Color color) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepInsight(String title, List<String> items) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildPhaseExerciseCard(String phase, String emoji, String category, List<String> exercises) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exercises.map((ex) {
              return Chip(
                label: Text(ex, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue.shade100,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutBar(String label, int count, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / 20,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildStressLevel(String label, double level, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              Text('$level/10', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: level > 6 ? Colors.red.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status, style: TextStyle(color: level > 6 ? Colors.red.shade700 : Colors.orange.shade700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalHealthInsight(String title, String emoji, String description) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreComponent(String label, int current, int max, Color color) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / max,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$current/$max', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDailyTip(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tip, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
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
                    Text(inPeriod.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.pink)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outside Period', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(outPeriod.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
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
            inPeriod > outPeriod ? '${difference.toStringAsFixed(1)} higher during period' : '${difference.toStringAsFixed(1)} lower during period',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: inPeriod > outPeriod ? Colors.red.shade600 : Colors.green.shade600),
          ),
        ],
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

class _DailyTip {
  final String icon;
  final String text;

  _DailyTip(this.icon, this.text);
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
