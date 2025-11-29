import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicationType {
  aminosalicylates,
  corticosteroids,
  immunomodulators,
  biologics,
  antibiotics,
  painRelief,
  supplements,
  other,
}

enum DoseFrequency {
  asNeeded,
  onceDaily,
  twiceDaily,
  threeTimesDaily,
  fourTimesDaily,
  weekly,
  biweekly,
  monthly,
}

class Medication {
  final String id;
  final String userId;
  final String name;
  final MedicationType type;
  final String dosage;
  final String unit;
  final DoseFrequency frequency;
  final List<String> reminderTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? prescribedBy;
  final String? notes;
  final List<String> sideEffects;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.dosage,
    required this.unit,
    required this.frequency,
    this.reminderTimes = const [],
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.prescribedBy,
    this.notes,
    this.sideEffects = const [],
  });

  factory Medication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medication(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: MedicationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MedicationType.other,
      ),
      dosage: data['dosage'] ?? '',
      unit: data['unit'] ?? '',
      frequency: DoseFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => DoseFrequency.onceDaily,
      ),
      reminderTimes: List<String>.from(data['reminderTimes'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      prescribedBy: data['prescribedBy'],
      notes: data['notes'],
      sideEffects: List<String>.from(data['sideEffects'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'dosage': dosage,
      'unit': unit,
      'frequency': frequency.name,
      'reminderTimes': reminderTimes,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'prescribedBy': prescribedBy,
      'notes': notes,
      'sideEffects': sideEffects,
    };
  }

  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    MedicationType? type,
    String? dosage,
    String? unit,
    DoseFrequency? frequency,
    List<String>? reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? prescribedBy,
    String? notes,
    List<String>? sideEffects,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      notes: notes ?? this.notes,
      sideEffects: sideEffects ?? this.sideEffects,
    );
  }
}

class MedicationLog {
  final String id;
  final String oderId;
  final String medicationId;
  final DateTime timestamp;
  final bool taken;
  final String? skippedReason;
  final List<String> sideEffectsExperienced;
  final String? notes;

  MedicationLog({
    required this.id,
    required this.oderId,
    required this.medicationId,
    required this.timestamp,
    required this.taken,
    this.skippedReason,
    this.sideEffectsExperienced = const [],
    this.notes,
  });

  factory MedicationLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicationLog(
      id: doc.id,
      oderId: data['userId'] ?? '',
      medicationId: data['medicationId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      taken: data['taken'] ?? false,
      skippedReason: data['skippedReason'],
      sideEffectsExperienced:
          List<String>.from(data['sideEffectsExperienced'] ?? []),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'medicationId': medicationId,
      'timestamp': Timestamp.fromDate(timestamp),
      'taken': taken,
      'skippedReason': skippedReason,
      'sideEffectsExperienced': sideEffectsExperienced,
      'notes': notes,
    };
  }
}
