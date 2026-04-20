import 'package:better_life/models/income.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('incomeCategoryFromString', () {
    test('returns matching category for valid string values', () {
      expect(incomeCategoryFromString('salary'), IncomeCategory.salary);
      expect(incomeCategoryFromString('freelance'), IncomeCategory.freelance);
      expect(incomeCategoryFromString('investment'), IncomeCategory.investment);
      expect(incomeCategoryFromString('bonus'), IncomeCategory.bonus);
      expect(incomeCategoryFromString('gift'), IncomeCategory.gift);
      expect(incomeCategoryFromString('other'), IncomeCategory.other);
    });

    test('returns other when value is null or unknown', () {
      expect(incomeCategoryFromString(null), IncomeCategory.other);
      expect(incomeCategoryFromString('unknown'), IncomeCategory.other);
    });
  });

  group('IncomeCategoryX', () {
    test('exposes label for every category', () {
      expect(IncomeCategory.salary.label, 'Atlyginimas');
      expect(IncomeCategory.freelance.label, 'Samdomas darbas');
      expect(IncomeCategory.investment.label, 'Investicijos');
      expect(IncomeCategory.bonus.label, 'Premija');
      expect(IncomeCategory.gift.label, 'Dovana');
      expect(IncomeCategory.other.label, 'Kita');
    });

    test('shortLabel contains emoji and label', () {
      for (final category in IncomeCategory.values) {
        expect(category.shortLabel, contains(category.label));
        expect(category.shortLabel, contains(category.emoji));
      }
    });

    test('icon and color are available for all categories', () {
      for (final category in IncomeCategory.values) {
        expect(category.icon, isA<IconData>());
        expect(category.color, isA<Color>());
      }
    });
  });

  group('Income', () {
    test('constructor stores fields correctly', () {
      final income = makeIncome();

      expect(income.id, 'income-1');
      expect(income.amount, 1250.75);
      expect(income.note, 'Balandzio atlyginimas');
      expect(income.category, IncomeCategory.salary);
      expect(income.date, DateTime(2026, 4, 10));
      expect(income.createdAt, DateTime(2026, 4, 10, 8));
      expect(income.updatedAt, DateTime(2026, 4, 11, 9));
    });

    test('copyWith updates only provided fields', () {
      final income = makeIncome();

      final copied = income.copyWith(
        id: 'income-2',
        amount: 500,
        note: 'Premija',
        category: IncomeCategory.bonus,
        date: DateTime(2026, 5, 1),
      );

      expect(copied.id, 'income-2');
      expect(copied.amount, 500);
      expect(copied.note, 'Premija');
      expect(copied.category, IncomeCategory.bonus);
      expect(copied.date, DateTime(2026, 5, 1));
      expect(copied.createdAt, income.createdAt);
      expect(copied.updatedAt, income.updatedAt);
    });

    test('toMap trims note and stores Firestore compatible values', () {
      final income = makeIncome(note: '  Laisvai samdomas darbas  ');

      final map = income.toMap();

      expect(map['amount'], 1250.75);
      expect(map['note'], 'Laisvai samdomas darbas');
      expect(map['category'], 'salary');
      expect(map['date'], isA<Timestamp>());
      expect((map['date'] as Timestamp).toDate(), DateTime(2026, 4, 10));
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['updatedAt'], isA<FieldValue>());
    });

    test('toUpdateMap trims note and omits createdAt', () {
      final income = makeIncome(note: '  Atnaujinta pastaba  ');

      final map = income.toUpdateMap();

      expect(map['amount'], 1250.75);
      expect(map['note'], 'Atnaujinta pastaba');
      expect(map['category'], 'salary');
      expect(map['date'], isA<Timestamp>());
      expect(map['updatedAt'], isA<FieldValue>());
      expect(map.containsKey('createdAt'), isFalse);
    });

    test('fromDoc builds model from Firestore document', () async {
      final firestore = FakeFirebaseFirestore();
      final doc = await firestore.collection('users').doc('user-1').collection('incomes').add({
        'amount': 950.5,
        'note': 'Investicijos',
        'category': 'investment',
        'date': Timestamp.fromDate(DateTime(2026, 4, 15)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 4, 15, 8)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 16, 9)),
      });

      final snapshot = await doc.get();
      final income = Income.fromDoc(snapshot);

      expect(income.id, doc.id);
      expect(income.amount, 950.5);
      expect(income.note, 'Investicijos');
      expect(income.category, IncomeCategory.investment);
      expect(income.date, DateTime(2026, 4, 15));
      expect(income.createdAt, DateTime(2026, 4, 15, 8));
      expect(income.updatedAt, DateTime(2026, 4, 16, 9));
    });

    test('fromDoc falls back safely when fields are missing', () async {
      final firestore = FakeFirebaseFirestore();
      final before = DateTime.now();
      final doc = await firestore.collection('users').doc('user-1').collection('incomes').add({});

      final snapshot = await doc.get();
      final income = Income.fromDoc(snapshot);
      final after = DateTime.now();

      expect(income.id, doc.id);
      expect(income.amount, 0);
      expect(income.note, '');
      expect(income.category, IncomeCategory.other);
      expect(income.createdAt, isNull);
      expect(income.updatedAt, isNull);
      expect(
        income.date.isAfter(before) || income.date.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        income.date.isBefore(after) || income.date.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });
}

Income makeIncome({
  String id = 'income-1',
  double amount = 1250.75,
  String note = 'Balandzio atlyginimas',
  IncomeCategory category = IncomeCategory.salary,
  DateTime? date,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Income(
    id: id,
    amount: amount,
    note: note,
    category: category,
    date: date ?? DateTime(2026, 4, 10),
    createdAt: createdAt ?? DateTime(2026, 4, 10, 8),
    updatedAt: updatedAt ?? DateTime(2026, 4, 11, 9),
  );
}
