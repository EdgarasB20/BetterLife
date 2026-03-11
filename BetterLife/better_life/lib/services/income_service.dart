import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income.dart';

class IncomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _incomesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('incomes');
  }

  Stream<List<Income>> watchMonthlyIncomes(String uid, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _incomesRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Income.fromDoc).toList());
  }

  Stream<List<Income>> watchAllIncomes(String uid) {
    return _incomesRef(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Income.fromDoc).toList());
  }

  Future<List<Income>> getAllIncomes(String uid) async {
    final snapshot = await _incomesRef(uid)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map(Income.fromDoc).toList();
  }

  Future<void> addIncome(String uid, Income income) async {
    await _incomesRef(uid).add(income.toMap());
  }

  Future<void> updateIncome(String uid, String incomeId, Income income) async {
    await _incomesRef(uid).doc(incomeId).update(income.toUpdateMap());
  }

  Future<void> deleteIncome(String uid, String incomeId) async {
    await _incomesRef(uid).doc(incomeId).delete();
  }
}
