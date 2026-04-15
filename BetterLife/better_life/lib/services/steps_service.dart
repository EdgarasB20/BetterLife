import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/step_entry.dart';

class StepsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _stepsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('steps');
  }

  Stream<StepEntry?> watchDay(String uid, DateTime day) {
    final id = StepEntry.idFromDate(day);
    return _stepsRef(uid).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StepEntry.fromDoc(doc);
    });
  }

  Stream<List<StepEntry>> watchMonth(String uid, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _stepsRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs.map(StepEntry.fromDoc).toList());
  }

  Future<void> setDaySteps({
    required String uid,
    required DateTime day,
    required int steps,
    int goal = 10000,
  }) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final id = StepEntry.idFromDate(normalized);

    final entry = StepEntry(
      id: id,
      date: normalized,
      steps: steps < 0 ? 0 : steps,
      goal: goal <= 0 ? 10000 : goal,
    );

    await _stepsRef(uid).doc(id).set(entry.toMap(), SetOptions(merge: true));
  }
}