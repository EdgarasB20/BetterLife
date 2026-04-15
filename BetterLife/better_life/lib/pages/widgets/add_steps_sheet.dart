import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';

class AddStepsSheet extends StatefulWidget {
  final DateTime date;
  final int initialSteps;
  final int initialGoal;
  final Future<void> Function(int steps, int goal) onSave;

  const AddStepsSheet({
    super.key,
    required this.date,
    required this.initialSteps,
    required this.initialGoal,
    required this.onSave,
  });

  @override
  State<AddStepsSheet> createState() => _AddStepsSheetState();
}

class _AddStepsSheetState extends State<AddStepsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stepsController;
  late final TextEditingController _goalController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController(
      text: widget.initialSteps > 0 ? widget.initialSteps.toString() : '',
    );
    _goalController = TextEditingController(
      text: widget.initialGoal.toString(),
    );
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final steps = int.tryParse(_stepsController.text.trim()) ?? 0;
    final goal = int.tryParse(_goalController.text.trim()) ?? 10000;

    setState(() => _saving = true);
    try {
      await widget.onSave(steps, goal);
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
              'Žingsniai',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}',
              style: TextStyle(color: subtext),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                labelText: 'Žingsnių skaičius',
                labelStyle: TextStyle(color: subtext),
                prefixIcon: const Icon(Icons.directions_walk_rounded),
                filled: true,
                fillColor: input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                final parsed = int.tryParse((v ?? '').trim());
                if (parsed == null || parsed < 0) return 'Įvesk teisingą skaičių';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                labelText: 'Dienos tikslas',
                labelStyle: TextStyle(color: subtext),
                prefixIcon: const Icon(Icons.flag_rounded),
                filled: true,
                fillColor: input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                final parsed = int.tryParse((v ?? '').trim());
                if (parsed == null || parsed <= 0) return 'Tikslas turi būti > 0';
                return null;
              },
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
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saugoma...' : 'Išsaugoti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}