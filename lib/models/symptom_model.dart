import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomEntry {
  final String id;
  final String oderId;
  final DateTime timestamp;
  final int painLevel;
  final int stoolFrequency;
  final int urgencyLevel;
  final int fatigueLevel;
  final bool hasBlood;
  final bool hasMucus;
  final bool hasNausea;
  final bool hasVomiting;
  final bool hasFever;
  final double? temperature;
  final bool hasJointPain;
  final bool hasSkinIssues;
  final bool hasEyeIssues;
  final String? notes;
  final List<String> tags;
  final bool isFlare;

  SymptomEntry({
    required this.id,
    required this.oderId,
    required this.timestamp,
    required this.painLevel,
    required this.stoolFrequency,
    required this.urgencyLevel,
    required this.fatigueLevel,
    this.hasBlood = false,
    this.hasMucus = false,
    this.hasNausea = false,
    this.hasVomiting = false,
    this.hasFever = false,
    this.temperature,
    this.hasJointPain = false,
    this.hasSkinIssues = false,
    this.hasEyeIssues = false,
    this.notes,
    this.tags = const [],
    this.isFlare = false,
  });

  factory SymptomEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SymptomEntry(
      id: doc.id,
      oderId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      painLevel: data['painLevel'] ?? 0,
      stoolFrequency: data['stoolFrequency'] ?? 0,
      urgencyLevel: data['urgencyLevel'] ?? 0,
      fatigueLevel: data['fatigueLevel'] ?? 0,
      hasBlood: data['hasBlood'] ?? false,
      hasMucus: data['hasMucus'] ?? false,
      hasNausea: data['hasNausea'] ?? false,
      hasVomiting: data['hasVomiting'] ?? false,
      hasFever: data['hasFever'] ?? false,
      temperature: data['temperature']?.toDouble(),
      hasJointPain: data['hasJointPain'] ?? false,
      hasSkinIssues: data['hasSkinIssues'] ?? false,
      hasEyeIssues: data['hasEyeIssues'] ?? false,
      notes: data['notes'],
      tags: List<String>.from(data['tags'] ?? []),
      isFlare: data['isFlare'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'painLevel': painLevel,
      'stoolFrequency': stoolFrequency,
      'urgencyLevel': urgencyLevel,
      'fatigueLevel': fatigueLevel,
      'hasBlood': hasBlood,
      'hasMucus': hasMucus,
      'hasNausea': hasNausea,
      'hasVomiting': hasVomiting,
      'hasFever': hasFever,
      'temperature': temperature,
      'hasJointPain': hasJointPain,
      'hasSkinIssues': hasSkinIssues,
      'hasEyeIssues': hasEyeIssues,
      'notes': notes,
      'tags': tags,
      'isFlare': isFlare,
    };
  }

  int get severityScore {
    return ((painLevel + urgencyLevel + fatigueLevel) / 3).round() +
        (hasBlood ? 2 : 0) +
        (hasFever ? 1 : 0) +
        (stoolFrequency > 6 ? 2 : (stoolFrequency > 3 ? 1 : 0));
  }

  SymptomEntry copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    int? painLevel,
    int? stoolFrequency,
    int? urgencyLevel,
    int? fatigueLevel,
    bool? hasBlood,
    bool? hasMucus,
    bool? hasNausea,
    bool? hasVomiting,
    bool? hasFever,
    double? temperature,
    bool? hasJointPain,
    bool? hasSkinIssues,
    bool? hasEyeIssues,
    String? notes,
    List<String>? tags,
    bool? isFlare,
  }) {
    return SymptomEntry(
      id: id ?? this.id,
      oderId: userId ?? this.oderId,
      timestamp: timestamp ?? this.timestamp,
      painLevel: painLevel ?? this.painLevel,
      stoolFrequency: stoolFrequency ?? this.stoolFrequency,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      hasBlood: hasBlood ?? this.hasBlood,
      hasMucus: hasMucus ?? this.hasMucus,
      hasNausea: hasNausea ?? this.hasNausea,
      hasVomiting: hasVomiting ?? this.hasVomiting,
      hasFever: hasFever ?? this.hasFever,
      temperature: temperature ?? this.temperature,
      hasJointPain: hasJointPain ?? this.hasJointPain,
      hasSkinIssues: hasSkinIssues ?? this.hasSkinIssues,
      hasEyeIssues: hasEyeIssues ?? this.hasEyeIssues,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isFlare: isFlare ?? this.isFlare,
    );
  }
}
