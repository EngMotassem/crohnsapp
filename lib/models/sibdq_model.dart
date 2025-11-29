import 'package:cloud_firestore/cloud_firestore.dart';

class SIBDQResponse {
  final String id;
  final String oderId;
  final DateTime timestamp;
  final int bowelFrequencyScore;
  final int looseStoolsScore;
  final int abdominalPainScore;
  final int generalWellbeingScore;
  final int energyLevelScore;
  final int socialActivityScore;
  final int emotionalHealthScore;
  final int sleepQualityScore;
  final int angerScore;
  final int embarrassmentScore;
  final String? notes;

  SIBDQResponse({
    required this.id,
    required this.oderId,
    required this.timestamp,
    required this.bowelFrequencyScore,
    required this.looseStoolsScore,
    required this.abdominalPainScore,
    required this.generalWellbeingScore,
    required this.energyLevelScore,
    required this.socialActivityScore,
    required this.emotionalHealthScore,
    required this.sleepQualityScore,
    required this.angerScore,
    required this.embarrassmentScore,
    this.notes,
  });

  int get totalScore {
    return bowelFrequencyScore +
        looseStoolsScore +
        abdominalPainScore +
        generalWellbeingScore +
        energyLevelScore +
        socialActivityScore +
        emotionalHealthScore +
        sleepQualityScore +
        angerScore +
        embarrassmentScore;
  }

  int get bowelSymptomsDomain {
    return bowelFrequencyScore + looseStoolsScore + abdominalPainScore;
  }

  int get systemicSymptomsDomain {
    return generalWellbeingScore + energyLevelScore;
  }

  int get socialFunctionDomain {
    return socialActivityScore;
  }

  int get emotionalFunctionDomain {
    return emotionalHealthScore + sleepQualityScore + angerScore + embarrassmentScore;
  }

  factory SIBDQResponse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SIBDQResponse(
      id: doc.id,
      oderId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      bowelFrequencyScore: data['bowelFrequencyScore'] ?? 1,
      looseStoolsScore: data['looseStoolsScore'] ?? 1,
      abdominalPainScore: data['abdominalPainScore'] ?? 1,
      generalWellbeingScore: data['generalWellbeingScore'] ?? 1,
      energyLevelScore: data['energyLevelScore'] ?? 1,
      socialActivityScore: data['socialActivityScore'] ?? 1,
      emotionalHealthScore: data['emotionalHealthScore'] ?? 1,
      sleepQualityScore: data['sleepQualityScore'] ?? 1,
      angerScore: data['angerScore'] ?? 1,
      embarrassmentScore: data['embarrassmentScore'] ?? 1,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'bowelFrequencyScore': bowelFrequencyScore,
      'looseStoolsScore': looseStoolsScore,
      'abdominalPainScore': abdominalPainScore,
      'generalWellbeingScore': generalWellbeingScore,
      'energyLevelScore': energyLevelScore,
      'socialActivityScore': socialActivityScore,
      'emotionalHealthScore': emotionalHealthScore,
      'sleepQualityScore': sleepQualityScore,
      'angerScore': angerScore,
      'embarrassmentScore': embarrassmentScore,
      'totalScore': totalScore,
      'bowelSymptomsDomain': bowelSymptomsDomain,
      'systemicSymptomsDomain': systemicSymptomsDomain,
      'socialFunctionDomain': socialFunctionDomain,
      'emotionalFunctionDomain': emotionalFunctionDomain,
      'notes': notes,
    };
  }

  SIBDQResponse copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    int? bowelFrequencyScore,
    int? looseStoolsScore,
    int? abdominalPainScore,
    int? generalWellbeingScore,
    int? energyLevelScore,
    int? socialActivityScore,
    int? emotionalHealthScore,
    int? sleepQualityScore,
    int? angerScore,
    int? embarrassmentScore,
    String? notes,
  }) {
    return SIBDQResponse(
      id: id ?? this.id,
      oderId: userId ?? this.oderId,
      timestamp: timestamp ?? this.timestamp,
      bowelFrequencyScore: bowelFrequencyScore ?? this.bowelFrequencyScore,
      looseStoolsScore: looseStoolsScore ?? this.looseStoolsScore,
      abdominalPainScore: abdominalPainScore ?? this.abdominalPainScore,
      generalWellbeingScore:
          generalWellbeingScore ?? this.generalWellbeingScore,
      energyLevelScore: energyLevelScore ?? this.energyLevelScore,
      socialActivityScore: socialActivityScore ?? this.socialActivityScore,
      emotionalHealthScore: emotionalHealthScore ?? this.emotionalHealthScore,
      sleepQualityScore: sleepQualityScore ?? this.sleepQualityScore,
      angerScore: angerScore ?? this.angerScore,
      embarrassmentScore: embarrassmentScore ?? this.embarrassmentScore,
      notes: notes ?? this.notes,
    );
  }
}

