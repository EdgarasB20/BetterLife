import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _budgetsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('budgets');
  }

  Stream<List<Budget>> watchMonthlyBudgets(String uid, DateTime month) {
    final monthKey = Budget.monthKeyFromDate(month);

    return _budgetsRef(uid)
        .where('monthKey', isEqualTo: monthKey)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Budget.fromDoc).toList());
  }

  Future<void> setBudget(String uid, Budget budget) async {
    final docId =
        budget.id.isNotEmpty ? budget.id : '${budget.monthKey}_${budget.category.name}';
    final ref = _budgetsRef(uid).doc(docId);

    await ref.set(budget.toMap(), SetOptions(merge: true));
  }
}