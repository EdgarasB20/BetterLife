import 'package:better_life/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense model', () {
    test('maps stored category names to enum values', () {
      final cases = <String, ExpenseCategory>{
        'food': ExpenseCategory.food,
        'transport': ExpenseCategory.transport,
        'shopping': ExpenseCategory.shopping,
        'bills': ExpenseCategory.bills,
        'health': ExpenseCategory.health,
        'entertainment': ExpenseCategory.entertainment,
        'other': ExpenseCategory.other,
      };

      for (final entry in cases.entries) {
        expect(expenseCategoryFromString(entry.key), entry.value);
      }
    });

    test('falls back to other category for unknown stored values', () {
      expect(expenseCategoryFromString(null), ExpenseCategory.other);
      expect(expenseCategoryFromString('unexpected'), ExpenseCategory.other);
    });

    test('copyWith changes selected fields and keeps the rest', () {
      final original = Expense(
        id: 'expense-1',
        amount: 10,
        note: 'Lunch',
        category: ExpenseCategory.food,
        date: DateTime(2026, 4, 1),
      );

      final updated = original.copyWith(
        amount: 12.5,
        note: 'Dinner',
        category: ExpenseCategory.entertainment,
      );

      expect(updated.id, original.id);
      expect(updated.date, original.date);
      expect(updated.amount, 12.5);
      expect(updated.note, 'Dinner');
      expect(updated.category, ExpenseCategory.entertainment);
    });
  });
}
