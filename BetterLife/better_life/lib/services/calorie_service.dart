import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/calorie_entry.dart';

class CalorieService {
  CalorieService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _caloriesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('calories');
  }

  Stream<List<CalorieEntry>> watchDayEntries(String uid, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return _caloriesRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CalorieEntry.fromDoc).toList());
  }

  Future<void> addEntry(String uid, CalorieEntry entry) async {
    if (entry.calories <= 0) {
      throw ArgumentError.value(entry.calories, 'calories', 'must be > 0');
    }
    for (final ingredient in entry.ingredients) {
      if (ingredient.grams <= 0) {
        throw ArgumentError.value(ingredient.grams, 'grams', 'must be > 0');
      }
    }

    await _caloriesRef(uid).add(entry.toMap());
  }
}
