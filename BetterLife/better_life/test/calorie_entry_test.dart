import 'package:better_life/models/calorie_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalorieIngredient', () {
    test('calculates calories from grams', () {
      const ingredient = CalorieIngredient(
        fdcId: 1,
        name: 'Rice',
        grams: 150,
        caloriesPerBasis: 130,
        gramsBasis: 100,
      );

      expect(ingredient.calories, 195);
    });

    test('serializes ingredient details', () {
      const ingredient = CalorieIngredient(
        fdcId: 2,
        name: 'Chicken',
        grams: 200,
        caloriesPerBasis: 165,
        gramsBasis: 100,
      );

      final map = ingredient.toMap();
      expect(map['fdcId'], 2);
      expect(map['name'], 'Chicken');
      expect(map['grams'], 200);
      expect(map['calories'], 330);
    });
  });

  group('CalorieEntry', () {
    test('uses single ingredient as default name', () {
      final entry = CalorieEntry(
        id: '',
        calories: 52,
        date: DateTime(2026),
        note: '',
        ingredients: const [
          CalorieIngredient(
            fdcId: 3,
            name: 'Apple',
            grams: 100,
            caloriesPerBasis: 52,
            gramsBasis: 100,
          ),
        ],
      );

      expect(entry.effectiveName, 'Apple');
    });

    test('uses custom meal name when provided', () {
      final entry = CalorieEntry(
        id: '',
        calories: 525,
        date: DateTime(2026),
        note: '',
        name: 'Lunch bowl',
        ingredients: const [
          CalorieIngredient(
            fdcId: 4,
            name: 'Chicken',
            grams: 200,
            caloriesPerBasis: 165,
            gramsBasis: 100,
          ),
          CalorieIngredient(
            fdcId: 5,
            name: 'Rice',
            grams: 150,
            caloriesPerBasis: 130,
            gramsBasis: 100,
          ),
        ],
      );

      expect(entry.effectiveName, 'Lunch bowl');
    });
  });
}
