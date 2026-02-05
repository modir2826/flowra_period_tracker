class HealthLogModel {
  final String? id;
  final DateTime timestamp;

  // Mood
  final String mood; // emoji or keyword
  final int moodIntensity; // 1-5

  // Energy & pain
  final int energy; // 1-10
  final int painIntensity; // 0-10
  final String painLocation;

  // Period / flow
  final String periodStatus; // None/Spotting/Light/Medium/Heavy
  final bool spotting;
  final int? cycleDay;

  // Symptoms
  final List<String> symptoms;

  // Sleep
  final double? sleepHours;
  final String? sleepQuality; // Poor/Okay/Good

  // Activity
  final String activityType;
  final int? activityDuration; // minutes

  // Hydration
  final int hydration; // glasses
  final int? hydrationGoal;

  // Nutrition
  final List<String> cravings; // Sweet/Salty/Spicy
  final bool ironTaken;
  final String foodNotes;

  // Reproductive & sexual
  final String cervicalMucus; // types
  final String ovulationTest; // Positive/Negative/Not taken
  final int libido; // 0-10
  final bool sexualActivity; // yes/no
  final bool sexualProtected;
  final String sexualDiscomfort;

  // Mental health
  final String stressLevel; // Low/Medium/High
  final String stressReason;

  // Other
  final int energyLevel; // 0-10 duplicate/alternate
  final List<String> medications;
  final List<String> selfCare;
  final String notes;

  HealthLogModel({
    this.id,
    DateTime? timestamp,
    this.mood = 'Neutral',
    this.moodIntensity = 3,
    this.energy = 5,
    this.painIntensity = 0,
    this.painLocation = '',
    this.periodStatus = 'None',
    this.spotting = false,
    this.cycleDay,
    List<String>? symptoms,
    this.sleepHours,
    this.sleepQuality,
    this.activityType = 'None',
    this.activityDuration,
    this.hydration = 0,
    this.hydrationGoal,
    List<String>? cravings,
    this.ironTaken = false,
    this.foodNotes = '',
    this.cervicalMucus = '',
    this.ovulationTest = 'Not taken',
    this.libido = 5,
    this.sexualActivity = false,
    this.sexualProtected = false,
    this.sexualDiscomfort = '',
    this.stressLevel = 'Medium',
    this.stressReason = '',
    this.energyLevel = 5,
    List<String>? medications,
    List<String>? selfCare,
    this.notes = '',
  })  : timestamp = timestamp ?? DateTime.now(),
        symptoms = symptoms ?? [],
        cravings = cravings ?? [],
        medications = medications ?? [],
        selfCare = selfCare ?? [];

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'mood': mood,
        'moodIntensity': moodIntensity,
        'energy': energy,
        'painIntensity': painIntensity,
        'painLocation': painLocation,
        'periodStatus': periodStatus,
        'spotting': spotting,
        'cycleDay': cycleDay,
        'symptoms': symptoms,
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
        'activityType': activityType,
        'activityDuration': activityDuration,
        'hydration': hydration,
        'hydrationGoal': hydrationGoal,
        'cravings': cravings,
        'ironTaken': ironTaken,
        'foodNotes': foodNotes,
        'cervicalMucus': cervicalMucus,
        'ovulationTest': ovulationTest,
        'libido': libido,
        'sexualActivity': sexualActivity,
        'sexualProtected': sexualProtected,
        'sexualDiscomfort': sexualDiscomfort,
        'stressLevel': stressLevel,
        'stressReason': stressReason,
        'energyLevel': energyLevel,
        'medications': medications,
        'selfCare': selfCare,
        'notes': notes,
      };

  factory HealthLogModel.fromJson(Map<String, dynamic> json) {
    return HealthLogModel(
      id: json['id'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
      mood: (json['mood'] ?? 'Neutral') as String,
      moodIntensity: (json['moodIntensity'] ?? 3) as int,
      energy: (json['energy'] ?? 5) as int,
      painIntensity: (json['painIntensity'] ?? 0) as int,
      painLocation: (json['painLocation'] ?? '') as String,
      periodStatus: (json['periodStatus'] ?? 'None') as String,
      spotting: (json['spotting'] ?? false) as bool,
      cycleDay: json['cycleDay'] as int?,
      symptoms: json['symptoms'] != null ? List<String>.from(json['symptoms'] as List) : [],
      sleepHours: json['sleepHours'] != null ? (json['sleepHours'] as num).toDouble() : null,
      sleepQuality: json['sleepQuality'] as String?,
      activityType: (json['activityType'] ?? 'None') as String,
      activityDuration: json['activityDuration'] as int?,
      hydration: (json['hydration'] ?? 0) as int,
      hydrationGoal: json['hydrationGoal'] as int?,
      cravings: json['cravings'] != null ? List<String>.from(json['cravings'] as List) : [],
      ironTaken: (json['ironTaken'] ?? false) as bool,
      foodNotes: (json['foodNotes'] ?? '') as String,
      cervicalMucus: (json['cervicalMucus'] ?? '') as String,
      ovulationTest: (json['ovulationTest'] ?? 'Not taken') as String,
      libido: (json['libido'] ?? 5) as int,
      sexualActivity: (json['sexualActivity'] ?? false) as bool,
      sexualProtected: (json['sexualProtected'] ?? false) as bool,
      sexualDiscomfort: (json['sexualDiscomfort'] ?? '') as String,
      stressLevel: (json['stressLevel'] ?? 'Medium') as String,
      stressReason: (json['stressReason'] ?? '') as String,
      energyLevel: (json['energyLevel'] ?? 5) as int,
      medications: json['medications'] != null ? List<String>.from(json['medications'] as List) : [],
      selfCare: json['selfCare'] != null ? List<String>.from(json['selfCare'] as List) : [],
      notes: (json['notes'] ?? '') as String,
    );
  }
}
