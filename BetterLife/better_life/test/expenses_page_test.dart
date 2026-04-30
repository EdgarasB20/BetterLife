import 'dart:async';

import 'package:better_life/models/expense.dart';
import 'package:better_life/pages/expenses_page.dart';
import 'package:better_life/services/expense_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpensesPage', () {
    late FakeExpenseService expenseService;

    setUp(() {
      expenseService = FakeExpenseService();
    });

    tearDown(() async {
      await expenseService.close();
    });

    testWidgets('shows sign-in prompt when user is missing', (tester) async {
      await pumpExpensesPage(tester, expenseService, uid: null);

      expect(find.text('Pirma prisijunk'), findsOneWidget);
      expect(find.text('Išlaidos'), findsNothing);
      expect(expenseService.watchedUid, isNull);
    });

    testWidgets('renders monthly expenses summary and list items', (
      tester,
    ) async {
      await pumpExpensesPage(tester, expenseService);

      expenseService.emit([
        testExpense(
          id: 'food',
          amount: 15.5,
          note: 'Maxima',
          category: ExpenseCategory.food,
          date: DateTime(2026, 4, 18),
        ),
        testExpense(
          id: 'transport',
          amount: 7,
          note: 'Bolt',
          category: ExpenseCategory.transport,
          date: DateTime(2026, 4, 19),
        ),
        testExpense(
          id: 'bills',
          amount: 20,
          note: 'Internetas',
          category: ExpenseCategory.bills,
          date: DateTime(2026, 4, 17),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(expenseService.watchedUid, 'user-1');
      expect(expenseService.watchedMonth, DateTime(2026, 4));
      expect(find.text('Išlaidos'), findsOneWidget);
      expect(find.text('€42.50'), findsOneWidget);
      expect(find.text('Maxima'), findsOneWidget);
      expect(find.text('Bolt'), findsOneWidget);
      expect(find.text('Internetas'), findsOneWidget);
      expect(find.text('-€15.50'), findsOneWidget);
    });

    testWidgets('filters expenses by category and clears filters', (
      tester,
    ) async {
      await pumpExpensesPage(tester, expenseService);

      expenseService.emit([
        testExpense(
          id: 'food',
          amount: 15.5,
          note: 'Maxima',
          category: ExpenseCategory.food,
          date: DateTime(2026, 4, 18),
        ),
        testExpense(
          id: 'transport',
          amount: 7,
          note: 'Bolt',
          category: ExpenseCategory.transport,
          date: DateTime(2026, 4, 19),
        ),
      ]);
      await tester.pumpAndSettle();

      final foodFilter = find.byKey(const ValueKey('expense-filter-food'));
      await tester.ensureVisible(foodFilter);
      await tester.tap(foodFilter);
      await tester.pumpAndSettle();

      expect(find.text('Maxima'), findsOneWidget);
      expect(find.text('Bolt'), findsNothing);
      expect(find.text('Aktyvios kategorijos: 1'), findsOneWidget);
      expect(find.text('€15.50'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('expense-clear-filters')));
      await tester.pumpAndSettle();

      expect(find.text('Maxima'), findsOneWidget);
      expect(find.text('Bolt'), findsOneWidget);
      expect(find.text('Rodomos visos kategorijos'), findsOneWidget);
    });

    testWidgets('sorts expenses by amount in both directions', (tester) async {
      await pumpExpensesPage(tester, expenseService);

      expenseService.emit([
        testExpense(
          id: 'cheap',
          amount: 5,
          note: 'Kava',
          category: ExpenseCategory.food,
          date: DateTime(2026, 4, 21),
        ),
        testExpense(
          id: 'expensive',
          amount: 100,
          note: 'Telefonas',
          category: ExpenseCategory.shopping,
          date: DateTime(2026, 4, 20),
        ),
      ]);
      await tester.pumpAndSettle();

      final sortDropdown = find.byKey(const ValueKey('expense-sort-criterion'));
      await tester.ensureVisible(sortDropdown);
      await tester.tap(sortDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suma').last);
      await tester.pumpAndSettle();

      expect(
        itemTop(tester, 'expense-item-expensive'),
        lessThan(itemTop(tester, 'expense-item-cheap')),
      );

      await tester.tap(find.byKey(const ValueKey('expense-sort-direction')));
      await tester.pumpAndSettle();

      expect(
        itemTop(tester, 'expense-item-cheap'),
        lessThan(itemTop(tester, 'expense-item-expensive')),
      );
    });

    testWidgets('adds an expense from the bottom sheet', (tester) async {
      await pumpExpensesPage(tester, expenseService);
      expenseService.emit([]);
      await tester.pump();

      await tester.tap(find.text('Pridėti'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '12,30');
      await tester.enterText(find.byType(TextFormField).at(1), 'Kava');

      final saveButton = find.widgetWithText(FilledButton, 'Išsaugoti');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(expenseService.addedUids, ['user-1']);
      expect(expenseService.addedExpenses, hasLength(1));
      expect(expenseService.addedExpenses.single.amount, 12.3);
      expect(expenseService.addedExpenses.single.note, 'Kava');
      expect(
        expenseService.addedExpenses.single.category,
        ExpenseCategory.food,
      );
      expect(find.text('Išlaida pridėta'), findsOneWidget);
    });

    testWidgets('opens receipt scanner from expenses page', (tester) async {
      await pumpExpensesPage(tester, expenseService);
      expenseService.emit([]);
      await tester.pumpAndSettle();

      final scanButton = find.byKey(const ValueKey('scan-receipt-button'));
      await tester.ensureVisible(scanButton);
      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      expect(find.text('Čekio skenavimas'), findsOneWidget);
      expect(find.text('Fotografuoti'), findsOneWidget);
      expect(find.text('Iš galerijos'), findsOneWidget);
    });

    testWidgets('deletes an expense after confirmation', (tester) async {
      await pumpExpensesPage(tester, expenseService);

      expenseService.emit([
        testExpense(
          id: 'food',
          amount: 15.5,
          note: 'Maxima',
          category: ExpenseCategory.food,
          date: DateTime(2026, 4, 18),
        ),
      ]);
      await tester.pumpAndSettle();

      final expenseMenu = find.byKey(const ValueKey('expense-menu-food'));
      await tester.ensureVisible(expenseMenu);
      await tester.tap(expenseMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ištrinti').last);
      await tester.pumpAndSettle();

      expect(find.text('Ištrinti išlaidą?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Ištrinti'));
      await tester.pumpAndSettle();

      expect(expenseService.deletedUids, ['user-1']);
      expect(expenseService.deletedExpenseIds, ['food']);
      expect(find.text('Išlaida ištrinta'), findsOneWidget);
    });
  });
}

Future<void> pumpExpensesPage(
  WidgetTester tester,
  FakeExpenseService expenseService, {
  String? uid = 'user-1',
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: ExpensesPage(
        expenseService: expenseService,
        currentUserId: () => uid,
        initialMonth: DateTime(2026, 4),
        profileAction: const SizedBox.shrink(),
      ),
    ),
  );
}

double itemTop(WidgetTester tester, String keyValue) {
  return tester.getTopLeft(find.byKey(ValueKey(keyValue))).dy;
}

Expense testExpense({
  required String id,
  required double amount,
  required String note,
  required ExpenseCategory category,
  required DateTime date,
}) {
  return Expense(
    id: id,
    amount: amount,
    note: note,
    category: category,
    date: date,
    createdAt: DateTime(2026, 4, 1, 12),
  );
}

class FakeExpenseService implements ExpenseService {
  final _controller = StreamController<List<Expense>>.broadcast();
  final addedUids = <String>[];
  final addedExpenses = <Expense>[];
  final updatedUids = <String>[];
  final updatedExpenseIds = <String>[];
  final updatedExpenses = <Expense>[];
  final deletedUids = <String>[];
  final deletedExpenseIds = <String>[];

  String? watchedUid;
  DateTime? watchedMonth;

  @override
  Stream<List<Expense>> watchMonthlyExpenses(String uid, DateTime month) {
    watchedUid = uid;
    watchedMonth = month;
    return _controller.stream;
  }

  void emit(List<Expense> expenses) {
    _controller.add(expenses);
  }

  Future<void> close() {
    return _controller.close();
  }

  @override
  Future<void> addExpense(String uid, Expense expense) async {
    addedUids.add(uid);
    addedExpenses.add(expense);
  }

  @override
  Future<void> updateExpense(
    String uid,
    String expenseId,
    Expense expense,
  ) async {
    updatedUids.add(uid);
    updatedExpenseIds.add(expenseId);
    updatedExpenses.add(expense);
  }

  @override
  Future<void> deleteExpense(String uid, String expenseId) async {
    deletedUids.add(uid);
    deletedExpenseIds.add(expenseId);
  }
}
