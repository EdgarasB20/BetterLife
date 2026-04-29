import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_palette.dart';

class AddCalorieSheet extends StatefulWidget {
  final DateTime initialDate;
  final Future<void> Function(int calories, DateTime date, String note) onSave;

  const AddCalorieSheet({
    super.key,
    required this.initialDate,
    required this.onSave,
  });

  @override
  State<AddCalorieSheet> createState() => _AddCalorieSheetState();
}

class _AddCalorieSheetState extends State<AddCalorieSheet> {
  final _formKey = GlobalKey<FormState>();
  final _caloriesController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      now.hour,
      now.minute,
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final calories = int.parse(_caloriesController.text.trim());
    final note = _noteController.text.trim();

    setState(() => _saving = true);
    try {
      await widget.onSave(calories, _selectedDate, note);
      if (mounted) Navigator.pop(context);
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
              'Kalorijų įrašas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: text,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                labelText: 'Kalorijos',
                labelStyle: TextStyle(color: subtext),
                prefixIcon: const Icon(Icons.local_fire_department_rounded),
                filled: true,
                fillColor: input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                final parsed = int.tryParse((v ?? '').trim());
                if (parsed == null) return 'Kalorijų laukas privalomas';
                if (parsed <= 0) return 'Kalorijos turi būti > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data',
                  labelStyle: TextStyle(color: subtext),
                  prefixIcon: const Icon(Icons.calendar_today_rounded),
                  filled: true,
                  fillColor: input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                    style: TextStyle(color: text),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                labelText: 'Pastaba',
                labelStyle: TextStyle(color: subtext),
                prefixIcon: const Icon(Icons.notes_rounded),
                filled: true,
                fillColor: input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(_saving ? 'Saugoma...' : 'Pridėti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
