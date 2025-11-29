import 'package:cloud_firestore/cloud_firestore.dart';

enum VideoDiaryCategory {
  dailyReflection,
  flareExperience,
  copingStrategy,
  emotionalState,
  treatmentExperience,
  milestone,
  other,
}

class VideoDiary {
  final String id;
  final String oderId;
  final DateTime timestamp;
  final String videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final VideoDiaryCategory category;
  final String title;
  final String? description;
  final List<String> tags;
  final List<String> aiGeneratedTags;
  final String? transcription;
  final bool isProcessed;
  final Map<String, dynamic>? sentimentAnalysis;

  VideoDiary({
    required this.id,
    required this.oderId,
    required this.timestamp,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.category,
    required this.title,
    this.description,
    this.tags = const [],
    this.aiGeneratedTags = const [],
    this.transcription,
    this.isProcessed = false,
    this.sentimentAnalysis,
  });

  factory VideoDiary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoDiary(
      id: doc.id,
      oderId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      durationSeconds: data['durationSeconds'] ?? 0,
      category: VideoDiaryCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => VideoDiaryCategory.other,
      ),
      title: data['title'] ?? '',
      description: data['description'],
      tags: List<String>.from(data['tags'] ?? []),
      aiGeneratedTags: List<String>.from(data['aiGeneratedTags'] ?? []),
      transcription: data['transcription'],
      isProcessed: data['isProcessed'] ?? false,
      sentimentAnalysis: data['sentimentAnalysis'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'category': category.name,
      'title': title,
      'description': description,
      'tags': tags,
      'aiGeneratedTags': aiGeneratedTags,
      'transcription': transcription,
      'isProcessed': isProcessed,
      'sentimentAnalysis': sentimentAnalysis,
    };
  }

  VideoDiary copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    VideoDiaryCategory? category,
    String? title,
    String? description,
    List<String>? tags,
    List<String>? aiGeneratedTags,
    String? transcription,
    bool? isProcessed,
    Map<String, dynamic>? sentimentAnalysis,
  }) {
    return VideoDiary(
      id: id ?? this.id,
      oderId: userId ?? this.oderId,
      timestamp: timestamp ?? this.timestamp,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      aiGeneratedTags: aiGeneratedTags ?? this.aiGeneratedTags,
      transcription: transcription ?? this.transcription,
      isProcessed: isProcessed ?? this.isProcessed,
      sentimentAnalysis: sentimentAnalysis ?? this.sentimentAnalysis,
    );
  }
}
