import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class ClinicianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getPatients(String clinicianId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('clinicianId', isEqualTo: clinicianId)
        .where('role', isEqualTo: UserRole.patient.name)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<List<UserModel>> getPatientsWithSharedData(String clinicianId) async {
    final patients = await getPatients(clinicianId);
    return patients.where((p) {
      final settings = p.privacySettings;
      return settings.symptomsPrivacy == PrivacyLevel.sharedWithClinician ||
          settings.medicationsPrivacy == PrivacyLevel.sharedWithClinician ||
          settings.dietPrivacy == PrivacyLevel.sharedWithClinician ||
          settings.moodPrivacy == PrivacyLevel.sharedWithClinician ||
          settings.videoDiaryPrivacy == PrivacyLevel.sharedWithClinician ||
          settings.narrativesPrivacy == PrivacyLevel.sharedWithClinician ||
          settings.promsPrivacy == PrivacyLevel.sharedWithClinician;
    }).toList();
  }

  Future<Map<String, dynamic>> getPatientOverview(String patientId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final symptomsSnapshot = await _firestore
        .collection('symptoms')
        .where('userId', isEqualTo: patientId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    final medicationLogsSnapshot = await _firestore
        .collection('medication_logs')
        .where('userId', isEqualTo: patientId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    final sibdqSnapshot = await _firestore
        .collection('sibdq_responses')
        .where('userId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    final symptoms = symptomsSnapshot.docs
        .map((doc) => SymptomEntry.fromFirestore(doc))
        .toList();

    final medicationLogs = medicationLogsSnapshot.docs
        .map((doc) => MedicationLog.fromFirestore(doc))
        .toList();

    SIBDQResponse? latestSibdq;
    if (sibdqSnapshot.docs.isNotEmpty) {
      latestSibdq = SIBDQResponse.fromFirestore(sibdqSnapshot.docs.first);
    }

    double avgPain = 0;
    double avgFatigue = 0;
    int flareCount = 0;
    if (symptoms.isNotEmpty) {
      avgPain = symptoms.map((s) => s.painLevel).reduce((a, b) => a + b) / symptoms.length;
      avgFatigue = symptoms.map((s) => s.fatigueLevel).reduce((a, b) => a + b) / symptoms.length;
      flareCount = symptoms.where((s) => s.isFlare).length;
    }

    int takenMeds = medicationLogs.where((l) => l.taken).length;
    double adherenceRate = medicationLogs.isNotEmpty
        ? (takenMeds / medicationLogs.length) * 100
        : 0;

    return {
      'symptomEntries': symptoms.length,
      'averagePain': avgPain,
      'averageFatigue': avgFatigue,
      'flareCount': flareCount,
      'medicationAdherence': adherenceRate,
      'latestSibdqScore': latestSibdq?.totalScore,
      'latestSibdqDate': latestSibdq?.timestamp,
    };
  }

  Future<List<SymptomEntry>> getPatientSymptoms(
    String patientId, {
    DateTime? startDate,
    DateTime? endDate,
    int? severityThreshold,
    bool? flaresOnly,
  }) async {
    Query query = _firestore
        .collection('symptoms')
        .where('userId', isEqualTo: patientId);

    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (flaresOnly == true) {
      query = query.where('isFlare', isEqualTo: true);
    }

    final snapshot = await query.orderBy('timestamp', descending: true).get();
    var symptoms = snapshot.docs
        .map((doc) => SymptomEntry.fromFirestore(doc))
        .toList();

    if (severityThreshold != null) {
      symptoms = symptoms.where((s) => s.severityScore >= severityThreshold).toList();
    }

    return symptoms;
  }

  Future<List<MoodEntry>> getPatientMoodEntries(
    String patientId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore
        .collection('mood_entries')
        .where('userId', isEqualTo: patientId);

    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
  }

  Future<List<DietEntry>> getPatientDietEntries(
    String patientId, {
    DateTime? startDate,
    DateTime? endDate,
    bool? triggersOnly,
  }) async {
    Query query = _firestore
        .collection('diet_entries')
        .where('userId', isEqualTo: patientId);

    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (triggersOnly == true) {
      query = query.where('triggeredSymptoms', isEqualTo: true);
    }

    final snapshot = await query.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => DietEntry.fromFirestore(doc)).toList();
  }

  Future<List<SIBDQResponse>> getPatientSIBDQResponses(
    String patientId, {
    int? limit,
  }) async {
    Query query = _firestore
        .collection('sibdq_responses')
        .where('userId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SIBDQResponse.fromFirestore(doc)).toList();
  }

  Future<List<VideoDiary>> getPatientVideoDiaries(
    String patientId, {
    VideoDiaryCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore
        .collection('video_diaries')
        .where('userId', isEqualTo: patientId);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => VideoDiary.fromFirestore(doc)).toList();
  }

  Future<List<Narrative>> getPatientNarratives(
    String patientId, {
    NarrativeCategory? category,
  }) async {
    Query query = _firestore
        .collection('narratives')
        .where('userId', isEqualTo: patientId)
        .where('isDraft', isEqualTo: false);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    final snapshot = await query.orderBy('updatedAt', descending: true).get();
    return snapshot.docs.map((doc) => Narrative.fromFirestore(doc)).toList();
  }

  Future<Map<String, dynamic>> generatePatientReport(
    String patientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final symptoms = await getPatientSymptoms(
      patientId,
      startDate: startDate,
      endDate: endDate,
    );

    final moodEntries = await getPatientMoodEntries(
      patientId,
      startDate: startDate,
      endDate: endDate,
    );

    final dietEntries = await getPatientDietEntries(
      patientId,
      startDate: startDate,
      endDate: endDate,
    );

    final sibdqResponses = await getPatientSIBDQResponses(patientId, limit: 10);

    final medicationLogsSnapshot = await _firestore
        .collection('medication_logs')
        .where('userId', isEqualTo: patientId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final medicationLogs = medicationLogsSnapshot.docs
        .map((doc) => MedicationLog.fromFirestore(doc))
        .toList();

    return {
      'period': {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
      'symptoms': {
        'totalEntries': symptoms.length,
        'flareCount': symptoms.where((s) => s.isFlare).length,
        'averagePain': symptoms.isNotEmpty
            ? symptoms.map((s) => s.painLevel).reduce((a, b) => a + b) / symptoms.length
            : 0,
        'averageFatigue': symptoms.isNotEmpty
            ? symptoms.map((s) => s.fatigueLevel).reduce((a, b) => a + b) / symptoms.length
            : 0,
      },
      'mood': {
        'totalEntries': moodEntries.length,
        'averageWellbeing': moodEntries.isNotEmpty
            ? moodEntries.map((m) => m.wellbeingScore).reduce((a, b) => a + b) / moodEntries.length
            : 0,
      },
      'diet': {
        'totalEntries': dietEntries.length,
        'triggerEvents': dietEntries.where((d) => d.triggeredSymptoms).length,
      },
      'medication': {
        'totalLogs': medicationLogs.length,
        'adherenceRate': medicationLogs.isNotEmpty
            ? (medicationLogs.where((l) => l.taken).length / medicationLogs.length) * 100
            : 0,
      },
      'sibdq': {
        'latestScore': sibdqResponses.isNotEmpty ? sibdqResponses.first.totalScore : null,
        'scoreHistory': sibdqResponses.map((r) => <String, dynamic>{
          'date': r.timestamp.toIso8601String(),
          'score': r.totalScore,
        }).toList(),
      },
    };
  }

  Future<Map<String, dynamic>> exportPatientData(
    String patientId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final report = await generatePatientReport(patientId, startDate, endDate);
    
    final symptoms = await getPatientSymptoms(
      patientId,
      startDate: startDate,
      endDate: endDate,
    );

    final moodEntries = await getPatientMoodEntries(
      patientId,
      startDate: startDate,
      endDate: endDate,
    );

    final dietEntries = await getPatientDietEntries(
      patientId,
      startDate: startDate,
      endDate: endDate,
    );

    return {
      'summary': report,
      'rawData': {
        'symptoms': symptoms.map((s) => s.toFirestore()).toList(),
        'moodEntries': moodEntries.map((m) => m.toFirestore()).toList(),
        'dietEntries': dietEntries.map((d) => d.toFirestore()).toList(),
      },
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
