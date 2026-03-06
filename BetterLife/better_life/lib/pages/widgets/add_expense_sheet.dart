import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../theme/app_palette.dart';

class AddExpenseSheet extends StatefulWidget {
  final Future<void> Function(Expense expense) onSave;
  final Expense? initialExpense;

  const AddExpenseSheet({
    super.key,
    required this.onSave,
    this.initialExpense,
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late ExpenseCategory _category;
  late DateTime _date;
  bool _saving = false;

  bool get _isEditing => widget.initialExpense != null;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialExpense;
    _amountController = TextEditingController(
      text: initial != null ? initial.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(
      text: initial?.note ?? '',
    );
    _category = initial?.category ?? ExpenseCategory.food;
    _date = initial?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    if (parsed == null || parsed <= 0) return;

    setState(() => _saving = true);

    try {
      final expense = Expense(
        id: widget.initialExpense?.id ?? '',
        amount: parsed,
        note: _noteController.text.trim(),
        category: _category,
        date: _date,
        createdAt: widget.initialExpense?.createdAt,
        updatedAt: widget.initialExpense?.updatedAt,
      );

      await widget.onSave(expense);

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final surface = AppPalette.surface(context);
    final input = AppPalette.input(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isEditing ? 'Redaguoti išlaidą' : 'Pridėti išlaidą',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: text),
                decoration: InputDecoration(
                  labelText: 'Suma (€)',
                  labelStyle: TextStyle(color: subtext),
                  prefixIcon: const Icon(
                    Icons.euro_rounded,
                    color: AppPalette.accentGreen,
                  ),
                  filled: true,
                  fillColor: input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  final parsed =
                      double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Įvesk teisingą sumą';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                style: TextStyle(color: text),
                decoration: InputDecoration(
                  labelText: 'Pastaba',
                  hintText: 'Pvz. Maxima, Circle K, Bolt',
                  labelStyle: TextStyle(color: subtext),
                  hintStyle: TextStyle(color: subtext),
                  prefixIcon: const Icon(
                    Icons.notes_rounded,
                    color: AppPalette.accentPurple,
                  ),
                  filled: true,
                  fillColor: input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                value: _category,
                dropdownColor: surface,
                style: TextStyle(color: text),
                decoration: InputDecoration(
                  labelText: 'Kategorija',
                  labelStyle: TextStyle(color: subtext),
                  prefixIcon: Icon(Icons.category_rounded, color: subtext),
                  filled: true,
                  fillColor: input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.shortLabel),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: input,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppPalette.accentGreen,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                        style: TextStyle(color: text),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accentGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(_saving
                      ? 'Saugoma...'
                      : (_isEditing ? 'Atnaujinti' : 'Išsaugoti')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}