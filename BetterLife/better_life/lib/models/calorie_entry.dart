import 'package:cloud_firestore/cloud_firestore.dart';

import 'usda_food_search_result.dart';

class CalorieIngredient {
  final int fdcId;
  final String name;
  final double grams;
  final double caloriesPerBasis;
  final double gramsBasis;

  const CalorieIngredient({
    required this.fdcId,
    required this.name,
    required this.grams,
    required this.caloriesPerBasis,
    required this.gramsBasis,
  });

  factory CalorieIngredient.fromFood(
    UsdaFoodSearchResult food, {
    double grams = 100,
  }) {
    return CalorieIngredient(
      fdcId: food.fdcId,
      name: food.description,
      grams: grams,
      caloriesPerBasis: food.calories ?? 0,
      gramsBasis: food.gramsBasis,
    );
  }

  double get calories {
    if (grams <= 0 || gramsBasis <= 0) return 0;
    return caloriesPerBasis * grams / gramsBasis;
  }

  Map<String, dynamic> toMap() {
    return {
      'fdcId': fdcId,
      'name': name.trim(),
      'grams': grams,
      'caloriesPerBasis': caloriesPerBasis,
      'gramsBasis': gramsBasis,
      'calories': calories,
    };
  }

  factory CalorieIngredient.fromMap(Map<String, dynamic> data) {
    return CalorieIngredient(
      fdcId: (data['fdcId'] as num?)?.toInt() ?? 0,
      name: data['name'] as String? ?? '',
      grams: (data['grams'] as num?)?.toDouble() ?? 0,
      caloriesPerBasis: (data['caloriesPerBasis'] as num?)?.toDouble() ?? 0,
      gramsBasis: (data['gramsBasis'] as num?)?.toDouble() ?? 100,
    );
  }
}

class CalorieEntry {
  final String id;
  final int calories;
  final DateTime date;
  final String note;
  final String name;
  final List<CalorieIngredient> ingredients;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CalorieEntry({
    required this.id,
    required this.calories,
    required this.date,
    required this.note,
    this.name = '',
    this.ingredients = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'date': Timestamp.fromDate(date),
      'note': note.trim(),
      'name': effectiveName,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get effectiveName {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) return trimmedName;
    if (ingredients.length == 1) return ingredients.single.name.trim();
    return note.trim();
  }

  factory CalorieEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ingredientsJson = data['ingredients'];
    final ingredients = ingredientsJson is List
        ? ingredientsJson
              .whereType<Map<String, dynamic>>()
              .map(CalorieIngredient.fromMap)
              .toList()
        : <CalorieIngredient>[];

    return CalorieEntry(
      id: doc.id,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String? ?? '',
      name: data['name'] as String? ?? '',
      ingredients: ingredients,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
