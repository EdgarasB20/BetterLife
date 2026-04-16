import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum IncomeCategory {
  salary,
  freelance,
  investment,
  bonus,
  gift,
  other,
}

IncomeCategory incomeCategoryFromString(String? value) {
  return IncomeCategory.values.firstWhere(
    (e) => e.name == value,
    orElse: () => IncomeCategory.other,
  );
}

extension IncomeCategoryX on IncomeCategory {
  String get label {
    switch (this) {
      case IncomeCategory.salary:
        return 'Atlyginimas';
      case IncomeCategory.freelance:
        return 'Samdomas darbas';
      case IncomeCategory.investment:
        return 'Investicijos';
      case IncomeCategory.bonus:
        return 'Premija';
      case IncomeCategory.gift:
        return 'Dovana';
      case IncomeCategory.other:
        return 'Kita';
    }
  }

  String get emoji {
    switch (this) {
      case IncomeCategory.salary:
        return '💼';
      case IncomeCategory.freelance:
        return '💻';
      case IncomeCategory.investment:
        return '📈';
      case IncomeCategory.bonus:
        return '🎁';
      case IncomeCategory.gift:
        return '🎀';
      case IncomeCategory.other:
        return '⭐';
    }
  }

  String get shortLabel => '$emoji $label';

  IconData get icon {
    switch (this) {
      case IncomeCategory.salary:
        return Icons.business_center_rounded;
      case IncomeCategory.freelance:
        return Icons.computer_rounded;
      case IncomeCategory.investment:
        return Icons.trending_up_rounded;
      case IncomeCategory.bonus:
        return Icons.card_giftcard_rounded;
      case IncomeCategory.gift:
        return Icons.favorite_rounded;
      case IncomeCategory.other:
        return Icons.auto_awesome_rounded;
    }
  }

  Color get color {
    switch (this) {
      case IncomeCategory.salary:
        return Colors.blue.shade400;
      case IncomeCategory.freelance:
        return Colors.green.shade400;
      case IncomeCategory.investment:
        return Colors.amber.shade400;
      case IncomeCategory.bonus:
        return Colors.pink.shade400;
      case IncomeCategory.gift:
        return Colors.red.shade400;
      case IncomeCategory.other:
        return Colors.teal.shade400;
    }
  }
}

class Income {
  final String id;
  final double amount;
  final String note;
  final IncomeCategory category;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Income({
    required this.id,
    required this.amount,
    required this.note,
    required this.category,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  Income copyWith({
    String? id,
    double? amount,
    String? note,
    IncomeCategory? category,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
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

  factory Income.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Income(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      note: data['note'] as String? ?? '',
      category: incomeCategoryFromString(data['category'] as String?),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}