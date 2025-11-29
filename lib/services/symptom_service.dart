import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symptom_model.dart';

class SymptomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'symptoms';

  Future<String> addSymptomEntry(SymptomEntry entry) async {
    final docRef = await _firestore.collection(_collection).add(entry.toFirestore());
    return docRef.id;
  }

  Future<void> updateSymptomEntry(SymptomEntry entry) async {
    await _firestore.collection(_collection).doc(entry.id).update(entry.toFirestore());
  }

  Future<void> deleteSymptomEntry(String entryId) async {
    await _firestore.collection(_collection).doc(entryId).delete();
  }

  Future<SymptomEntry?> getSymptomEntry(String entryId) async {
    final doc = await _firestore.collection(_collection).doc(entryId).get();
    if (doc.exists) {
      return SymptomEntry.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<SymptomEntry>> getSymptomEntriesStream(String oderId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: oderId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SymptomEntry.fromFirestore(doc)).toList());
  }

  Future<List<SymptomEntry>> getSymptomEntriesByDateRange(
    String oderId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: oderId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => SymptomEntry.fromFirestore(doc)).toList();
  }

  Future<List<SymptomEntry>> getFlareEntries(String oderId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: oderId)
        .where('isFlare', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => SymptomEntry.fromFirestore(doc)).toList();
  }

  Future<Map<String, dynamic>> getSymptomStatistics(
    String oderId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entries = await getSymptomEntriesByDateRange(oderId, startDate, endDate);
    
    if (entries.isEmpty) {
      return {
        'averagePain': 0.0,
        'averageFatigue': 0.0,
        'averageUrgency': 0.0,
        'averageStoolFrequency': 0.0,
        'flareCount': 0,
        'totalEntries': 0,
      };
    }

    double totalPain = 0;
    double totalFatigue = 0;
    double totalUrgency = 0;
    double totalStoolFrequency = 0;
    int flareCount = 0;

    for (final entry in entries) {
      totalPain += entry.painLevel;
      totalFatigue += entry.fatigueLevel;
      totalUrgency += entry.urgencyLevel;
      totalStoolFrequency += entry.stoolFrequency;
      if (entry.isFlare) flareCount++;
    }

    return {
      'averagePain': totalPain / entries.length,
      'averageFatigue': totalFatigue / entries.length,
      'averageUrgency': totalUrgency / entries.length,
      'averageStoolFrequency': totalStoolFrequency / entries.length,
      'flareCount': flareCount,
      'totalEntries': entries.length,
    };
  }

  Future<SymptomEntry?> getTodaysEntry(String oderId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: oderId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SymptomEntry.fromFirestore(snapshot.docs.first);
    }
    return null;
  }
}
