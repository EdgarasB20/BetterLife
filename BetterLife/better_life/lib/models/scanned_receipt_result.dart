import 'expense.dart';

class ScannedReceiptResult {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? date;
  final String rawText;
  final String? imagePath;

  const ScannedReceiptResult({
    this.merchantName,
    this.totalAmount,
    this.date,
    required this.rawText,
    this.imagePath,
  });

  bool get hasRecognizedExpenseData => totalAmount != null;

  Expense toExpenseDraft({DateTime? fallbackDate}) {
    return Expense(
      id: '',
      amount: totalAmount ?? 0,
      note: merchantName?.trim().isNotEmpty == true
          ? merchantName!.trim()
          : 'Nuskenuotas čekis',
      category: ExpenseCategory.shopping,
      date: date ?? fallbackDate ?? DateTime.now(),
    );
  }
}
