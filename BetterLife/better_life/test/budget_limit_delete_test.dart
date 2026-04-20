import 'package:flutter_test/flutter_test.dart';

import 'package:better_life/models/budget.dart';
import 'package:better_life/models/expense.dart';

void main() {
  test('Biudžeto limito ištrynimo testas', () {
    final existing = Budget(
      id: 'b1',
      category: ExpenseCategory.food,
      limit: 150,
      monthKey: '2026-04',
    );

    // "Ištrynimas" - limitas nustatomas į 0
    final afterDelete = existing.copyWith(limit: 0);

    expect(existing.limit, 150);
    expect(afterDelete.limit, 0);
    expect(afterDelete.category, ExpenseCategory.food);
    expect(afterDelete.monthKey, '2026-04');
  });
}