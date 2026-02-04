class CycleModel {
  final String? id;
  final DateTime lastPeriodDate;
  final int cycleLength; // days between period starts
  final int periodLength; // duration of period in days
  final String? notes;
  final DateTime createdAt;

  CycleModel({
    this.id,
    required this.lastPeriodDate,
    required this.cycleLength,
    required this.periodLength,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DateTime get nextPeriodDate =>
      lastPeriodDate.add(Duration(days: cycleLength));

  Map<String, dynamic> toJson() => {
        'id': id,
        'lastPeriodDate': lastPeriodDate.toIso8601String(),
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CycleModel.fromJson(Map<String, dynamic> json) => CycleModel(
        id: json['id'] as String?,
        lastPeriodDate: DateTime.parse(json['lastPeriodDate'] as String),
        cycleLength: (json['cycleLength'] as num).toInt(),
        periodLength: (json['periodLength'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}
