import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/body_entry.dart';
import '../theme/app_palette.dart';
import 'widgets/profile_action_button.dart';

// ---------------------------------------------------------------------------
// Simple in-memory store – replace with your persistence layer later.
// ---------------------------------------------------------------------------
class _BodyStore {
  _BodyStore._();
  static final _BodyStore instance = _BodyStore._();

  final _data = <String, BodyEntry>{};
  final notifier = ValueNotifier<int>(0);

  void set(BodyEntry entry) {
    _data[entry.id] = entry;
    notifier.value++;
  }

  void delete(String id) {
    _data.remove(id);
    notifier.value++;
  }

  BodyEntry? get(String id) => _data[id];

  List<BodyEntry> month(int year, int month) => _data.values
      .where((e) => e.date.year == year && e.date.month == month)
      .toList();
}

// ---------------------------------------------------------------------------

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  final _store = _BodyStore.instance;

  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  void _changeMonth(int delta) {
    final newMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final maxDay = DateTime(newMonth.year, newMonth.month + 1, 0).day;
    final newDay = DateTime(
      newMonth.year,
      newMonth.month,
      _selectedDay.day.clamp(1, maxDay),
    );
    setState(() {
      _selectedMonth = newMonth;
      _selectedDay = newDay;
    });
  }

  Future<void> _openEditor({BodyEntry? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BodyEntrySheet(
        date: _selectedDay,
        existing: existing,
        onSave: (entry) {
          _store.set(entry);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kūno duomenys išsaugoti')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ištrinti įrašą?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Atšaukti'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ištrinti'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _store.delete(BodyEntry.idFromDate(_selectedDay));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Įrašas ištrintas')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = AppPalette.background(context);
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    final today = _normalize(DateTime.now());
    final selected = _normalize(_selectedDay);
    final monthDays = _daysInMonth(_selectedMonth);

    return ValueListenableBuilder<int>(
      valueListenable: _store.notifier,
      builder: (context, _, __) {
        final monthEntries =
            _store.month(_selectedMonth.year, _selectedMonth.month);
        final byId = {for (final e in monthEntries) e.id: e};
        final dayEntry = _store.get(BodyEntry.idFromDate(_selectedDay));

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            foregroundColor: text,
            elevation: 0,
            title: const Text('Kūno matmenys'),
            actions: const [ProfileActionButton()],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Įvesti duomenis'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Month navigator ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppPalette.heroGradient,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Pasirinktas mėnuo',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy MMMM').format(_selectedMonth),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Calendar grid ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(monthDays, (index) {
                    final d = DateTime(_selectedMonth.year,
                        _selectedMonth.month, index + 1);
                    final id = BodyEntry.idFromDate(d);
                    final hasData = byId.containsKey(id);
                    final isToday = _normalize(d) == today;
                    final isSelected = _normalize(d) == selected;

                    Color bg = Colors.transparent;
                    final Color fg = text;
                    BorderSide b = BorderSide(color: border);

                    if (isToday) {
                      b = const BorderSide(
                          color: AppPalette.accentPurple, width: 1.5);
                    }
                    if (isSelected) {
                      bg = AppPalette.accentGreen.withValues(alpha: 0.18);
                      b = const BorderSide(
                          color: AppPalette.accentGreen, width: 1.5);
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedDay = d),
                      child: Container(
                        width: 44,
                        height: 52,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.fromBorderSide(b),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: hasData
                                    ? AppPalette.accentGreen
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // ── Weight sparkline ─────────────────────────────────
              _WeightSparkCard(
                entries: monthEntries,
                surface: surface,
                border: border,
                text: text,
                subtext: subtext,
              ),

              // ── Selected day detail card ─────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data: ${DateFormat('yyyy-MM-dd').format(_selectedDay)}',
                      style: TextStyle(color: subtext),
                    ),
                    const SizedBox(height: 12),
                    if (dayEntry == null)
                      Text(
                        'Nėra duomenų',
                        style: TextStyle(
                          color: subtext,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else ...[
                      _MetricRow(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Svoris',
                        value: dayEntry.weightKg != null
                            ? '${dayEntry.weightKg!.toStringAsFixed(1)} kg'
                            : '—',
                        text: text,
                        subtext: subtext,
                      ),
                      const SizedBox(height: 10),
                      _MetricRow(
                        icon: Icons.height_rounded,
                        label: 'Ūgis',
                        value: dayEntry.heightCm != null
                            ? '${dayEntry.heightCm!.toStringAsFixed(0)} cm'
                            : '—',
                        text: text,
                        subtext: subtext,
                      ),
                      const SizedBox(height: 10),
                      _MetricRow(
                        icon: Icons.straighten_rounded,
                        label: 'Juosmens apimtis',
                        value: dayEntry.waistCm != null
                            ? '${dayEntry.waistCm!.toStringAsFixed(1)} cm'
                            : '—',
                        text: text,
                        subtext: subtext,
                      ),
                      const SizedBox(height: 10),
                      _MetricRow(
                        icon: Icons.radio_button_unchecked_rounded,
                        label: 'Klubų apimtis',
                        value: dayEntry.hipsCm != null
                            ? '${dayEntry.hipsCm!.toStringAsFixed(1)} cm'
                            : '—',
                        text: text,
                        subtext: subtext,
                      ),
                      const SizedBox(height: 10),
                      _MetricRow(
                        icon: Icons.fitness_center_rounded,
                        label: 'Krūtinės apimtis',
                        value: dayEntry.chestCm != null
                            ? '${dayEntry.chestCm!.toStringAsFixed(1)} cm'
                            : '—',
                        text: text,
                        subtext: subtext,
                      ),
                      if (dayEntry.weightKg != null &&
                          dayEntry.heightCm != null) ...[
                        const SizedBox(height: 14),
                        _BmiChip(
                          weightKg: dayEntry.weightKg!,
                          heightCm: dayEntry.heightCm!,
                          subtext: subtext,
                        ),
                      ],
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () => _openEditor(existing: dayEntry),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Redaguoti'),
                        ),
                        if (dayEntry != null) ...[
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: _deleteEntry,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Ištrinti'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Metric row ────────────────────────────────────────────────────────────────
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.text,
    required this.subtext,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color text;
  final Color subtext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppPalette.accentGreen),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: subtext))),
        Text(
          value,
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// ── BMI chip ──────────────────────────────────────────────────────────────────
class _BmiChip extends StatelessWidget {
  const _BmiChip({
    required this.weightKg,
    required this.heightCm,
    required this.subtext,
  });

  final double weightKg;
  final double heightCm;
  final Color subtext;

  @override
  Widget build(BuildContext context) {
    final h = heightCm / 100;
    final bmi = weightKg / (h * h);
    final String label;
    final Color color;
    if (bmi < 18.5) {
      label = 'Nepakankamai sveria';
      color = Colors.blueAccent;
    } else if (bmi < 25) {
      label = 'Normalus svoris';
      color = AppPalette.accentGreen;
    } else if (bmi < 30) {
      label = 'Antsvoris';
      color = Colors.orange;
    } else {
      label = 'Nutukimas';
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'KMI ${bmi.toStringAsFixed(1)} – $label',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Weight sparkline card ─────────────────────────────────────────────────────
class _WeightSparkCard extends StatelessWidget {
  const _WeightSparkCard({
    required this.entries,
    required this.surface,
    required this.border,
    required this.text,
    required this.subtext,
  });

  final List<BodyEntry> entries;
  final Color surface;
  final Color border;
  final Color text;
  final Color subtext;

  @override
  Widget build(BuildContext context) {
    final withWeight = entries.where((e) => e.weightKg != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (withWeight.length < 2) return const SizedBox.shrink();

    final weights = withWeight.map((e) => e.weightKg!).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final diff = weights.last - weights.first;
    final diffText = '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg';
    final diffColor = diff <= 0 ? AppPalette.accentGreen : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart_rounded,
                    size: 18, color: AppPalette.accentGreen),
                const SizedBox(width: 6),
                Text(
                  'Svorio pokytis',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    diffText,
                    style: TextStyle(
                        color: diffColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 56,
              child: CustomPaint(
                painter: _SparklinePainter(
                    values: weights, min: minW, max: maxW),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MM-dd').format(withWeight.first.date),
                  style: TextStyle(color: subtext, fontSize: 11),
                ),
                Text(
                  DateFormat('MM-dd').format(withWeight.last.date),
                  style: TextStyle(color: subtext, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.min,
    required this.max,
  });

  final List<double> values;
  final double min;
  final double max;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final range = (max - min).abs();
    final linePaint = Paint()
      ..color = AppPalette.accentGreen
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppPalette.accentGreen.withValues(alpha: 0.35),
          AppPalette.accentGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final xStep = size.width / (values.length - 1);

    Offset toOffset(int i) {
      final x = i * xStep;
      final y = range == 0
          ? size.height / 2
          : size.height - ((values[i] - min) / range) * size.height;
      return Offset(x, y);
    }

    final path = Path()..moveTo(0, toOffset(0).dy);
    for (int i = 1; i < values.length; i++) {
      final prev = toOffset(i - 1);
      final curr = toOffset(i);
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = AppPalette.accentGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(toOffset(0), 4, dotPaint);
    canvas.drawCircle(toOffset(values.length - 1), 4, dotPaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.min != min || old.max != max;
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────
class _BodyEntrySheet extends StatefulWidget {
  const _BodyEntrySheet({
    required this.date,
    required this.onSave,
    this.existing,
  });

  final DateTime date;
  final BodyEntry? existing;
  final void Function(BodyEntry) onSave;

  @override
  State<_BodyEntrySheet> createState() => _BodyEntrySheetState();
}

class _BodyEntrySheetState extends State<_BodyEntrySheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _waistCtrl;
  late final TextEditingController _hipsCtrl;
  late final TextEditingController _chestCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _weightCtrl =
        TextEditingController(text: e?.weightKg?.toStringAsFixed(1) ?? '');
    _heightCtrl =
        TextEditingController(text: e?.heightCm?.toStringAsFixed(0) ?? '');
    _waistCtrl =
        TextEditingController(text: e?.waistCm?.toStringAsFixed(1) ?? '');
    _hipsCtrl =
        TextEditingController(text: e?.hipsCm?.toStringAsFixed(1) ?? '');
    _chestCtrl =
        TextEditingController(text: e?.chestCm?.toStringAsFixed(1) ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _waistCtrl.dispose();
    _hipsCtrl.dispose();
    _chestCtrl.dispose();
    super.dispose();
  }

  double? _parse(String v) =>
      v.trim().isEmpty ? null : double.tryParse(v.trim().replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(BodyEntry(
      id: BodyEntry.idFromDate(widget.date),
      date: widget.date,
      weightKg: _parse(_weightCtrl.text),
      heightCm: _parse(_heightCtrl.text),
      waistCm: _parse(_waistCtrl.text),
      hipsCm: _parse(_hipsCtrl.text),
      chestCm: _parse(_chestCtrl.text),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final text = AppPalette.primaryText(context);
    final border = AppPalette.border(context);
    final subtext = AppPalette.secondaryText(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kūno duomenys – ${DateFormat('yyyy-MM-dd').format(widget.date)}',
                style: TextStyle(
                  color: text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _FieldRow(
                  ctrl: _weightCtrl,
                  label: 'Svoris (kg)',
                  hint: 'pvz. 75.5',
                  subtext: subtext),
              const SizedBox(height: 10),
              _FieldRow(
                  ctrl: _heightCtrl,
                  label: 'Ūgis (cm)',
                  hint: 'pvz. 178',
                  subtext: subtext),
              const SizedBox(height: 10),
              _FieldRow(
                  ctrl: _waistCtrl,
                  label: 'Juosmuo (cm)',
                  hint: 'pvz. 82.0',
                  subtext: subtext),
              const SizedBox(height: 10),
              _FieldRow(
                  ctrl: _hipsCtrl,
                  label: 'Klubai (cm)',
                  hint: 'pvz. 96.0',
                  subtext: subtext),
              const SizedBox(height: 10),
              _FieldRow(
                  ctrl: _chestCtrl,
                  label: 'Krūtinė (cm)',
                  hint: 'pvz. 100.0',
                  subtext: subtext),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Išsaugoti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.subtext,
  });

  final TextEditingController ctrl;
  final String label;
  final String hint;
  final Color subtext;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final d = double.tryParse(v.trim().replaceAll(',', '.'));
        if (d == null || d <= 0) return 'Įveskite teisingą skaičių';
        return null;
      },
    );
  }
}