class SIBDQQuestion {
  final int questionNumber;
  final String questionText;
  final String domain;
  final List<String> answerOptions;

  const SIBDQQuestion({
    required this.questionNumber,
    required this.questionText,
    required this.domain,
    required this.answerOptions,
  });
}

const List<SIBDQQuestion> sibdqQuestions = [
  SIBDQQuestion(
    questionNumber: 1,
    questionText:
        'How often has bowel frequency been a problem for you during the last 2 weeks?',
    domain: 'Bowel Symptoms',
    answerOptions: [
      'All of the time',
      'Most of the time',
      'A good bit of the time',
      'Some of the time',
      'A little of the time',
      'Hardly any of the time',
      'None of the time',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 2,
    questionText:
        'How often has the problem of loose stools or diarrhea been a problem during the last 2 weeks?',
    domain: 'Bowel Symptoms',
    answerOptions: [
      'All of the time',
      'Most of the time',
      'A good bit of the time',
      'Some of the time',
      'A little of the time',
      'Hardly any of the time',
      'None of the time',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 3,
    questionText:
        'How much of the time during the last 2 weeks have you been troubled by pain in the abdomen?',
    domain: 'Bowel Symptoms',
    answerOptions: [
      'All of the time',
      'Most of the time',
      'A good bit of the time',
      'Some of the time',
      'A little of the time',
      'Hardly any of the time',
      'None of the time',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 4,
    questionText:
        'Overall, in the last 2 weeks, how much of a problem have you had with passing large amounts of gas?',
    domain: 'Systemic Symptoms',
    answerOptions: [
      'A very big problem',
      'A big problem',
      'A significant problem',
      'Some trouble',
      'A little trouble',
      'Hardly any trouble',
      'No trouble',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 5,
    questionText:
        'How often during the last 2 weeks have you felt fatigued or tired and worn out?',
    domain: 'Systemic Symptoms',
    answerOptions: [
      'All of the time',
      'Most of the time',
      'A good bit of the time',
      'Some of the time',
      'A little of the time',
      'Hardly any of the time',
      'None of the time',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 6,
    questionText:
        'How often during the last 2 weeks have you had to avoid attending events or activities because there was no washroom nearby?',
    domain: 'Social Function',
    answerOptions: [
      'All of the time',
      'Most of the time',
      'A good bit of the time',
      'Some of the time',
      'A little of the time',
      'Hardly any of the time',
      'None of the time',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 7,
    questionText:
        'Overall, in the last 2 weeks, how much of a problem have you had maintaining or getting to the weight you would like to be?',
    domain: 'Emotional Function',
    answerOptions: [
      'A very big problem',
      'A big problem',
      'A significant problem',
      'Some trouble',
      'A little trouble',
      'Hardly any trouble',
      'No trouble',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 8,
    questionText:
        'How often during the last 2 weeks have you felt relaxed and free of tension?',
    domain: 'Emotional Function',
    answerOptions: [
      'None of the time',
      'A little of the time',
      'Some of the time',
      'A good bit of the time',
      'Most of the time',
      'Almost all of the time',
      'All of the time',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 9,
    questionText:
        'How much of the time during the last 2 weeks have you been troubled by a feeling of having to go to the bathroom even though your bowels were empty?',
    domain: 'Emotional Function',
    answerOptions: [
      'All of the time',
      'Most of the time',
      'A good bit of the time',
      'Some of the time',
      'A little of the time',
      'Hardly any of the time',
      'None of the time',
    ],
  ),
  SIBDQQuestion(
    questionNumber: 10,
    questionText:
        'How much of the time during the last 2 weeks have you felt angry as a result of your bowel problem?',
    domain: 'Emotional Function',
    answerOptions: [
      'All of the time',
      'Most of the time',
      'A good bit of the time',
      'Some of the time',
      'A little of the time',
      'Hardly any of the time',
      'None of the time',
    ],
  ),
];
