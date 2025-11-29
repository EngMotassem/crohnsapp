import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType { breakfast, lunch, dinner, snack }

enum FoodCategory {
  dairy,
  grains,
  protein,
  vegetables,
  fruits,
  fats,
  beverages,
  processed,
  other,
}

class DietEntry {
  final String id;
  final String oderId;
  final DateTime timestamp;
  final MealType mealType;
  final List<FoodItem> foods;
  final int waterIntake;
  final bool triggeredSymptoms;
  final List<String> symptomTags;
  final String? notes;
  final String? photoUrl;

  DietEntry({
    required this.id,
    required this.oderId,
    required this.timestamp,
    required this.mealType,
    this.foods = const [],
    this.waterIntake = 0,
    this.triggeredSymptoms = false,
    this.symptomTags = const [],
    this.notes,
    this.photoUrl,
  });

  factory DietEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DietEntry(
      id: doc.id,
      oderId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      mealType: MealType.values.firstWhere(
        (e) => e.name == data['mealType'],
        orElse: () => MealType.snack,
      ),
      foods: (data['foods'] as List<dynamic>?)
              ?.map((f) => FoodItem.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
      waterIntake: data['waterIntake'] ?? 0,
      triggeredSymptoms: data['triggeredSymptoms'] ?? false,
      symptomTags: List<String>.from(data['symptomTags'] ?? []),
      notes: data['notes'],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': oderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'mealType': mealType.name,
      'foods': foods.map((f) => f.toMap()).toList(),
      'waterIntake': waterIntake,
      'triggeredSymptoms': triggeredSymptoms,
      'symptomTags': symptomTags,
      'notes': notes,
      'photoUrl': photoUrl,
    };
  }

  DietEntry copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    MealType? mealType,
    List<FoodItem>? foods,
    int? waterIntake,
    bool? triggeredSymptoms,
    List<String>? symptomTags,
    String? notes,
    String? photoUrl,
  }) {
    return DietEntry(
      id: id ?? this.id,
      oderId: userId ?? this.oderId,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      foods: foods ?? this.foods,
      waterIntake: waterIntake ?? this.waterIntake,
      triggeredSymptoms: triggeredSymptoms ?? this.triggeredSymptoms,
      symptomTags: symptomTags ?? this.symptomTags,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class FoodItem {
  final String name;
  final FoodCategory category;
  final String? portion;
  final bool isKnownTrigger;
  final List<String> ingredients;

  FoodItem({
    required this.name,
    required this.category,
    this.portion,
    this.isKnownTrigger = false,
    this.ingredients = const [],
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? '',
      category: FoodCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => FoodCategory.other,
      ),
      portion: map['portion'],
      isKnownTrigger: map['isKnownTrigger'] ?? false,
      ingredients: List<String>.from(map['ingredients'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'portion': portion,
      'isKnownTrigger': isKnownTrigger,
      'ingredients': ingredients,
    };
  }
}

class FoodTrigger {
  final String id;
  final String userId;
  final String foodName;
  final FoodCategory category;
  final int triggerCount;
  final DateTime firstIdentified;
  final DateTime lastTriggered;
  final List<String> associatedSymptoms;
  final String? notes;

  FoodTrigger({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.category,
    this.triggerCount = 1,
    required this.firstIdentified,
    required this.lastTriggered,
    this.associatedSymptoms = const [],
    this.notes,
  });

  factory FoodTrigger.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodTrigger(
      id: doc.id,
      userId: data['userId'] ?? '',
      foodName: data['foodName'] ?? '',
      category: FoodCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => FoodCategory.other,
      ),
      triggerCount: data['triggerCount'] ?? 1,
      firstIdentified: (data['firstIdentified'] as Timestamp).toDate(),
      lastTriggered: (data['lastTriggered'] as Timestamp).toDate(),
      associatedSymptoms: List<String>.from(data['associatedSymptoms'] ?? []),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'foodName': foodName,
      'category': category.name,
      'triggerCount': triggerCount,
      'firstIdentified': Timestamp.fromDate(firstIdentified),
      'lastTriggered': Timestamp.fromDate(lastTriggered),
      'associatedSymptoms': associatedSymptoms,
      'notes': notes,
    };
  }
}
