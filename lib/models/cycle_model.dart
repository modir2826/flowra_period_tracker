class CycleModel {
  final DateTime lastPeriodDate;
  final int cycleLength;

  CycleModel({
    required this.lastPeriodDate,
    required this.cycleLength,
  });

  DateTime get nextPeriodDate {
    return lastPeriodDate.add(Duration(days: cycleLength));
  }
}
