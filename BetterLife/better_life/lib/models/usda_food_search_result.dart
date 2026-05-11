class UsdaFoodSearchPage {
  final List<UsdaFoodSearchResult> foods;
  final int totalHits;
  final int currentPage;
  final int totalPages;

  const UsdaFoodSearchPage({
    required this.foods,
    required this.totalHits,
    required this.currentPage,
    required this.totalPages,
  });

  factory UsdaFoodSearchPage.fromJson(Map<String, dynamic> json) {
    final foodsJson = json['foods'];
    final foods = foodsJson is List
        ? foodsJson
              .whereType<Map<String, dynamic>>()
              .map(UsdaFoodSearchResult.fromJson)
              .toList()
        : <UsdaFoodSearchResult>[];

    return UsdaFoodSearchPage(
      foods: foods,
      totalHits: (json['totalHits'] as num?)?.toInt() ?? foods.length,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  factory UsdaFoodSearchPage.fromCacheMap(
    Map<String, dynamic> data,
    List<UsdaFoodSearchResult> foods,
  ) {
    return UsdaFoodSearchPage(
      foods: foods,
      totalHits: (data['totalHits'] as num?)?.toInt() ?? foods.length,
      currentPage: (data['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class UsdaFoodSearchResult {
  final int fdcId;
  final String description;
  final double? calories;
  final String calorieBasis;
  final double gramsBasis;

  const UsdaFoodSearchResult({
    required this.fdcId,
    required this.description,
    required this.calories,
    required this.calorieBasis,
    required this.gramsBasis,
  });

  factory UsdaFoodSearchResult.fromJson(Map<String, dynamic> json) {
    final gramsBasis = _readGramsBasis(json);

    return UsdaFoodSearchResult(
      fdcId: (json['fdcId'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?)?.trim().isNotEmpty == true
          ? (json['description'] as String).trim()
          : 'Unknown food',
      calories: _readCalories(json['foodNutrients']),
      calorieBasis: _readServingBasis(json, gramsBasis),
      gramsBasis: gramsBasis,
    );
  }

  factory UsdaFoodSearchResult.fromCacheMap(Map<String, dynamic> data) {
    return UsdaFoodSearchResult(
      fdcId: (data['fdcId'] as num?)?.toInt() ?? 0,
      description: (data['description'] as String?)?.trim().isNotEmpty == true
          ? (data['description'] as String).trim()
          : 'Unknown food',
      calories: (data['calories'] as num?)?.toDouble(),
      calorieBasis: (data['calorieBasis'] as String?)?.trim().isNotEmpty == true
          ? (data['calorieBasis'] as String).trim()
          : 'per 100g',
      gramsBasis: (data['gramsBasis'] as num?)?.toDouble() ?? 100,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'fdcId': fdcId,
      'description': description,
      'calories': calories,
      'calorieBasis': calorieBasis,
      'gramsBasis': gramsBasis,
    };
  }

  String get caloriesText {
    if (calories == null) return 'N/A';
    final rounded = calories!.roundToDouble() == calories
        ? calories!.toStringAsFixed(0)
        : calories!.toStringAsFixed(1);
    return '$rounded kcal';
  }

  static double? _readCalories(Object? nutrients) {
    if (nutrients is! List) return null;

    for (final item in nutrients.whereType<Map<String, dynamic>>()) {
      final nutrientId = (item['nutrientId'] as num?)?.toInt();
      final unit = (item['unitName'] as String?)?.toUpperCase();
      final name = (item['nutrientName'] as String?)?.toLowerCase();
      final value = item['value'];

      final isCalories =
          nutrientId == 1008 ||
          unit == 'KCAL' ||
          (name != null && name.contains('energy'));

      if (isCalories && value is num) {
        return value.toDouble();
      }
    }

    return null;
  }

  double? caloriesForGrams(double grams) {
    if (calories == null || grams <= 0 || gramsBasis <= 0) return null;
    return calories! * grams / gramsBasis;
  }

  static double _readGramsBasis(Map<String, dynamic> json) {
    final servingSize = json['servingSize'];
    final servingUnit = json['servingSizeUnit'];
    if (servingSize is num &&
        servingSize > 0 &&
        servingUnit is String &&
        servingUnit.trim().toLowerCase() == 'g') {
      return servingSize.toDouble();
    }

    return 100;
  }

  static String _readServingBasis(
    Map<String, dynamic> json,
    double gramsBasis,
  ) {
    final servingSize = json['servingSize'];
    final servingUnit = json['servingSizeUnit'];
    if (servingSize is num && servingUnit is String && servingUnit.isNotEmpty) {
      final size = servingSize.roundToDouble() == servingSize
          ? servingSize.toStringAsFixed(0)
          : servingSize.toStringAsFixed(1);
      return 'per $size $servingUnit';
    }

    final householdServing = json['householdServingFullText'];
    if (householdServing is String && householdServing.trim().isNotEmpty) {
      return householdServing.trim();
    }

    final size = gramsBasis.roundToDouble() == gramsBasis
        ? gramsBasis.toStringAsFixed(0)
        : gramsBasis.toStringAsFixed(1);
    return 'per ${size}g';
  }
}
