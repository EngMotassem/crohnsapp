import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/narrative_model.dart';

class NarrativeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'narratives';

  Future<String> addNarrative(Narrative narrative) async {
    final docRef = await _firestore.collection(_collection).add(narrative.toFirestore());
    return docRef.id;
  }

  Future<void> updateNarrative(Narrative narrative) async {
    await _firestore.collection(_collection).doc(narrative.id).update(narrative.toFirestore());
  }

  Future<void> deleteNarrative(String narrativeId) async {
    await _firestore.collection(_collection).doc(narrativeId).delete();
  }

  Future<Narrative?> getNarrative(String narrativeId) async {
    final doc = await _firestore.collection(_collection).doc(narrativeId).get();
    if (doc.exists) {
      return Narrative.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Narrative>> getNarrativesStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isDraft', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Narrative.fromFirestore(doc)).toList());
  }

  Stream<List<Narrative>> getDraftsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isDraft', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Narrative.fromFirestore(doc)).toList());
  }

  Future<List<Narrative>> getNarrativesByCategory(
    String userId,
    NarrativeCategory category,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category.name)
        .where('isDraft', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Narrative.fromFirestore(doc)).toList();
  }

  Future<List<Narrative>> searchNarratives(String userId, String query) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isDraft', isEqualTo: false)
        .get();

    final narratives = snapshot.docs.map((doc) => Narrative.fromFirestore(doc)).toList();
    final queryLower = query.toLowerCase();

    return narratives.where((n) {
      return n.title.toLowerCase().contains(queryLower) ||
          n.content.toLowerCase().contains(queryLower) ||
          n.tags.any((tag) => tag.toLowerCase().contains(queryLower));
    }).toList();
  }

  Future<void> publishDraft(String narrativeId) async {
    await _firestore.collection(_collection).doc(narrativeId).update({
      'isDraft': false,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateAITags(String narrativeId, List<String> tags) async {
    await _firestore.collection(_collection).doc(narrativeId).update({
      'aiGeneratedTags': tags,
    });
  }

  Future<void> updateSentimentAnalysis(
    String narrativeId,
    Map<String, dynamic> analysis,
  ) async {
    await _firestore.collection(_collection).doc(narrativeId).update({
      'sentimentAnalysis': analysis,
    });
  }

  Future<Map<String, dynamic>> getNarrativeStatistics(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final narratives = snapshot.docs.map((doc) => Narrative.fromFirestore(doc)).toList();

    if (narratives.isEmpty) {
      return {
        'totalNarratives': 0,
        'totalDrafts': 0,
        'totalWordCount': 0,
        'categoryDistribution': <String, int>{},
      };
    }

    int drafts = 0;
    int totalWords = 0;
    final categoryDistribution = <String, int>{};

    for (final narrative in narratives) {
      if (narrative.isDraft) {
        drafts++;
      }
      totalWords += narrative.wordCount;
      final categoryName = narrative.category.name;
      categoryDistribution[categoryName] = (categoryDistribution[categoryName] ?? 0) + 1;
    }

    return {
      'totalNarratives': narratives.length - drafts,
      'totalDrafts': drafts,
      'totalWordCount': totalWords,
      'categoryDistribution': categoryDistribution,
    };
  }
}
