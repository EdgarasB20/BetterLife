import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';

import '../models/step_entry.dart';

class StepsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Health _health = Health();

  CollectionReference<Map<String, dynamic>> _stepsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('steps');
  }

  Future<bool> requestPermissions() async {
    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];
    return _health.requestAuthorization(types, permissions: permissions);
  }

  Future<int> readStepsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final steps = await _health.getTotalStepsInInterval(start, end);
    return steps ?? 0;
  }

  // ✅ Needed for month dots
  Stream<List<StepEntry>> watchMonth(String uid, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _stepsRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs.map(StepEntry.fromDoc).toList());
  }

  Stream<StepEntry?> watchGoal(String uid, DateTime day) {
    final id = StepEntry.idFromDate(day);
    return _stepsRef(uid).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StepEntry.fromDoc(doc);
    });
  }

  Future<void> setDayGoal({
    required String uid,
    required DateTime day,
    required int goal,
  }) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final id = StepEntry.idFromDate(normalized);

    final entry = StepEntry(
      id: id,
      date: normalized,
      steps: 0, // steps come from Health Connect
      goal: goal <= 0 ? 10000 : goal,
    );

    await _stepsRef(uid).doc(id).set(entry.toMap(), SetOptions(merge: true));
  }
}