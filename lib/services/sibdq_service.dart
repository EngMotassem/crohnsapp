import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sibdq_model.dart';

class SIBDQService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'sibdq_responses';

  Future<String> submitResponse(SIBDQResponse response) async {
    final docRef = await _firestore.collection(_collection).add(response.toFirestore());
    return docRef.id;
  }

  Future<void> updateResponse(SIBDQResponse response) async {
    await _firestore.collection(_collection).doc(response.id).update(response.toFirestore());
  }

  Future<void> deleteResponse(String responseId) async {
    await _firestore.collection(_collection).doc(responseId).delete();
  }

  Future<SIBDQResponse?> getResponse(String responseId) async {
    final doc = await _firestore.collection(_collection).doc(responseId).get();
    if (doc.exists) {
      return SIBDQResponse.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<SIBDQResponse>> getResponsesStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SIBDQResponse.fromFirestore(doc)).toList());
  }

  Future<List<SIBDQResponse>> getResponsesByDateRange(
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
    return snapshot.docs.map((doc) => SIBDQResponse.fromFirestore(doc)).toList();
  }

  Future<SIBDQResponse?> getLatestResponse(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SIBDQResponse.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<bool> hasCompletedThisWeek(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>> getScoreTrends(
    String userId,
    int numberOfResponses,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(numberOfResponses)
        .get();

    final responses = snapshot.docs
        .map((doc) => SIBDQResponse.fromFirestore(doc))
        .toList()
        .reversed
        .toList();

    if (responses.isEmpty) {
      return {
        'dates': <DateTime>[],
        'totalScores': <int>[],
        'bowelSymptoms': <int>[],
        'systemicSymptoms': <int>[],
        'socialFunction': <int>[],
        'emotionalFunction': <int>[],
      };
    }

    return {
      'dates': responses.map((r) => r.timestamp).toList(),
      'totalScores': responses.map((r) => r.totalScore).toList(),
      'bowelSymptoms': responses.map((r) => r.bowelSymptomsDomain).toList(),
      'systemicSymptoms': responses.map((r) => r.systemicSymptomsDomain).toList(),
      'socialFunction': responses.map((r) => r.socialFunctionDomain).toList(),
      'emotionalFunction': responses.map((r) => r.emotionalFunctionDomain).toList(),
    };
  }

  Future<Map<String, dynamic>> getStatistics(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final responses = snapshot.docs.map((doc) => SIBDQResponse.fromFirestore(doc)).toList();

    if (responses.isEmpty) {
      return {
        'totalResponses': 0,
        'averageScore': 0.0,
        'highestScore': 0,
        'lowestScore': 0,
        'scoreImprovement': 0.0,
      };
    }

    responses.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final scores = responses.map((r) => r.totalScore).toList();
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    final highestScore = scores.reduce((a, b) => a > b ? a : b);
    final lowestScore = scores.reduce((a, b) => a < b ? a : b);

    double improvement = 0.0;
    if (responses.length >= 2) {
      final firstScore = responses.first.totalScore;
      final lastScore = responses.last.totalScore;
      improvement = ((lastScore - firstScore) / firstScore) * 100;
    }

    return {
      'totalResponses': responses.length,
      'averageScore': averageScore,
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'scoreImprovement': improvement,
    };
  }

  String interpretScore(int totalScore) {
    if (totalScore >= 60) {
      return 'Excellent quality of life - minimal impact from IBD';
    } else if (totalScore >= 50) {
      return 'Good quality of life - mild impact from IBD';
    } else if (totalScore >= 40) {
      return 'Moderate quality of life - noticeable impact from IBD';
    } else if (totalScore >= 30) {
      return 'Fair quality of life - significant impact from IBD';
    } else {
      return 'Poor quality of life - severe impact from IBD';
    }
  }
}
