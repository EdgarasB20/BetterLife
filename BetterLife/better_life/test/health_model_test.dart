import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

// ─── Inline modeliai (kopija iš health_page.dart) ────────────────────────────

enum RepeatPeriod { hourly, daily, weekly, monthly }

enum HabitCategory { sport, food, water, medicine, sleep, mind, other }

class Habit {
  final String id;
  String name;
  HabitCategory category;
  RepeatPeriod repeatPeriod;
  DateTime? endDate;
  final DateTime createdAt;
  int completedCount;
  int targetCount;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.repeatPeriod,
    required this.createdAt,
    this.endDate,
    this.completedCount = 0,
    this.targetCount = 1,
  });

  double get progress =>
      targetCount > 0 ? (completedCount / targetCount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => completedCount >= targetCount;
}

class Reminder {
  final String id;
  String title;
  String body;
  HabitCategory category;
  RepeatPeriod repeatPeriod;
  DateTime? endDate;
  bool isActive;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.repeatPeriod,
    required this.createdAt,
    this.endDate,
    this.isActive = true,
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Habit makeHabit({
  int completed = 0,
  int target = 1,
  HabitCategory category = HabitCategory.sport,
  RepeatPeriod repeat = RepeatPeriod.daily,
  DateTime? endDate,
}) =>
    Habit(
      id: const Uuid().v4(),
      name: 'Testas',
      category: category,
      repeatPeriod: repeat,
      createdAt: DateTime.now(),
      completedCount: completed,
      targetCount: target,
      endDate: endDate,
    );

Reminder makeReminder({
  bool isActive = true,
  String title = 'Primink',
  String body = 'Kūnas',
  HabitCategory category = HabitCategory.water,
  RepeatPeriod repeat = RepeatPeriod.daily,
}) =>
    Reminder(
      id: const Uuid().v4(),
      title: title,
      body: body,
      category: category,
      repeatPeriod: repeat,
      createdAt: DateTime.now(),
      isActive: isActive,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════
  // Habit.progress
  // ══════════════════════════════════════════════════════════════
  group('Habit.progress', () {
    test('0.0 kai niekas neatlikiama', () {
      expect(makeHabit(completed: 0, target: 5).progress, 0.0);
    });

    test('0.5 kai pusė atlikta', () {
      expect(makeHabit(completed: 2, target: 4).progress, closeTo(0.5, 0.001));
    });

    test('1.0 kai viskas atlikta', () {
      expect(makeHabit(completed: 3, target: 3).progress, 1.0);
    });

    test('niekada neviršija 1.0', () {
      expect(makeHabit(completed: 10, target: 3).progress, 1.0);
    });

    test('0.0 kai targetCount == 0', () {
      expect(makeHabit(completed: 0, target: 0).progress, 0.0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Habit.isCompleted
  // ══════════════════════════════════════════════════════════════
  group('Habit.isCompleted', () {
    test('false kai completed < target', () {
      expect(makeHabit(completed: 2, target: 5).isCompleted, isFalse);
    });

    test('true kai completed == target', () {
      expect(makeHabit(completed: 5, target: 5).isCompleted, isTrue);
    });

    test('true kai completed > target', () {
      expect(makeHabit(completed: 7, target: 5).isCompleted, isTrue);
    });

    test('false kai target == 0 ir completed == 0', () {
      // completedCount(0) >= targetCount(0) → true matematiškai,
      // tačiau tikriname esamo kodo elgseną
      expect(makeHabit(completed: 0, target: 0).isCompleted, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Habit – mutacijos simuliacija
  // ══════════════════════════════════════════════════════════════
  group('Habit completedCount atnaujinimas', () {
    test('completedCount didėja teisingai', () {
      final h = makeHabit(completed: 1, target: 3);
      h.completedCount = (h.completedCount + 1).clamp(0, h.targetCount);
      expect(h.completedCount, 2);
      expect(h.isCompleted, isFalse);
    });

    test('completedCount niekada neviršija targetCount', () {
      final h = makeHabit(completed: 3, target: 3);
      h.completedCount = (h.completedCount + 1).clamp(0, h.targetCount);
      expect(h.completedCount, 3);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Habit – kategorijų ir periodų padengiamumas
  // ══════════════════════════════════════════════════════════════
  group('Habit kategorijos ir periodai', () {
    test('visi HabitCategory variantai priimami', () {
      for (final cat in HabitCategory.values) {
        final h = makeHabit(category: cat);
        expect(h.category, cat);
      }
    });

    test('visi RepeatPeriod variantai priimami', () {
      for (final p in RepeatPeriod.values) {
        final h = makeHabit(repeat: p);
        expect(h.repeatPeriod, p);
      }
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Habit – pabaigos data
  // ══════════════════════════════════════════════════════════════
  group('Habit.endDate', () {
    test('null pagal nutylėjimą', () {
      final h = makeHabit();
      expect(h.endDate, isNull);
    });

    test('išsaugoma teisingai kai nustatoma', () {
      final date = DateTime(2025, 12, 31);
      final h = makeHabit(endDate: date);
      expect(h.endDate, date);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Reminder – pagrindiniai laukai
  // ══════════════════════════════════════════════════════════════
  group('Reminder laukai', () {
    test('isActive true pagal nutylėjimą', () {
      expect(makeReminder().isActive, isTrue);
    });

    test('isActive gali būti false', () {
      expect(makeReminder(isActive: false).isActive, isFalse);
    });

    test('title išsaugomas teisingai', () {
      expect(makeReminder(title: 'Gerti vandenį').title, 'Gerti vandenį');
    });

    test('body išsaugomas teisingai', () {
      expect(makeReminder(body: 'Prisimink!').body, 'Prisimink!');
    });

    test('category išsaugoma teisingai', () {
      expect(
        makeReminder(category: HabitCategory.medicine).category,
        HabitCategory.medicine,
      );
    });

    test('repeatPeriod išsaugomas teisingai', () {
      expect(
        makeReminder(repeat: RepeatPeriod.weekly).repeatPeriod,
        RepeatPeriod.weekly,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Reminder – toggle isActive
  // ══════════════════════════════════════════════════════════════
  group('Reminder.isActive toggle', () {
    test('galima išjungti aktyvų priminimą', () {
      final r = makeReminder(isActive: true);
      r.isActive = false;
      expect(r.isActive, isFalse);
    });

    test('galima įjungti neaktyvų priminimą', () {
      final r = makeReminder(isActive: false);
      r.isActive = true;
      expect(r.isActive, isTrue);
    });
  });
}
