import 'dart:async';

import 'package:better_life/models/income.dart';
import 'package:better_life/pages/income_page.dart';
import 'package:better_life/services/income_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IncomePage', () {
    late FakeIncomeService incomeService;

    setUp(() {
      incomeService = FakeIncomeService();
    });

    tearDown(() async {
      await incomeService.close();
    });

    testWidgets('shows sign-in prompt when user is missing', (tester) async {
      await pumpIncomePage(tester, incomeService, uid: null);

      expect(find.text('Pirma prisijunk'), findsOneWidget);
      expect(find.text('Pajamos'), findsNothing);
      expect(incomeService.watchedUid, isNull);
    });

    testWidgets('renders monthly income summary and list items', (
      tester,
    ) async {
      await pumpIncomePage(tester, incomeService);

      incomeService.emit([
        testIncome(
          id: 'salary',
          amount: 1200,
          note: 'Alga',
          category: IncomeCategory.salary,
          date: DateTime(2026, 4, 18),
        ),
        testIncome(
          id: 'bonus',
          amount: 150,
          note: 'Metine premija',
          category: IncomeCategory.bonus,
          date: DateTime(2026, 4, 19),
        ),
        testIncome(
          id: 'old',
          amount: 50,
          note: 'Sena',
          category: IncomeCategory.other,
          date: DateTime(2026, 3, 28),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(incomeService.watchedUid, 'user-1');
      expect(find.text('Pajamos'), findsOneWidget);
      expect(find.text('Alga'), findsOneWidget);
      expect(find.text('Metine premija'), findsOneWidget);
      expect(find.text('Sena'), findsNothing);
      expect(find.textContaining('1350.00'), findsOneWidget);
      expect(find.textContaining('+'), findsWidgets);
    });

    testWidgets('sorts incomes by amount in both directions', (tester) async {
      await pumpIncomePage(tester, incomeService);

      incomeService.emit([
        testIncome(
          id: 'small',
          amount: 120,
          note: 'Smulki premija',
          category: IncomeCategory.bonus,
          date: DateTime(2026, 4, 21),
        ),
        testIncome(
          id: 'large',
          amount: 2200,
          note: 'Atlyginimas',
          category: IncomeCategory.salary,
          date: DateTime(2026, 4, 20),
        ),
      ]);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('income-sort-field')));
      await tester.tap(find.byKey(const ValueKey('income-sort-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suma').last);
      await tester.pumpAndSettle();

      expect(
        itemTop(tester, 'income-item-large'),
        lessThan(itemTop(tester, 'income-item-small')),
      );

      await tester.tap(find.byKey(const ValueKey('income-sort-direction')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Did').last);
      await tester.pumpAndSettle();

      expect(
        itemTop(tester, 'income-item-small'),
        lessThan(itemTop(tester, 'income-item-large')),
      );
    });

    testWidgets('adds an income from the bottom sheet', (tester) async {
      await pumpIncomePage(tester, incomeService);
      incomeService.emit([]);
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '250,75');
      await tester.enterText(find.byType(TextFormField).at(1), 'Laisvai samdomas darbas');

      await tester.ensureVisible(find.byType(FilledButton).last);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      expect(incomeService.addedUids, ['user-1']);
      expect(incomeService.addedIncomes, hasLength(1));
      expect(incomeService.addedIncomes.single.amount, 250.75);
      expect(incomeService.addedIncomes.single.note, 'Laisvai samdomas darbas');
      expect(incomeService.addedIncomes.single.category, IncomeCategory.salary);
    });

    testWidgets('deletes an income after confirmation', (tester) async {
      await pumpIncomePage(tester, incomeService);

      incomeService.emit([
        testIncome(
          id: 'salary',
          amount: 1200,
          note: 'Alga',
          category: IncomeCategory.salary,
          date: DateTime(2026, 4, 18),
        ),
      ]);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('income-menu-salary')));
      await tester.tap(find.byKey(const ValueKey('income-menu-salary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuItem<String>).last);
      await tester.pumpAndSettle();

      expect(find.textContaining('pajam'), findsOneWidget);

      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      expect(incomeService.deletedUids, ['user-1']);
      expect(incomeService.deletedIncomeIds, ['salary']);
    });
  });
}

Future<void> pumpIncomePage(
  WidgetTester tester,
  FakeIncomeService incomeService, {
  String? uid = 'user-1',
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: IncomePage(
        incomeService: incomeService,
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

Income testIncome({
  required String id,
  required double amount,
  required String note,
  required IncomeCategory category,
  required DateTime date,
}) {
  return Income(
    id: id,
    amount: amount,
    note: note,
    category: category,
    date: date,
    createdAt: DateTime(2026, 4, 1, 12),
  );
}

class FakeIncomeService implements IncomeService {
  final _controller = StreamController<List<Income>>.broadcast();
  final addedUids = <String>[];
  final addedIncomes = <Income>[];
  final updatedUids = <String>[];
  final updatedIncomeIds = <String>[];
  final updatedIncomes = <Income>[];
  final deletedUids = <String>[];
  final deletedIncomeIds = <String>[];

  String? watchedUid;
  DateTime? watchedStart;

  @override
  Stream<List<Income>> watchIncomesSince(String uid, DateTime start) {
    watchedUid = uid;
    watchedStart = start;
    return _controller.stream;
  }

  void emit(List<Income> incomes) {
    _controller.add(incomes);
  }

  Future<void> close() {
    return _controller.close();
  }

  @override
  Future<void> addIncome(String uid, Income income) async {
    addedUids.add(uid);
    addedIncomes.add(income);
  }

  @override
  Future<void> updateIncome(String uid, String incomeId, Income income) async {
    updatedUids.add(uid);
    updatedIncomeIds.add(incomeId);
    updatedIncomes.add(income);
  }

  @override
  Future<void> deleteIncome(String uid, String incomeId) async {
    deletedUids.add(uid);
    deletedIncomeIds.add(incomeId);
  }

  @override
  Future<List<Income>> getAllIncomes(String uid) async => [];

  @override
  Stream<List<Income>> watchAllIncomes(String uid) => _controller.stream;

  @override
  Stream<List<Income>> watchMonthlyIncomes(String uid, DateTime month) =>
      _controller.stream;
}
