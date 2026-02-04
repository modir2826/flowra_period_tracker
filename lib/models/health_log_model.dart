class HealthLogModel {
  final String? id;
  final DateTime timestamp;
  final int mood; // 1-5
  final int energy; // 1-10
  final int painIntensity; // 0-10
  final String painLocation;
  final String notes;

  HealthLogModel({
    this.id,
    required this.timestamp,
    required this.mood,
    required this.energy,
    required this.painIntensity,
    this.painLocation = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'mood': mood,
        'energy': energy,
        'painIntensity': painIntensity,
        'painLocation': painLocation,
        'notes': notes,
      };

  factory HealthLogModel.fromJson(Map<String, dynamic> json) {
    return HealthLogModel(
      id: json['id'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mood: (json['mood'] ?? 3) as int,
      energy: (json['energy'] ?? 5) as int,
      painIntensity: (json['painIntensity'] ?? 0) as int,
      painLocation: (json['painLocation'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
    );
  }
}
