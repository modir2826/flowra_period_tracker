class CycleModel {
  final String? id;
  final DateTime startDate; // period start
  final DateTime? endDate; // period end (optional)
  final int cycleLength; // days between period starts
  final int periodLength; // duration of period in days
  final String flowIntensity; // Spotting/Light/Medium/Heavy
  final bool missed; // missed/skipped period flag
  final String? notes;
  final DateTime createdAt;

  CycleModel({
    this.id,
    required this.startDate,
    this.endDate,
    required this.cycleLength,
    required this.periodLength,
    this.flowIntensity = 'Medium',
    this.missed = false,
    this.notes,
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

    factory CycleModel.fromJson(Map<String, dynamic> json) => CycleModel(
      id: json['id'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      cycleLength: (json['cycleLength'] as num).toInt(),
      periodLength: (json['periodLength'] as num?)?.toInt() ?? 0,
      flowIntensity: (json['flowIntensity'] ?? 'Medium') as String,
      missed: (json['missed'] ?? false) as bool,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
      ? DateTime.parse(json['createdAt'] as String)
      : DateTime.now(),
    );
}
