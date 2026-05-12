import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';

class GoalService {
  final _db = FirebaseFirestore.instance;

  // users/{uid}/goals/{goalId}
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('goals');

  /// Realaus laiko srautas
  Stream<List<Goal>> watchGoals(String uid) =>
      _col(uid).orderBy('createdAt', descending: true).snapshots().map(
            (snap) => snap.docs
                .map((d) => Goal.fromMap(d.id, d.data()))
                .toList(),
          );

  /// Sukurti arba atnaujinti
  Future<void> setGoal(String uid, Goal goal) =>
      _col(uid).doc(goal.id).set(goal.toMap());

  /// Ištrinti
  Future<void> deleteGoal(String uid, String goalId) =>
      _col(uid).doc(goalId).delete();

  /// Atnaujinti tik `saved` ir `lastAutoApplied` laukus (greičiau)
  Future<void> updateSaved(
    String uid,
    String goalId,
    double saved,
    DateTime? lastAutoApplied,
  ) =>
      _col(uid).doc(goalId).update({
        'saved': saved,
        if (lastAutoApplied != null)
          'lastAutoApplied': Timestamp.fromDate(lastAutoApplied),
      });
}