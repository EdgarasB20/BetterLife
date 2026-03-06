import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  health,
  entertainment,
  other,
}

ExpenseCategory expenseCategoryFromString(String? value) {
  return ExpenseCategory.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ExpenseCategory.other,
  );
}

extension ExpenseCategoryX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Maistas';
      case ExpenseCategory.transport:
        return 'Transportas';
      case ExpenseCategory.shopping:
        return 'Pirkimai';
      case ExpenseCategory.bills:
        return 'Sąskaitos';
      case ExpenseCategory.health:
        return 'Sveikata';
      case ExpenseCategory.entertainment:
        return 'Pramogos';
      case ExpenseCategory.other:
        return 'Kita';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.food:
        return '🍔';
      case ExpenseCategory.transport:
        return '🚗';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.bills:
        return '🧾';
      case ExpenseCategory.health:
        return '💊';
      case ExpenseCategory.entertainment:
        return '🎉';
      case ExpenseCategory.other:
        return '✨';
    }
  }

  String get shortLabel => '$emoji $label';

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_filled_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.health:
        return Icons.health_and_safety_rounded;
      case ExpenseCategory.entertainment:
        return Icons.local_activity_rounded;
      case ExpenseCategory.other:
        return Icons.auto_awesome_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return Colors.green.shade400;
      case ExpenseCategory.transport:
        return Colors.blue.shade400;
      case ExpenseCategory.shopping:
        return Colors.deepPurple.shade300;
      case ExpenseCategory.bills:
        return Colors.orange.shade400;
      case ExpenseCategory.health:
        return Colors.red.shade400;
      case ExpenseCategory.entertainment:
        return Colors.pink.shade300;
      case ExpenseCategory.other:
        return Colors.teal.shade300;
    }
  }
}

class Expense {
  final String id;
  final double amount;
  final String note;
  final ExpenseCategory category;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.note,
    required this.category,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? note,
    ExpenseCategory? category,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'note': note.trim(),
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'amount': amount,
      'note': note.trim(),
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Expense(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      note: data['note'] as String? ?? '',
      category: expenseCategoryFromString(data['category'] as String?),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}