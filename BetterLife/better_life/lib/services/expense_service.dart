import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _expensesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('expenses');
  }

  Stream<List<Expense>> watchMonthlyExpenses(String uid, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _expensesRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Expense.fromDoc).toList());
  }

  Future<void> addExpense(String uid, Expense expense) async {
    await _expensesRef(uid).add(expense.toMap());
  }

  Future<void> updateExpense(String uid, String expenseId, Expense expense) async {
    await _expensesRef(uid).doc(expenseId).update(expense.toUpdateMap());
  }

  Future<void> deleteExpense(String uid, String expenseId) async {
    await _expensesRef(uid).doc(expenseId).delete();
  }
}