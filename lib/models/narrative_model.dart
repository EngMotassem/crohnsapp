import 'package:cloud_firestore/cloud_firestore.dart';

enum NarrativeCategory {
  diseaseChallenge,
  flareEvent,
  treatmentJourney,
  personalGoal,
  copingStrategy,
  lifestyleChange,
  emotionalJourney,
  milestone,
  other,
}

class Narrative {
  final String id;
  final String oderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String content;
  final NarrativeCategory category;
  final List<String> tags;
  final List<String> aiGeneratedTags;
  final bool isDraft;
  final int wordCount;
  final Map<String, dynamic>? sentimentAnalysis;
  final List<String> relatedSymptomIds;
  final List<String> relatedMedicationIds;

  Narrative({
    required this.id,
    required this.oderId,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.content,
    required this.category,
    this.tags = const [],
    this.aiGeneratedTags = const [],
    this.isDraft = false,
    this.wordCount = 0,
    this.sentimentAnalysis,
    this.relatedSymptomIds = const [],
    this.relatedMedicationIds = const [],
  });

  factory Narrative.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Narrative(
      id: doc.id,
      oderId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: NarrativeCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => NarrativeCategory.other,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      aiGeneratedTags: List<String>.from(data['aiGeneratedTags'] ?? []),
      isDraft: data['isDraft'] ?? false,
      wordCount: data['wordCount'] ?? 0,
      sentimentAnalysis: data['sentimentAnalysis'] as Map<String, dynamic>?,
      relatedSymptomIds: List<String>.from(data['relatedSymptomIds'] ?? []),
      relatedMedicationIds:
          List<String>.from(data['relatedMedicationIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'title': title,
      'content': content,
      'category': category.name,
      'tags': tags,
      'aiGeneratedTags': aiGeneratedTags,
      'isDraft': isDraft,
      'wordCount': wordCount,
      'sentimentAnalysis': sentimentAnalysis,
      'relatedSymptomIds': relatedSymptomIds,
      'relatedMedicationIds': relatedMedicationIds,
    };
  }

  Narrative copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? content,
    NarrativeCategory? category,
    List<String>? tags,
    List<String>? aiGeneratedTags,
    bool? isDraft,
    int? wordCount,
    Map<String, dynamic>? sentimentAnalysis,
    List<String>? relatedSymptomIds,
    List<String>? relatedMedicationIds,
  }) {
    return Narrative(
      id: id ?? this.id,
      oderId: userId ?? this.oderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      aiGeneratedTags: aiGeneratedTags ?? this.aiGeneratedTags,
      isDraft: isDraft ?? this.isDraft,
      wordCount: wordCount ?? this.wordCount,
      sentimentAnalysis: sentimentAnalysis ?? this.sentimentAnalysis,
      relatedSymptomIds: relatedSymptomIds ?? this.relatedSymptomIds,
      relatedMedicationIds: relatedMedicationIds ?? this.relatedMedicationIds,
    );
  }
}
