import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

// ─── Inline Goal model (kopija iš goals_page.dart) ───────────────────────────
// Testams nereikia Flutter widget'ų, todėl modelį galima išskirti atskirai.

class Goal {
  final String id;
  final String name;
  final double target;
  final double initialSaved;
  double saved;
  double monthlyContribution;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  bool autoContribute;
  DateTime? lastAutoApplied;

  Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.initialSaved,
    required this.saved,
    required this.monthlyContribution,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.autoContribute = false,
    this.lastAutoApplied,
  });

  double get progress => target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => saved >= target;
  double get remaining => (target - saved).clamp(0, double.infinity);

  double get recommendedMonthly {
    final months = endDate.difference(DateTime.now()).inDays / 30;
    if (months <= 0) return remaining;
    return remaining / months;
  }

  int pendingAutoMonths() {
    if (monthlyContribution <= 0) return 0;
    final since = lastAutoApplied ?? startDate;
    final months = DateTime.now().difference(since).inDays ~/ 30;
    return months.clamp(0, 9999);
  }

  double applyAutoContributions() {
    final months = pendingAutoMonths();
    if (months <= 0) return 0;
    final added = (monthlyContribution * months).clamp(0, remaining).toDouble();
    saved = (saved + added).clamp(0, target);
    lastAutoApplied = DateTime.now();
    return added;
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

Goal makeGoal({
  double target = 1000,
  double saved = 0,
  double monthly = 100,
  bool autoContribute = false,
  DateTime? startDate,
  DateTime? endDate,
  DateTime? lastAutoApplied,
}) =>
    Goal(
      id: const Uuid().v4(),
      name: 'Testas',
      target: target,
      initialSaved: saved,
      saved: saved,
      monthlyContribution: monthly,
      startDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      endDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
      createdAt: DateTime.now(),
      autoContribute: autoContribute,
      lastAutoApplied: lastAutoApplied,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════
  // progress
  // ══════════════════════════════════════════════════════════════
  group('Goal.progress', () {
    test('0 kai nieko nesukaupta', () {
      final g = makeGoal(target: 500, saved: 0);
      expect(g.progress, 0.0);
    });

    test('0.5 kai pusė sukaupta', () {
      final g = makeGoal(target: 500, saved: 250);
      expect(g.progress, closeTo(0.5, 0.001));
    });

    test('1.0 kai tikslas pasiektas', () {
      final g = makeGoal(target: 500, saved: 500);
      expect(g.progress, 1.0);
    });

    test('niekada neviršija 1.0 net jei saved > target', () {
      final g = makeGoal(target: 500, saved: 999);
      expect(g.progress, 1.0);
    });

    test('grąžina 0.0 kai target == 0', () {
      final g = makeGoal(target: 0, saved: 0);
      expect(g.progress, 0.0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // isCompleted
  // ══════════════════════════════════════════════════════════════
  group('Goal.isCompleted', () {
    test('false kai saved < target', () {
      expect(makeGoal(target: 100, saved: 99).isCompleted, isFalse);
    });

    test('true kai saved == target', () {
      expect(makeGoal(target: 100, saved: 100).isCompleted, isTrue);
    });

    test('true kai saved > target', () {
      expect(makeGoal(target: 100, saved: 200).isCompleted, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // remaining
  // ══════════════════════════════════════════════════════════════
  group('Goal.remaining', () {
    test('teisingai skaičiuoja likusią sumą', () {
      final g = makeGoal(target: 1000, saved: 300);
      expect(g.remaining, closeTo(700, 0.001));
    });

    test('niekada negražina neigiamos reikšmės', () {
      final g = makeGoal(target: 500, saved: 999);
      expect(g.remaining, 0.0);
    });

    test('0 kai tikslas pasiektas tiksliai', () {
      final g = makeGoal(target: 500, saved: 500);
      expect(g.remaining, 0.0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // recommendedMonthly
  // ══════════════════════════════════════════════════════════════
  group('Goal.recommendedMonthly', () {
    test('teisingai apskaičiuoja rekomenduojamą įnašą', () {
      final g = makeGoal(
        target: 1200,
        saved: 0,
        endDate: DateTime.now().add(const Duration(days: 365)),
      );
      // ~1200 / 12 mėnesių ≈ 100
      expect(g.recommendedMonthly, greaterThan(90));
      expect(g.recommendedMonthly, lessThan(110));
    });

    test('grąžina remaining kai terminas praėjęs', () {
      final g = makeGoal(
        target: 500,
        saved: 200,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(g.recommendedMonthly, closeTo(300, 0.001));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // pendingAutoMonths
  // ══════════════════════════════════════════════════════════════
  group('Goal.pendingAutoMonths', () {
    test('grąžina 0 kai monthlyContribution == 0', () {
      final g = makeGoal(monthly: 0, autoContribute: true);
      expect(g.pendingAutoMonths(), 0);
    });

    test('grąžina 0 kai lastAutoApplied buvo šiandien', () {
      final g = makeGoal(
        monthly: 100,
        lastAutoApplied: DateTime.now(),
      );
      expect(g.pendingAutoMonths(), 0);
    });

    test('grąžina 1 po ~30 dienų', () {
      final g = makeGoal(
        monthly: 100,
        lastAutoApplied: DateTime.now().subtract(const Duration(days: 35)),
      );
      expect(g.pendingAutoMonths(), 1);
    });

    test('grąžina 3 po ~90 dienų', () {
      final g = makeGoal(
        monthly: 100,
        lastAutoApplied: DateTime.now().subtract(const Duration(days: 95)),
      );
      expect(g.pendingAutoMonths(), 3);
    });

    test('naudoja startDate kai lastAutoApplied == null', () {
      final g = makeGoal(
        monthly: 100,
        startDate: DateTime.now().subtract(const Duration(days: 65)),
        lastAutoApplied: null,
      );
      // 65 dienų / 30 = 2 mėnesiai
      expect(g.pendingAutoMonths(), 2);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // applyAutoContributions
  // ══════════════════════════════════════════════════════════════
  group('Goal.applyAutoContributions', () {
    test('prideda teisingą sumą už 1 mėnesį', () {
      final g = makeGoal(
        target: 1000,
        saved: 0,
        monthly: 100,
        lastAutoApplied: DateTime.now().subtract(const Duration(days: 35)),
      );
      final added = g.applyAutoContributions();
      expect(added, closeTo(100, 0.001));
      expect(g.saved, closeTo(100, 0.001));
    });

    test('neprisideda kai nėra praleistų mėnesių', () {
      final g = makeGoal(
        target: 1000,
        saved: 100,
        monthly: 100,
        lastAutoApplied: DateTime.now(),
      );
      final added = g.applyAutoContributions();
      expect(added, 0.0);
      expect(g.saved, closeTo(100, 0.001));
    });

    test('niekada neviršija target', () {
      final g = makeGoal(
        target: 150,
        saved: 100,
        monthly: 100,
        lastAutoApplied: DateTime.now().subtract(const Duration(days: 65)),
      );
      g.applyAutoContributions();
      expect(g.saved, closeTo(150, 0.001)); // clamp prie target
    });

    test('atnaujina lastAutoApplied po taikymo', () {
      final g = makeGoal(
        target: 1000,
        saved: 0,
        monthly: 100,
        lastAutoApplied: DateTime.now().subtract(const Duration(days: 35)),
      );
      g.applyAutoContributions();
      expect(g.lastAutoApplied, isNotNull);
      // lastAutoApplied turi būti artimas dabarties laikui
      final diff = DateTime.now().difference(g.lastAutoApplied!).inSeconds;
      expect(diff, lessThan(5));
    });

    test('grąžina 0 kai monthlyContribution == 0', () {
      final g = makeGoal(
        monthly: 0,
        lastAutoApplied: DateTime.now().subtract(const Duration(days: 60)),
      );
      expect(g.applyAutoContributions(), 0.0);
    });
  });
}
