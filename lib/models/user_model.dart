import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, clinician, researcher, admin }

enum PrivacyLevel { private, anonymizedForResearch, sharedWithClinician }

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final PrivacySettings privacySettings;
  final String? clinicianId;
  final List<String> researchStudyIds;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    required this.privacySettings,
    this.clinicianId,
    this.researchStudyIds = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.patient,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      privacySettings: PrivacySettings.fromMap(
        data['privacySettings'] ?? {},
      ),
      clinicianId: data['clinicianId'],
      researchStudyIds: List<String>.from(data['researchStudyIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'privacySettings': privacySettings.toMap(),
      'clinicianId': clinicianId,
      'researchStudyIds': researchStudyIds,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    PrivacySettings? privacySettings,
    String? clinicianId,
    List<String>? researchStudyIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      privacySettings: privacySettings ?? this.privacySettings,
      clinicianId: clinicianId ?? this.clinicianId,
      researchStudyIds: researchStudyIds ?? this.researchStudyIds,
    );
  }
}

class PrivacySettings {
  final PrivacyLevel symptomsPrivacy;
  final PrivacyLevel medicationsPrivacy;
  final PrivacyLevel dietPrivacy;
  final PrivacyLevel moodPrivacy;
  final PrivacyLevel videoDiaryPrivacy;
  final PrivacyLevel narrativesPrivacy;
  final PrivacyLevel promsPrivacy;

  PrivacySettings({
    this.symptomsPrivacy = PrivacyLevel.private,
    this.medicationsPrivacy = PrivacyLevel.private,
    this.dietPrivacy = PrivacyLevel.private,
    this.moodPrivacy = PrivacyLevel.private,
    this.videoDiaryPrivacy = PrivacyLevel.private,
    this.narrativesPrivacy = PrivacyLevel.private,
    this.promsPrivacy = PrivacyLevel.private,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      symptomsPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.name == map['symptomsPrivacy'],
        orElse: () => PrivacyLevel.private,
      ),
      medicationsPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.name == map['medicationsPrivacy'],
        orElse: () => PrivacyLevel.private,
      ),
      dietPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.name == map['dietPrivacy'],
        orElse: () => PrivacyLevel.private,
      ),
      moodPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.name == map['moodPrivacy'],
        orElse: () => PrivacyLevel.private,
      ),
      videoDiaryPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.name == map['videoDiaryPrivacy'],
        orElse: () => PrivacyLevel.private,
      ),
      narrativesPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.name == map['narrativesPrivacy'],
        orElse: () => PrivacyLevel.private,
      ),
      promsPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.name == map['promsPrivacy'],
        orElse: () => PrivacyLevel.private,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'symptomsPrivacy': symptomsPrivacy.name,
      'medicationsPrivacy': medicationsPrivacy.name,
      'dietPrivacy': dietPrivacy.name,
      'moodPrivacy': moodPrivacy.name,
      'videoDiaryPrivacy': videoDiaryPrivacy.name,
      'narrativesPrivacy': narrativesPrivacy.name,
      'promsPrivacy': promsPrivacy.name,
    };
  }

  PrivacySettings copyWith({
    PrivacyLevel? symptomsPrivacy,
    PrivacyLevel? medicationsPrivacy,
    PrivacyLevel? dietPrivacy,
    PrivacyLevel? moodPrivacy,
    PrivacyLevel? videoDiaryPrivacy,
    PrivacyLevel? narrativesPrivacy,
    PrivacyLevel? promsPrivacy,
  }) {
    return PrivacySettings(
      symptomsPrivacy: symptomsPrivacy ?? this.symptomsPrivacy,
      medicationsPrivacy: medicationsPrivacy ?? this.medicationsPrivacy,
      dietPrivacy: dietPrivacy ?? this.dietPrivacy,
      moodPrivacy: moodPrivacy ?? this.moodPrivacy,
      videoDiaryPrivacy: videoDiaryPrivacy ?? this.videoDiaryPrivacy,
      narrativesPrivacy: narrativesPrivacy ?? this.narrativesPrivacy,
      promsPrivacy: promsPrivacy ?? this.promsPrivacy,
    );
  }
}
