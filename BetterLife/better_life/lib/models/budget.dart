import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense.dart';

class Budget {
  final String id;
  final ExpenseCategory category;
  final double limit;
  final String monthKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.monthKey,
    this.createdAt,
    this.updatedAt,
  });

    static String monthKeyFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

    Budget copyWith({
    String? id,
    ExpenseCategory? category,
    double? limit,
    String? monthKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      monthKey: monthKey ?? this.monthKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

    Map<String, dynamic> toMap() {
    return {
      'category': category.name,
      'limit': limit,
      'monthKey': monthKey,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

    factory Budget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Budget(
      id: doc.id,
      category: expenseCategoryFromString(data['category'] as String?),
      limit: (data['limit'] as num?)?.toDouble() ?? 0,
      monthKey: data['monthKey'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

}