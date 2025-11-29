import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood_model.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'mood_entries';

  Future<String> addMoodEntry(MoodEntry entry) async {
    final docRef = await _firestore.collection(_collection).add(entry.toFirestore());
    return docRef.id;
  }

  Future<void> updateMoodEntry(MoodEntry entry) async {
    await _firestore.collection(_collection).doc(entry.id).update(entry.toFirestore());
  }

  Future<void> deleteMoodEntry(String entryId) async {
    await _firestore.collection(_collection).doc(entryId).delete();
  }

  Stream<List<MoodEntry>> getMoodEntriesStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList());
  }

  Future<List<MoodEntry>> getMoodEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
  }

  Future<MoodEntry?> getTodaysEntry(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return MoodEntry.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<Map<String, dynamic>> getMoodStatistics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final entries = await getMoodEntriesByDateRange(userId, startDate, endDate);

    if (entries.isEmpty) {
      return {
        'averageWellbeing': 0.0,
        'averageSleepHours': 0.0,
        'moodDistribution': <String, int>{},
        'stressDistribution': <String, int>{},
        'totalEntries': 0,
      };
    }

    double totalWellbeing = 0;
    double totalSleepHours = 0;
    int sleepEntries = 0;
    final moodDistribution = <String, int>{};
    final stressDistribution = <String, int>{};

    for (final entry in entries) {
      totalWellbeing += entry.wellbeingScore;
      if (entry.sleepHours != null) {
        totalSleepHours += entry.sleepHours!;
        sleepEntries++;
      }
      final moodName = entry.moodLevel.name;
      moodDistribution[moodName] = (moodDistribution[moodName] ?? 0) + 1;
      final stressName = entry.stressLevel.name;
      stressDistribution[stressName] = (stressDistribution[stressName] ?? 0) + 1;
    }

    return {
      'averageWellbeing': totalWellbeing / entries.length,
      'averageSleepHours': sleepEntries > 0 ? totalSleepHours / sleepEntries : 0.0,
      'moodDistribution': moodDistribution,
      'stressDistribution': stressDistribution,
      'totalEntries': entries.length,
    };
  }

  Future<List<String>> getCommonCopingStrategies(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final strategyCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final entry = MoodEntry.fromFirestore(doc);
      for (final strategy in entry.copingStrategiesUsed) {
        strategyCounts[strategy] = (strategyCounts[strategy] ?? 0) + 1;
      }
    }

    final sortedStrategies = strategyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedStrategies.take(10).map((e) => e.key).toList();
  }
}
