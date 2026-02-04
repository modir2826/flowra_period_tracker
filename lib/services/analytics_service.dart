import '../models/health_log_model.dart';
import '../models/cycle_model.dart';

class HealthSummary {
  final double avgMood;
  final double avgEnergy;
  final double avgPain;
  final int totalLogs;

  HealthSummary({
    required this.avgMood,
    required this.avgEnergy,
    required this.avgPain,
    required this.totalLogs,
  });
}

class AnalyticsService {
  // Compute simple summary across provided logs
  HealthSummary computeSummary(List<HealthLogModel> logs) {
    if (logs.isEmpty) return HealthSummary(avgMood: 3.0, avgEnergy: 5.0, avgPain: 0.0, totalLogs: 0);
    final total = logs.length;
    final moodTotal = logs.map((l) => l.mood).reduce((a, b) => a + b);
    final energyTotal = logs.map((l) => l.energy).reduce((a, b) => a + b);
    final painTotal = logs.map((l) => l.painIntensity).reduce((a, b) => a + b);
    return HealthSummary(
      avgMood: moodTotal / total,
      avgEnergy: energyTotal / total,
      avgPain: painTotal / total,
      totalLogs: total,
    );
  }

  // Correlate pain intensity during period windows vs outside.
  // A simple approach: for each cycle create a [start, end) window and
  // classify logs as in-period or out-of-period.
  Map<String, double> correlatePainWithCycles(List<CycleModel> cycles, List<HealthLogModel> logs) {
    if (logs.isEmpty) return {'inPeriod': 0.0, 'outPeriod': 0.0};

    final windows = <Map<String, DateTime>>[];
    for (final c in cycles) {
      final start = c.lastPeriodDate;
      final end = start.add(Duration(days: c.periodLength));
      windows.add({'start': start, 'end': end});
    }

    double inSum = 0;
    int inCount = 0;
    double outSum = 0;
    int outCount = 0;

    for (final l in logs) {
      final ts = l.timestamp;
      final inWindow = windows.any((w) {
        final s = w['start']!;
        final e = w['end']!;
        return !ts.isBefore(s) && ts.isBefore(e);
      });

      if (inWindow) {
        inSum += l.painIntensity;
        inCount++;
      } else {
        outSum += l.painIntensity;
        outCount++;
      }
    }

    return {
      'inPeriod': inCount == 0 ? 0.0 : inSum / inCount,
      'outPeriod': outCount == 0 ? 0.0 : outSum / outCount,
    };
  }

  /// Compute daily averages for the past [days] days (including today).
  /// Returns a map with keys 'days' (list of DateTime) and per-metric lists.
  Map<String, dynamic> computeDailyAverages(List<HealthLogModel> logs, {int days = 14}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

    // Initialize accumulators
    final dayLabels = List<DateTime>.generate(days, (i) => startDate.add(Duration(days: i)));
    final moodSums = List<double>.filled(days, 0.0);
    final energySums = List<double>.filled(days, 0.0);
    final painSums = List<double>.filled(days, 0.0);
    final counts = List<int>.filled(days, 0);

    for (final l in logs) {
      final d = DateTime(l.timestamp.year, l.timestamp.month, l.timestamp.day);
      final idx = d.difference(startDate).inDays;
      if (idx < 0 || idx >= days) continue;
      moodSums[idx] += l.mood;
      energySums[idx] += l.energy;
      painSums[idx] += l.painIntensity;
      counts[idx]++;
    }

    final moodAvg = List<double>.generate(days, (i) => counts[i] == 0 ? 0.0 : moodSums[i] / counts[i]);
    final energyAvg = List<double>.generate(days, (i) => counts[i] == 0 ? 0.0 : energySums[i] / counts[i]);
    final painAvg = List<double>.generate(days, (i) => counts[i] == 0 ? 0.0 : painSums[i] / counts[i]);

    return {
      'days': dayLabels,
      'mood': moodAvg,
      'energy': energyAvg,
      'pain': painAvg,
    };
  }
}
