import 'package:cloud_firestore/cloud_firestore.dart';

class CalorieEntry {
  final String id;
  final int calories;
  final DateTime date;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CalorieEntry({
    required this.id,
    required this.calories,
    required this.date,
    required this.note,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'date': Timestamp.fromDate(date),
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CalorieEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return CalorieEntry(
      id: doc.id,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
