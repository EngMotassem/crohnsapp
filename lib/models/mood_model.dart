import 'package:cloud_firestore/cloud_firestore.dart';

enum MoodLevel { veryLow, low, neutral, good, veryGood }

enum StressLevel { none, mild, moderate, high, severe }

enum SleepQuality { veryPoor, poor, fair, good, excellent }

class MoodEntry {
  final String id;
  final String oderId;
  final DateTime timestamp;
  final MoodLevel moodLevel;
  final StressLevel stressLevel;
  final SleepQuality sleepQuality;
  final double? sleepHours;
  final int anxietyLevel;
  final int depressionLevel;
  final bool feelingIsolated;
  final bool impactOnDailyLife;
  final List<String> copingStrategiesUsed;
  final String? notes;
  final List<String> tags;

  MoodEntry({
    required this.id,
    required this.oderId,
    required this.timestamp,
    required this.moodLevel,
    required this.stressLevel,
    required this.sleepQuality,
    this.sleepHours,
    this.anxietyLevel = 0,
    this.depressionLevel = 0,
    this.feelingIsolated = false,
    this.impactOnDailyLife = false,
    this.copingStrategiesUsed = const [],
    this.notes,
    this.tags = const [],
  });

  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      id: doc.id,
      oderId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      moodLevel: MoodLevel.values.firstWhere(
        (e) => e.name == data['moodLevel'],
        orElse: () => MoodLevel.neutral,
      ),
      stressLevel: StressLevel.values.firstWhere(
        (e) => e.name == data['stressLevel'],
        orElse: () => StressLevel.none,
      ),
      sleepQuality: SleepQuality.values.firstWhere(
        (e) => e.name == data['sleepQuality'],
        orElse: () => SleepQuality.fair,
      ),
      sleepHours: data['sleepHours']?.toDouble(),
      anxietyLevel: data['anxietyLevel'] ?? 0,
      depressionLevel: data['depressionLevel'] ?? 0,
      feelingIsolated: data['feelingIsolated'] ?? false,
      impactOnDailyLife: data['impactOnDailyLife'] ?? false,
      copingStrategiesUsed:
          List<String>.from(data['copingStrategiesUsed'] ?? []),
      notes: data['notes'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'moodLevel': moodLevel.name,
      'stressLevel': stressLevel.name,
      'sleepQuality': sleepQuality.name,
      'sleepHours': sleepHours,
      'anxietyLevel': anxietyLevel,
      'depressionLevel': depressionLevel,
      'feelingIsolated': feelingIsolated,
      'impactOnDailyLife': impactOnDailyLife,
      'copingStrategiesUsed': copingStrategiesUsed,
      'notes': notes,
      'tags': tags,
    };
  }

  int get wellbeingScore {
    int score = 0;
    switch (moodLevel) {
      case MoodLevel.veryGood:
        score += 5;
        break;
      case MoodLevel.good:
        score += 4;
        break;
      case MoodLevel.neutral:
        score += 3;
        break;
      case MoodLevel.low:
        score += 2;
        break;
      case MoodLevel.veryLow:
        score += 1;
        break;
    }
    switch (sleepQuality) {
      case SleepQuality.excellent:
        score += 5;
        break;
      case SleepQuality.good:
        score += 4;
        break;
      case SleepQuality.fair:
        score += 3;
        break;
      case SleepQuality.poor:
        score += 2;
        break;
      case SleepQuality.veryPoor:
        score += 1;
        break;
    }
    score -= (anxietyLevel ~/ 2);
    score -= (depressionLevel ~/ 2);
    return score.clamp(0, 10);
  }

  MoodEntry copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    MoodLevel? moodLevel,
    StressLevel? stressLevel,
    SleepQuality? sleepQuality,
    double? sleepHours,
    int? anxietyLevel,
    int? depressionLevel,
    bool? feelingIsolated,
    bool? impactOnDailyLife,
    List<String>? copingStrategiesUsed,
    String? notes,
    List<String>? tags,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      oderId: userId ?? this.oderId,
      timestamp: timestamp ?? this.timestamp,
      moodLevel: moodLevel ?? this.moodLevel,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepHours: sleepHours ?? this.sleepHours,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
      depressionLevel: depressionLevel ?? this.depressionLevel,
      feelingIsolated: feelingIsolated ?? this.feelingIsolated,
      impactOnDailyLife: impactOnDailyLife ?? this.impactOnDailyLife,
      copingStrategiesUsed: copingStrategiesUsed ?? this.copingStrategiesUsed,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}
