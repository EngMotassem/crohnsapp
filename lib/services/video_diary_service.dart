import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/video_diary_model.dart';

class VideoDiaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'video_diaries';

  Future<String> uploadVideo(String userId, File videoFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('videos/$userId/$timestamp.mp4');
    
    final uploadTask = ref.putFile(
      videoFile,
      SettableMetadata(contentType: 'video/mp4'),
    );
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadThumbnail(String userId, File thumbnailFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('thumbnails/$userId/$timestamp.jpg');
    
    final uploadTask = ref.putFile(
      thumbnailFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> addVideoDiary(VideoDiary diary) async {
    final docRef = await _firestore.collection(_collection).add(diary.toFirestore());
    return docRef.id;
  }

  Future<String> uploadVideoBytes(String userId, Uint8List videoBytes, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    final ref = _storage.ref().child('videos/$userId/$timestamp.$extension');
    
    final uploadTask = ref.putData(
      videoBytes,
      SettableMetadata(contentType: 'video/$extension'),
    );
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> createVideoDiary({
    required String userId,
    required String title,
    required String description,
    required VideoDiaryCategory category,
    required Uint8List videoBytes,
    required String fileName,
  }) async {
    final videoUrl = await uploadVideoBytes(userId, videoBytes, fileName);
    
    final diary = VideoDiary(
      id: '',
      oderId: userId,
      title: title,
      description: description,
      videoUrl: videoUrl,
      thumbnailUrl: null,
      durationSeconds: 0,
      category: category,
      timestamp: DateTime.now(),
      isProcessed: false,
      aiGeneratedTags: [],
      transcription: null,
      sentimentAnalysis: null,
    );
    
    await addVideoDiary(diary);
  }

  // Create video diary from YouTube URL (no Firebase Storage upload)
  Future<void> createVideoDiaryFromYoutube({
    required String userId,
    required String title,
    required String description,
    required VideoDiaryCategory category,
    required String youtubeUrl,
  }) async {
    final diary = VideoDiary(
      id: '',
      oderId: userId,
      title: title,
      description: description,
      videoUrl: youtubeUrl,
      thumbnailUrl: null,
      durationSeconds: 0,
      category: category,
      timestamp: DateTime.now(),
      isProcessed: false,
      aiGeneratedTags: [],
      transcription: null,
      sentimentAnalysis: null,
    );
    
    await addVideoDiary(diary);
  }

  Future<void> updateVideoDiary(VideoDiary diary) async {
    await _firestore.collection(_collection).doc(diary.id).update(diary.toFirestore());
  }

  Future<void> deleteVideoDiary(String diaryId) async {
    final doc = await _firestore.collection(_collection).doc(diaryId).get();
    if (doc.exists) {
      final diary = VideoDiary.fromFirestore(doc);
      
      try {
        await _storage.refFromURL(diary.videoUrl).delete();
        if (diary.thumbnailUrl != null) {
          await _storage.refFromURL(diary.thumbnailUrl!).delete();
        }
      } catch (e) {
        // Continue even if storage deletion fails
      }
      
      await _firestore.collection(_collection).doc(diaryId).delete();
    }
  }

  Stream<List<VideoDiary>> getVideoDiariesStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => VideoDiary.fromFirestore(doc)).toList());
  }

  Future<List<VideoDiary>> getVideoDiariesByCategory(
    String userId,
    VideoDiaryCategory category,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category.name)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => VideoDiary.fromFirestore(doc)).toList();
  }

  Future<List<VideoDiary>> getVideoDiariesByDateRange(
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
    return snapshot.docs.map((doc) => VideoDiary.fromFirestore(doc)).toList();
  }

  Future<void> updateAITags(String diaryId, List<String> tags) async {
    await _firestore.collection(_collection).doc(diaryId).update({
      'aiGeneratedTags': tags,
      'isProcessed': true,
    });
  }

  Future<void> updateTranscription(String diaryId, String transcription) async {
    await _firestore.collection(_collection).doc(diaryId).update({
      'transcription': transcription,
    });
  }

  Future<void> updateSentimentAnalysis(
    String diaryId,
    Map<String, dynamic> analysis,
  ) async {
    await _firestore.collection(_collection).doc(diaryId).update({
      'sentimentAnalysis': analysis,
    });
  }

  Future<Map<String, dynamic>> getVideoDiaryStatistics(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final diaries = snapshot.docs.map((doc) => VideoDiary.fromFirestore(doc)).toList();

    if (diaries.isEmpty) {
      return {
        'totalDiaries': 0,
        'totalDuration': 0,
        'categoryDistribution': <String, int>{},
      };
    }

    int totalDuration = 0;
    final categoryDistribution = <String, int>{};

    for (final diary in diaries) {
      totalDuration += diary.durationSeconds;
      final categoryName = diary.category.name;
      categoryDistribution[categoryName] = (categoryDistribution[categoryName] ?? 0) + 1;
    }

    return {
      'totalDiaries': diaries.length,
      'totalDuration': totalDuration,
      'categoryDistribution': categoryDistribution,
    };
  }
}
