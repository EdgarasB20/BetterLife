import 'package:cloud_firestore/cloud_firestore.dart';

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

  double recommendedMonthly([DateTime? now]) {
    final current = now ?? DateTime.now();
    final months = endDate.difference(current).inDays / 30;
    if (months <= 0) return remaining;
    return remaining / months;
  }

  int pendingAutoMonths([DateTime? now]) {
    if (monthlyContribution <= 0) return 0;
    final current = now ?? DateTime.now();
    final since = lastAutoApplied ?? startDate;
    final months = current.difference(since).inDays ~/ 30;
    return months.clamp(0, 9999);
  }

  double applyAutoContributions([DateTime? now]) {
    final current = now ?? DateTime.now();
    final months = pendingAutoMonths(current);
    if (months <= 0) return 0;
    final added = (monthlyContribution * months).clamp(0, remaining).toDouble();
    saved = (saved + added).clamp(0, target);
    lastAutoApplied = current;
    return added;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'target': target,
        'initialSaved': initialSaved,
        'saved': saved,
        'monthlyContribution': monthlyContribution,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'autoContribute': autoContribute,
        'lastAutoApplied': lastAutoApplied != null
            ? Timestamp.fromDate(lastAutoApplied!)
            : null,
      };

  factory Goal.fromMap(String id, Map<String, dynamic> map) => Goal(
        id: id,
        name: map['name'] as String,
        target: (map['target'] as num).toDouble(),
        initialSaved: (map['initialSaved'] as num).toDouble(),
        saved: (map['saved'] as num).toDouble(),
        monthlyContribution: (map['monthlyContribution'] as num).toDouble(),
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        autoContribute: map['autoContribute'] as bool? ?? false,
        lastAutoApplied: map['lastAutoApplied'] != null
            ? (map['lastAutoApplied'] as Timestamp).toDate()
            : null,
      );
}