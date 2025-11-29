import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _medicationsCollection = 'medications';
  final String _logsCollection = 'medication_logs';

  Future<String> addMedication(Medication medication) async {
    final docRef = await _firestore
        .collection(_medicationsCollection)
        .add(medication.toFirestore());
    return docRef.id;
  }

  Future<void> updateMedication(Medication medication) async {
    await _firestore
        .collection(_medicationsCollection)
        .doc(medication.id)
        .update(medication.toFirestore());
  }

  Future<void> deleteMedication(String medicationId) async {
    await _firestore.collection(_medicationsCollection).doc(medicationId).delete();
  }

  Future<void> deactivateMedication(String medicationId) async {
    await _firestore.collection(_medicationsCollection).doc(medicationId).update({
      'isActive': false,
      'endDate': Timestamp.now(),
    });
  }

  Stream<List<Medication>> getActiveMedicationsStream(String oderId) {
    return _firestore
        .collection(_medicationsCollection)
        .where('userId', isEqualTo: oderId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medication.fromFirestore(doc)).toList());
  }

  Future<List<Medication>> getAllMedications(String oderId) async {
    final snapshot = await _firestore
        .collection(_medicationsCollection)
        .where('userId', isEqualTo: oderId)
        .orderBy('startDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => Medication.fromFirestore(doc)).toList();
  }

  Future<String> logMedicationTaken(MedicationLog log) async {
    final docRef = await _firestore.collection(_logsCollection).add(log.toFirestore());
    return docRef.id;
  }

  Future<void> updateMedicationLog(String logId, MedicationLog log) async {
    await _firestore.collection(_logsCollection).doc(logId).update(log.toFirestore());
  }

  Stream<List<MedicationLog>> getMedicationLogsStream(
    String oderId,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_logsCollection)
        .where('userId', isEqualTo: oderId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MedicationLog.fromFirestore(doc)).toList());
  }

  Future<List<MedicationLog>> getMedicationLogsByDateRange(
    String oderId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection(_logsCollection)
        .where('userId', isEqualTo: oderId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => MedicationLog.fromFirestore(doc)).toList();
  }

  Future<Map<String, dynamic>> getAdherenceStatistics(
    String oderId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final logs = await getMedicationLogsByDateRange(oderId, startDate, endDate);
    
    if (logs.isEmpty) {
      return {
        'totalDoses': 0,
        'takenDoses': 0,
        'missedDoses': 0,
        'adherenceRate': 0.0,
      };
    }

    int takenCount = logs.where((log) => log.taken).length;
    int missedCount = logs.where((log) => !log.taken).length;

    return {
      'totalDoses': logs.length,
      'takenDoses': takenCount,
      'missedDoses': missedCount,
      'adherenceRate': (takenCount / logs.length) * 100,
    };
  }

  Future<List<String>> getCommonSideEffects(String oderId) async {
    final logs = await _firestore
        .collection(_logsCollection)
        .where('userId', isEqualTo: oderId)
        .get();

    final sideEffectCounts = <String, int>{};
    for (final doc in logs.docs) {
      final log = MedicationLog.fromFirestore(doc);
      for (final effect in log.sideEffectsExperienced) {
        sideEffectCounts[effect] = (sideEffectCounts[effect] ?? 0) + 1;
      }
    }

    final sortedEffects = sideEffectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEffects.take(10).map((e) => e.key).toList();
  }
}
