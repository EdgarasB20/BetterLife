import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/body_entry.dart';

class BodyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _collectionPath(String uid) => 'users/$uid/body_entries';

  /// Streams body entries for a given month
  Stream<List<BodyEntry>> watchMonth(String uid, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    return _db
        .collection(_collectionPath(uid))
        .where('date',
            isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThan: endOfMonth.toIso8601String())
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BodyEntry.fromMap(doc.data()))
          .toList();
    });
  }

  /// Streams body entry for a specific day
  Stream<BodyEntry?> watchDay(String uid, DateTime day) {
    final id = BodyEntry.idFromDate(day);
    return _db
        .collection(_collectionPath(uid))
        .doc(id)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return BodyEntry.fromMap(snapshot.data() ?? {});
    });
  }

  /// Saves a body entry for a specific day
  Future<void> setDayEntry({required String uid, required BodyEntry entry}) async {
    await _db
        .collection(_collectionPath(uid))
        .doc(entry.id)
        .set(entry.toMap());
  }

  /// Deletes a body entry for a specific day
  Future<void> deleteEntry({required String uid, required DateTime day}) async {
    final id = BodyEntry.idFromDate(day);
    await _db.collection(_collectionPath(uid)).doc(id).delete();
  }
}
