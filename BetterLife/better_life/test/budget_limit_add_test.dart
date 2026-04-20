import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:better_life/models/budget.dart';
import 'package:better_life/models/expense.dart';
import 'package:better_life/pages/widgets/add_budget_sheet.dart';

void main() {
  testWidgets('Biudžeto limito pridėjimo testas', (tester) async {
    Budget? savedBudget;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddBudgetSheet(
                      category: ExpenseCategory.food,
                      month: DateTime(2026, 4, 1),
                      onSave: (budget) async {
                        savedBudget = budget;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biudžetas išsaugotas'),
                          ),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Atidaryti'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Atidaryti'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '150,00');
    await tester.tap(find.text('Išsaugoti'));
    await tester.pumpAndSettle();

    expect(savedBudget, isNotNull);
    expect(savedBudget!.category, ExpenseCategory.food);
    expect(savedBudget!.limit, 150.0);
    expect(savedBudget!.monthKey, '2026-04');
    expect(find.text('Biudžetas išsaugotas'), findsOneWidget);
  });
}