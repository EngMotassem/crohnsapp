import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diet_model.dart';

class DietService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _entriesCollection = 'diet_entries';
  final String _triggersCollection = 'food_triggers';

  Future<String> addDietEntry(DietEntry entry) async {
    final docRef = await _firestore.collection(_entriesCollection).add(entry.toFirestore());
    
    if (entry.triggeredSymptoms) {
      await _updateFoodTriggers(entry);
    }
    
    return docRef.id;
  }

  Future<void> updateDietEntry(DietEntry entry) async {
    await _firestore
        .collection(_entriesCollection)
        .doc(entry.id)
        .update(entry.toFirestore());
  }

  Future<void> deleteDietEntry(String entryId) async {
    await _firestore.collection(_entriesCollection).doc(entryId).delete();
  }

  Stream<List<DietEntry>> getDietEntriesStream(String oderId) {
    return _firestore
        .collection(_entriesCollection)
        .where('userId', isEqualTo: oderId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DietEntry.fromFirestore(doc)).toList());
  }

  Future<List<DietEntry>> getDietEntriesByDate(String oderId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_entriesCollection)
        .where('userId', isEqualTo: oderId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp')
        .get();

    return snapshot.docs.map((doc) => DietEntry.fromFirestore(doc)).toList();
  }

  Future<List<DietEntry>> getTriggerEntries(String oderId) async {
    final snapshot = await _firestore
        .collection(_entriesCollection)
        .where('userId', isEqualTo: oderId)
        .where('triggeredSymptoms', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => DietEntry.fromFirestore(doc)).toList();
  }

  Stream<List<FoodTrigger>> getFoodTriggersStream(String oderId) {
    return _firestore
        .collection(_triggersCollection)
        .where('userId', isEqualTo: oderId)
        .orderBy('triggerCount', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FoodTrigger.fromFirestore(doc)).toList());
  }

  Future<void> _updateFoodTriggers(DietEntry entry) async {
    for (final food in entry.foods) {
      final existingTrigger = await _firestore
          .collection(_triggersCollection)
          .where('userId', isEqualTo: entry.oderId)
          .where('foodName', isEqualTo: food.name)
          .limit(1)
          .get();

      if (existingTrigger.docs.isNotEmpty) {
        final doc = existingTrigger.docs.first;
        final trigger = FoodTrigger.fromFirestore(doc);
        await _firestore.collection(_triggersCollection).doc(doc.id).update({
          'triggerCount': trigger.triggerCount + 1,
          'lastTriggered': Timestamp.fromDate(entry.timestamp),
          'associatedSymptoms': [
            ...trigger.associatedSymptoms,
            ...entry.symptomTags
          ].toSet().toList(),
        });
      } else {
        final trigger = FoodTrigger(
          id: '',
          userId: entry.oderId,
          foodName: food.name,
          category: food.category,
          triggerCount: 1,
          firstIdentified: entry.timestamp,
          lastTriggered: entry.timestamp,
          associatedSymptoms: entry.symptomTags,
        );
        await _firestore.collection(_triggersCollection).add(trigger.toFirestore());
      }
    }
  }

  Future<void> removeFoodTrigger(String triggerId) async {
    await _firestore.collection(_triggersCollection).doc(triggerId).delete();
  }

  Future<Map<String, dynamic>> getDietStatistics(
    String oderId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection(_entriesCollection)
        .where('userId', isEqualTo: oderId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final entries = snapshot.docs.map((doc) => DietEntry.fromFirestore(doc)).toList();

    if (entries.isEmpty) {
      return {
        'totalEntries': 0,
        'triggerEntries': 0,
        'averageWaterIntake': 0.0,
        'mealTypeDistribution': <String, int>{},
      };
    }

    int triggerCount = entries.where((e) => e.triggeredSymptoms).length;
    double totalWater = entries.fold(0, (sum, e) => sum + e.waterIntake);
    
    final mealDistribution = <String, int>{};
    for (final entry in entries) {
      final mealType = entry.mealType.name;
      mealDistribution[mealType] = (mealDistribution[mealType] ?? 0) + 1;
    }

    return {
      'totalEntries': entries.length,
      'triggerEntries': triggerCount,
      'averageWaterIntake': totalWater / entries.length,
      'mealTypeDistribution': mealDistribution,
    };
  }
}
