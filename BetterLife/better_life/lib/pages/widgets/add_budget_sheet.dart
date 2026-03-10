import 'package:flutter/material.dart';
import '../../models/budget.dart';
import '../../models/expense.dart';
import '../../theme/app_palette.dart';

class AddBudgetSheet extends StatefulWidget {
  final ExpenseCategory category;
  final DateTime month;
  final Budget? initialBudget;
  final Future<void> Function(Budget budget) onSave;

  const AddBudgetSheet({
    super.key,
    required this.category,
    required this.month,
    required this.onSave,
    this.initialBudget,
  });

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  bool _saving = false;

  bool get _isEditing => widget.initialBudget != null;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.initialBudget != null
          ? widget.initialBudget!.limit.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = double.tryParse(
      _limitController.text.trim().replaceAll(',', '.'),
    );

    if (parsed == null || parsed <= 0) return;

    setState(() => _saving = true);

    try {
      final budget = Budget(
        id: widget.initialBudget?.id ?? '',
        category: widget.category,
        limit: parsed,
        monthKey: Budget.monthKeyFromDate(widget.month),
        createdAt: widget.initialBudget?.createdAt,
        updatedAt: widget.initialBudget?.updatedAt,
      );

      await widget.onSave(budget);

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
              _isEditing
                  ? 'Redaguoti biudžetą'
                  : 'Nustatyti biudžetą',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.category.shortLabel,
              style: TextStyle(color: subtext),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: text),
              decoration: InputDecoration(
                labelText: 'Limitas (€)',
                labelStyle: TextStyle(color: subtext),
                prefixIcon: const Icon(
                  Icons.account_balance_wallet_rounded,
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
                  return 'Įvesk teisingą limitą';
                }
                return null;
              },
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
                    : Icon(_isEditing ? Icons.save_rounded : Icons.check_rounded),
                label: Text(_saving ? 'Saugoma...' : 'Išsaugoti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}