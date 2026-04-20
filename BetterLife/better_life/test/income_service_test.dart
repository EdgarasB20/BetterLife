import 'dart:async';

import 'package:better_life/models/income.dart';
import 'package:better_life/services/income_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IncomeService', () {
    late FakeFirebaseFirestore firestore;
    late IncomeService incomeService;
    const uid = 'user-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      incomeService = IncomeService(firestore: firestore);
    });

    tearDown(() async {
      await Future<void>.delayed(Duration.zero);
    });

    test('addIncome saves income document into Firestore', () async {
      final income = testIncome(
        id: '',
        amount: 1250.50,
        note: 'Balandzio alga',
        category: IncomeCategory.salary,
        date: DateTime(2026, 4, 10),
      );

      await incomeService.addIncome(uid, income);

      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('incomes')
          .get();

      expect(snapshot.docs, hasLength(1));
      final data = snapshot.docs.single.data();
      expect(data['amount'], 1250.50);
      expect(data['note'], 'Balandzio alga');
      expect(data['category'], 'salary');
      expect((data['date'] as Timestamp).toDate(), DateTime(2026, 4, 10));
      expect(data['createdAt'], isNotNull);
      expect(data['updatedAt'], isNotNull);
    });

    test('updateIncome updates existing income fields', () async {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('incomes')
          .add({
            'amount': 500.0,
            'note': 'Sena suma',
            'category': 'other',
            'date': Timestamp.fromDate(DateTime(2026, 4, 1)),
            'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
            'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
          });

      final updated = testIncome(
        id: doc.id,
        amount: 750.25,
        note: 'Atnaujinta suma',
        category: IncomeCategory.freelance,
        date: DateTime(2026, 4, 15),
      );

      await incomeService.updateIncome(uid, doc.id, updated);

      final snapshot = await doc.get();
      final data = snapshot.data()!;
      expect(data['amount'], 750.25);
      expect(data['note'], 'Atnaujinta suma');
      expect(data['category'], 'freelance');
      expect((data['date'] as Timestamp).toDate(), DateTime(2026, 4, 15));
      expect(data['updatedAt'], isNotNull);
    });

    test('deleteIncome removes income document', () async {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('incomes')
          .add({
            'amount': 300.0,
            'note': 'Vienkartines pajamos',
            'category': 'bonus',
            'date': Timestamp.fromDate(DateTime(2026, 4, 8)),
          });

      await incomeService.deleteIncome(uid, doc.id);

      final snapshot = await doc.get();
      expect(snapshot.exists, isFalse);
    });

    test('watchMonthlyIncomes returns only selected month sorted by date desc', () async {
      await seedIncome(
        firestore,
        uid,
        amount: 1000,
        note: 'Balandis 1',
        category: IncomeCategory.salary,
        date: DateTime(2026, 4, 5),
      );
      await seedIncome(
        firestore,
        uid,
        amount: 200,
        note: 'Kovas',
        category: IncomeCategory.other,
        date: DateTime(2026, 3, 31),
      );
      await seedIncome(
        firestore,
        uid,
        amount: 1500,
        note: 'Balandis 2',
        category: IncomeCategory.bonus,
        date: DateTime(2026, 4, 20),
      );

      final incomes = await incomeService
          .watchMonthlyIncomes(uid, DateTime(2026, 4))
          .first;

      expect(incomes, hasLength(2));
      expect(incomes.map((income) => income.note).toList(), [
        'Balandis 2',
        'Balandis 1',
      ]);
    });

    test('watchIncomesSince returns records from start date onward', () async {
      await seedIncome(
        firestore,
        uid,
        amount: 120,
        note: 'Per sena',
        category: IncomeCategory.other,
        date: DateTime(2026, 4, 1),
      );
      await seedIncome(
        firestore,
        uid,
        amount: 350,
        note: 'Tinkama 1',
        category: IncomeCategory.freelance,
        date: DateTime(2026, 4, 10),
      );
      await seedIncome(
        firestore,
        uid,
        amount: 900,
        note: 'Tinkama 2',
        category: IncomeCategory.salary,
        date: DateTime(2026, 4, 18),
      );

      final incomes = await incomeService
          .watchIncomesSince(uid, DateTime(2026, 4, 10))
          .first;

      expect(incomes, hasLength(2));
      expect(incomes.every((income) => !income.date.isBefore(DateTime(2026, 4, 10))), isTrue);
      expect(incomes.map((income) => income.note).toList(), [
        'Tinkama 2',
        'Tinkama 1',
      ]);
    });

    test('watchAllIncomes and getAllIncomes return all records sorted by date desc', () async {
      await seedIncome(
        firestore,
        uid,
        amount: 50,
        note: 'Sausis',
        category: IncomeCategory.gift,
        date: DateTime(2026, 1, 2),
      );
      await seedIncome(
        firestore,
        uid,
        amount: 400,
        note: 'Geguze',
        category: IncomeCategory.investment,
        date: DateTime(2026, 5, 1),
      );
      await seedIncome(
        firestore,
        uid,
        amount: 200,
        note: 'Vasaris',
        category: IncomeCategory.other,
        date: DateTime(2026, 2, 10),
      );

      final streamed = await incomeService.watchAllIncomes(uid).first;
      final fetched = await incomeService.getAllIncomes(uid);

      expect(streamed.map((income) => income.note).toList(), [
        'Geguze',
        'Vasaris',
        'Sausis',
      ]);
      expect(fetched.map((income) => income.note).toList(), [
        'Geguze',
        'Vasaris',
        'Sausis',
      ]);
    });
  });
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

Future<void> seedIncome(
  FakeFirebaseFirestore firestore,
  String uid, {
  required double amount,
  required String note,
  required IncomeCategory category,
  required DateTime date,
}) async {
  await firestore.collection('users').doc(uid).collection('incomes').add({
    'amount': amount,
    'note': note,
    'category': category.name,
    'date': Timestamp.fromDate(date),
    'createdAt': Timestamp.fromDate(date),
    'updatedAt': Timestamp.fromDate(date),
  });
}
