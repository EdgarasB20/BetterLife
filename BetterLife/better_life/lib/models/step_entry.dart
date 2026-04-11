import 'package:cloud_firestore/cloud_firestore.dart';

class StepEntry {
  final String id; // yyyy-MM-dd
  final DateTime date;
  final int steps;
  final int goal;
  final DateTime? updatedAt;

  const StepEntry({
    required this.id,
    required this.date,
    required this.steps,
    required this.goal,
    this.updatedAt,
  });

  static String idFromDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  StepEntry copyWith({
    String? id,
    DateTime? date,
    int? steps,
    int? goal,
    DateTime? updatedAt,
  }) {
    return StepEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      goal: goal ?? this.goal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'steps': steps,
      'goal': goal,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory StepEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['date'] as Timestamp?;
    final parsedDate = ts?.toDate() ?? DateTime.now();

    return StepEntry(
      id: doc.id,
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      steps: (data['steps'] as num?)?.toInt() ?? 0,
      goal: (data['goal'] as num?)?.toInt() ?? 10000,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}