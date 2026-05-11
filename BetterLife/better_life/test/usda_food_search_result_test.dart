import 'package:better_life/models/usda_food_search_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsdaFoodSearchPage.fromJson', () {
    test('parses USDA search results with kcal and pagination data', () {
      final page = UsdaFoodSearchPage.fromJson({
        'totalHits': 42,
        'currentPage': 2,
        'totalPages': 5,
        'foods': [
          {
            'fdcId': 123,
            'description': 'Cheddar cheese',
            'servingSize': 100,
            'servingSizeUnit': 'g',
            'foodNutrients': [
              {'nutrientId': 1008, 'nutrientName': 'Energy', 'value': 403},
            ],
          },
        ],
      });

      expect(page.totalHits, 42);
      expect(page.currentPage, 2);
      expect(page.totalPages, 5);
      expect(page.foods.single.fdcId, 123);
      expect(page.foods.single.description, 'Cheddar cheese');
      expect(page.foods.single.calories, 403);
      expect(page.foods.single.calorieBasis, 'per 100 g');
      expect(page.foods.single.caloriesText, '403 kcal');
      expect(page.foods.single.gramsBasis, 100);
      expect(page.foods.single.caloriesForGrams(50), 201.5);
    });

    test('handles missing calorie data', () {
      final page = UsdaFoodSearchPage.fromJson({
        'foods': [
          {'fdcId': 456, 'description': 'Mystery food'},
        ],
      });

      expect(page.foods.single.calories, isNull);
      expect(page.foods.single.caloriesText, 'N/A');
      expect(page.foods.single.calorieBasis, 'per 100g');
      expect(page.foods.single.caloriesForGrams(100), isNull);
    });
  });
}
