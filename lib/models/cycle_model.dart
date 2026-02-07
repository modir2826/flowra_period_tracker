class CycleModel {
  final String? id;
  final DateTime startDate; // period start
  final DateTime? endDate; // period end (optional)
  final int cycleLength; // days between period starts
  final int periodLength; // duration of period in days
  final String flowIntensity; // Spotting/Light/Medium/Heavy
  final bool missed; // missed/skipped period flag
  final String notes;
  final DateTime createdAt;

  CycleModel({
    this.id,
    required this.startDate,
    this.endDate,
    required this.cycleLength,
    required this.periodLength,
    this.flowIntensity = 'Medium',
    this.missed = false,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DateTime get nextPeriodDate => startDate.add(Duration(days: cycleLength));

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'flowIntensity': flowIntensity,
        'missed': missed,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is Map && value['millisecondsSinceEpoch'] is int) {
      return DateTime.fromMillisecondsSinceEpoch(value['millisecondsSinceEpoch'] as int);
    }
    return DateTime.now();
  }

  factory CycleModel.fromJson(Map<String, dynamic> json) => CycleModel(
        id: json['id'] as String?,
        startDate: _parseDate(json['startDate']),
        endDate: json['endDate'] != null ? _parseDate(json['endDate']) : null,
        cycleLength: (json['cycleLength'] as num?)?.toInt() ?? 28,
        periodLength: (json['periodLength'] as num?)?.toInt() ?? 5,
        flowIntensity: (json['flowIntensity'] ?? 'Medium') as String,
        missed: (json['missed'] ?? false) as bool,
        notes: (json['notes'] ?? '') as String,
        createdAt: json['createdAt'] != null ? _parseDate(json['createdAt']) : DateTime.now(),
      );
}
