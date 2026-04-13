import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_palette.dart';
import 'widgets/profile_action_button.dart';

// ─── Enums & extensions ───────────────────────────────────────────────────────

enum RepeatPeriod { hourly, daily, weekly, monthly }

extension RepeatPeriodLabel on RepeatPeriod {
  String get label => switch (this) {
        RepeatPeriod.hourly  => 'Kas valandą',
        RepeatPeriod.daily   => 'Kasdien',
        RepeatPeriod.weekly  => 'Kas savaitę',
        RepeatPeriod.monthly => 'Kas mėnesį',
      };

  IconData get icon => switch (this) {
        RepeatPeriod.hourly  => Icons.timer_rounded,
        RepeatPeriod.daily   => Icons.today_rounded,
        RepeatPeriod.weekly  => Icons.date_range_rounded,
        RepeatPeriod.monthly => Icons.calendar_month_rounded,
      };
}

enum HabitCategory { sport, food, water, medicine, sleep, mind, other }

extension HabitCategoryExt on HabitCategory {
  String get label => switch (this) {
        HabitCategory.sport    => 'Sportas',
        HabitCategory.food     => 'Maistas',
        HabitCategory.water    => 'Vanduo',
        HabitCategory.medicine => 'Medicina',
        HabitCategory.sleep    => 'Miegas',
        HabitCategory.mind     => 'Psichika',
        HabitCategory.other    => 'Kita',
      };

  String get emoji => switch (this) {
        HabitCategory.sport    => '🏋️',
        HabitCategory.food     => '🥗',
        HabitCategory.water    => '💧',
        HabitCategory.medicine => '💊',
        HabitCategory.sleep    => '😴',
        HabitCategory.mind     => '🧘',
        HabitCategory.other    => '⭐',
      };

  Color get color => switch (this) {
        HabitCategory.sport    => const Color(0xFF00BFA5),
        HabitCategory.food     => const Color(0xFF66BB6A),
        HabitCategory.water    => const Color(0xFF29B6F6),
        HabitCategory.medicine => const Color(0xFFEF5350),
        HabitCategory.sleep    => const Color(0xFF7C4DFF),
        HabitCategory.mind     => const Color(0xFFFFA726),
        HabitCategory.other    => const Color(0xFF78909C),
      };
}

// ─── Models ───────────────────────────────────────────────────────────────────

class Habit {
  final String id;
  String name;
  HabitCategory category;
  RepeatPeriod repeatPeriod;
  DateTime? endDate;
  final DateTime createdAt;
  int completedCount;
  int targetCount;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.repeatPeriod,
    required this.createdAt,
    this.endDate,
    this.completedCount = 0,
    this.targetCount = 1,
  });

  double get progress =>
      targetCount > 0 ? (completedCount / targetCount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => completedCount >= targetCount;
}

class Reminder {
  final String id;
  String title;
  String body;
  HabitCategory category;
  RepeatPeriod repeatPeriod;
  TimeOfDay? notificationTime;
  DateTime? endDate;
  bool isActive;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.repeatPeriod,
    required this.createdAt,
    this.notificationTime,
    this.endDate,
    this.isActive = true,
  });
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) => const _HealthView();
}

class _HealthView extends StatefulWidget {
  const _HealthView();

  @override
  State<_HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<_HealthView> {
  final List<Habit>    _habits    = [];
  final List<Reminder> _reminders = [];

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void _saveHabit(Habit h) => setState(() {
        final idx = _habits.indexWhere((x) => x.id == h.id);
        idx >= 0 ? _habits[idx] = h : _habits.add(h);
      });

  void _deleteHabit(String id) =>
      setState(() => _habits.removeWhere((h) => h.id == id));

  void _saveReminder(Reminder r) => setState(() {
        final idx = _reminders.indexWhere((x) => x.id == r.id);
        idx >= 0 ? _reminders[idx] = r : _reminders.add(r);
      });

  void _deleteReminder(String id) =>
      setState(() => _reminders.removeWhere((r) => r.id == id));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg   = AppPalette.background(context);
    final text = AppPalette.primaryText(context);

    final habitsTotal     = _habits.length;
    final habitsCompleted = _habits.where((h) => h.isCompleted).length;
    final habitsProgress  =
        habitsTotal > 0 ? habitsCompleted / habitsTotal : 0.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Sveikata',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: const [ProfileActionButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── Hero summary card ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppPalette.heroGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Šiandienos progresas',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('$habitsCompleted / $habitsTotal',
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const Text('įpročių įvykdyta',
                    style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: habitsProgress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(habitsProgress * 100).toStringAsFixed(0)}% bendras progresas',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${_reminders.where((r) => r.isActive).length} aktyvių priminimų',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ══════════════════════════════════════════════════════════
          //  ĮPROČIAI
          // ══════════════════════════════════════════════════════════
          _SectionHeader(
            icon: Icons.track_changes_rounded,
            title: 'Įpročiai',
            onAdd: () => _showHabitSheet(context, null),
          ),
          const SizedBox(height: 10),

          if (_habits.isEmpty)
            _EmptyCard(
              icon: Icons.track_changes_rounded,
              message: 'Įpročių nėra.\nSpausk + norėdamas pridėti.',
            )
          else
            ..._habits.map((h) => _HabitCard(
                  habit: h,
                  onEdit: () => _showHabitSheet(context, h),
                  onDelete: () => _deleteHabit(h.id),
                  onTap: () {
                    if (!h.isCompleted) {
                      h.completedCount =
                          (h.completedCount + 1).clamp(0, h.targetCount);
                      _saveHabit(h);
                    }
                  },
                )),

          const SizedBox(height: 28),

          // ══════════════════════════════════════════════════════════
          //  PRIMINIMAI
          // ══════════════════════════════════════════════════════════
          _SectionHeader(
            icon: Icons.notifications_rounded,
            title: 'Priminimai',
            onAdd: () => _showReminderSheet(context, null),
          ),
          const SizedBox(height: 10),

          if (_reminders.isEmpty)
            _EmptyCard(
              icon: Icons.notifications_off_outlined,
              message:
                  'Nėra egzistuojančių priminimų.\nSpausk + norėdamas pridėti.',
            )
          else
            ..._reminders.map((r) => _ReminderCard(
                  reminder: r,
                  onEdit: () => _showReminderSheet(context, r),
                  onDelete: () => _deleteReminder(r.id),
                  onToggle: (v) {
                    r.isActive = v;
                    _saveReminder(r);
                  },
                )),
        ],
      ),
    );
  }

  // ─── Habit sheet ──────────────────────────────────────────────────────────

  void _showHabitSheet(BuildContext context, Habit? existing) {
    final nameCtrl   = TextEditingController(text: existing?.name ?? '');
    final targetCtrl = TextEditingController(
        text: existing?.targetCount.toString() ?? '1');
    var category  = existing?.category ?? HabitCategory.sport;
    var repeat    = existing?.repeatPeriod ?? RepeatPeriod.daily;
    DateTime? endDate = existing?.endDate;
    final isEdit  = existing != null;

    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final text    = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: border),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DragHandle(border: border),
                  Text(isEdit ? 'Redaguoti įprotį' : 'Naujas įprotis',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: text)),
                  const SizedBox(height: 14),

                  Text('Kategorija',
                      style: TextStyle(fontSize: 12, color: subtext)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: HabitCategory.values.map((c) {
                      return _CategoryChip(
                        emoji: c.emoji,
                        label: c.label,
                        color: c.color,
                        active: category == c,
                        onTap: () => setS(() => category = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  _OutlinedField(ctrl: nameCtrl, label: 'Pavadinimas'),
                  const SizedBox(height: 12),
                  _OutlinedField(
                    ctrl: targetCtrl,
                    label: 'Kartų per periodą',
                    type: const TextInputType.numberWithOptions(),
                  ),
                  const SizedBox(height: 12),

                  Text('Pasikartojimas',
                      style: TextStyle(fontSize: 12, color: subtext)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: RepeatPeriod.values.map((p) {
                      return _PeriodChip(
                        period: p,
                        active: repeat == p,
                        onTap: () => setS(() => repeat = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  _DatePickerRow(
                    label: 'Pabaigos data (nebūtina)',
                    date: endDate,
                    onPick: (d) => setS(() => endDate = d),
                    onClear: () => setS(() => endDate = null),
                  ),
                  const SizedBox(height: 20),

                  _SubmitButton(
                    label: isEdit ? 'Išsaugoti' : 'Sukurti',
                    onPressed: () {
                      final name   = nameCtrl.text.trim();
                      final target = int.tryParse(targetCtrl.text) ?? 0;
                      if (name.isEmpty || target <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content:
                              Text('Klaida. Netinkamai suvesti duomenys!'),
                          backgroundColor: Colors.redAccent,
                        ));
                        return;
                      }
                      final habit = Habit(
                        id: existing?.id ?? const Uuid().v4(),
                        name: name,
                        category: category,
                        repeatPeriod: repeat,
                        endDate: endDate,
                        createdAt: existing?.createdAt ?? DateTime.now(),
                        completedCount: existing?.completedCount ?? 0,
                        targetCount: target,
                      );
                      Navigator.pop(ctx);
                      _saveHabit(habit);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Reminder sheet ───────────────────────────────────────────────────────

  void _showReminderSheet(BuildContext context, Reminder? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl  = TextEditingController(text: existing?.body ?? '');
    var category  = existing?.category ?? HabitCategory.water;
    var repeat    = existing?.repeatPeriod ?? RepeatPeriod.daily;
    TimeOfDay notifTime =
        existing?.notificationTime ?? const TimeOfDay(hour: 9, minute: 0);
    DateTime? endDate = existing?.endDate;
    bool isActive = existing?.isActive ?? true;
    final isEdit  = existing != null;

    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final text    = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: border),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DragHandle(border: border),
                  Text(
                      isEdit
                          ? 'Redaguoti priminimą'
                          : 'Naujas priminimas',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: text)),
                  const SizedBox(height: 14),

                  Text('Kategorija',
                      style: TextStyle(fontSize: 12, color: subtext)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: HabitCategory.values.map((c) {
                      return _CategoryChip(
                        emoji: c.emoji,
                        label: c.label,
                        color: c.color,
                        active: category == c,
                        onTap: () => setS(() => category = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  _OutlinedField(ctrl: titleCtrl, label: 'Pavadinimas'),
                  const SizedBox(height: 12),
                  _OutlinedField(
                      ctrl: bodyCtrl,
                      label: 'Priminimo tekstas',
                      maxLines: 2),
                  const SizedBox(height: 12),

                  Text('Pasikartojimas',
                      style: TextStyle(fontSize: 12, color: subtext)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: RepeatPeriod.values.map((p) {
                      return _PeriodChip(
                        period: p,
                        active: repeat == p,
                        onTap: () => setS(() => repeat = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Time picker (daily / weekly only)
                  if (repeat == RepeatPeriod.daily ||
                      repeat == RepeatPeriod.weekly) ...[
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: notifTime,
                        );
                        if (picked != null) setS(() => notifTime = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 16, color: subtext),
                            const SizedBox(width: 8),
                            Text('Laikas: ${notifTime.format(ctx)}',
                                style: TextStyle(
                                    fontSize: 14, color: text)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _DatePickerRow(
                    label: 'Siųsti iki (nebūtina)',
                    date: endDate,
                    onPick: (d) => setS(() => endDate = d),
                    onClear: () => setS(() => endDate = null),
                  ),
                  const SizedBox(height: 12),

                  // Active toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppPalette.accentTeal.withOpacity(.08)
                          : surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? AppPalette.accentTeal.withOpacity(.4)
                            : border,
                        width: isActive ? 1.5 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_rounded,
                            size: 18,
                            color: isActive
                                ? AppPalette.accentTeal
                                : subtext),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aktyvus priminimas',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? AppPalette.accentTeal
                                          : text)),
                              Text(
                                  'Išjungus – priminimai nesiunčiami',
                                  style: TextStyle(
                                      fontSize: 11, color: subtext)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isActive,
                          activeColor: AppPalette.accentTeal,
                          onChanged: (v) => setS(() => isActive = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SubmitButton(
                    label: isEdit ? 'Išsaugoti' : 'Sukurti',
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content:
                              Text('Klaida. Netinkamai suvesti duomenys!'),
                          backgroundColor: Colors.redAccent,
                        ));
                        return;
                      }
                      final reminder = Reminder(
                        id: existing?.id ?? const Uuid().v4(),
                        title: title,
                        body: bodyCtrl.text.trim().isEmpty
                            ? title
                            : bodyCtrl.text.trim(),
                        category: category,
                        repeatPeriod: repeat,
                        notificationTime: notifTime,
                        endDate: endDate,
                        isActive: isActive,
                        createdAt: existing?.createdAt ?? DateTime.now(),
                      );
                      Navigator.pop(ctx);
                      _saveReminder(reminder);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final text = AppPalette.primaryText(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: AppPalette.accentTeal),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: text)),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppPalette.accentTeal.withOpacity(.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: AppPalette.accentTeal.withOpacity(.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded,
                    size: 14, color: AppPalette.accentTeal),
                const SizedBox(width: 4),
                Text('Pridėti',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.accentTeal,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty card ───────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final subtext = AppPalette.secondaryText(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: subtext),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtext, height: 1.5)),
        ],
      ),
    );
  }
}

// ─── Habit card ───────────────────────────────────────────────────────────────

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _HabitCard({
    required this.habit,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final text    = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);
    final color   = habit.category.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: habit.isCompleted
                ? AppPalette.accentGreen.withOpacity(.5)
                : border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(.15),
                  child: Text(habit.category.emoji,
                      style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: text)),
                      Text(
                        '${habit.category.label}  ·  ${habit.repeatPeriod.label}',
                        style: TextStyle(fontSize: 12, color: subtext),
                      ),
                    ],
                  ),
                ),
                if (habit.isCompleted)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle_rounded,
                        color: AppPalette.accentGreen, size: 20),
                  ),
                _ActionBtn(
                    label: 'Edit',
                    color: AppPalette.accentTeal,
                    onTap: onEdit),
                const SizedBox(width: 6),
                _ActionBtn(
                    label: 'Delete',
                    color: Colors.redAccent,
                    onTap: onDelete),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${habit.completedCount} / ${habit.targetCount} kartų',
                    style: TextStyle(fontSize: 12, color: subtext)),
                if (habit.endDate != null)
                  Text('iki ${_fmt(habit.endDate!)}',
                      style: TextStyle(fontSize: 12, color: subtext)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: habit.progress,
                backgroundColor: color.withOpacity(.15),
                color: habit.isCompleted
                    ? AppPalette.accentGreen
                    : color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
                '${(habit.progress * 100).toStringAsFixed(0)}% įvykdyta',
                style: TextStyle(fontSize: 12, color: subtext)),
          ],
        ),
      ),
    );
  }
}

// ─── Reminder card ────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final text    = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);
    final color   = reminder.category.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: reminder.isActive ? color.withOpacity(.35) : border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(.15),
                child: Text(reminder.category.emoji,
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: text)),
                    Text(
                      '${reminder.category.label}  ·  ${reminder.repeatPeriod.label}',
                      style: TextStyle(fontSize: 12, color: subtext),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.isActive,
                activeColor: AppPalette.accentTeal,
                onChanged: onToggle,
              ),
            ],
          ),

          if (reminder.body.isNotEmpty &&
              reminder.body != reminder.title) ...[
            const SizedBox(height: 6),
            Text(reminder.body,
                style: TextStyle(fontSize: 13, color: subtext)),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Icon(reminder.repeatPeriod.icon,
                  size: 13, color: subtext),
              const SizedBox(width: 4),
              Text(reminder.repeatPeriod.label,
                  style: TextStyle(fontSize: 12, color: subtext)),
              if (reminder.notificationTime != null)
                Text(
                    '  ·  ${reminder.notificationTime!.format(context)}',
                    style: TextStyle(fontSize: 12, color: subtext)),
              const Spacer(),
              _ActionBtn(
                  label: 'Edit',
                  color: AppPalette.accentTeal,
                  onTap: onEdit),
              const SizedBox(width: 6),
              _ActionBtn(
                  label: 'Delete',
                  color: Colors.redAccent,
                  onTap: onDelete),
            ],
          ),

          if (reminder.endDate != null) ...[
            const SizedBox(height: 4),
            Text('Siųsti iki: ${_fmt(reminder.endDate!)}',
                style: TextStyle(fontSize: 11, color: subtext)),
          ],
        ],
      ),
    );
  }
}

// ─── Action button (Edit / Delete) ───────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(.4)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  final Color border;
  const _DragHandle({required this.border});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: border,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
}

class _OutlinedField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;
  final int maxLines;

  const _OutlinedField({
    required this.ctrl,
    required this.label,
    this.type = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border  = AppPalette.border(context);
    final surface = AppPalette.surface(context);
    final subtext = AppPalette.secondaryText(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(.12) : surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color.withOpacity(.5) : border,
            width: active ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? color : subtext,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final RepeatPeriod period;
  final bool active;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.period,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border  = AppPalette.border(context);
    final surface = AppPalette.surface(context);
    final subtext = AppPalette.secondaryText(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppPalette.accentTeal.withOpacity(.12)
              : surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? AppPalette.accentTeal.withOpacity(.5)
                : border,
            width: active ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(period.icon,
                size: 13,
                color: active ? AppPalette.accentTeal : subtext),
            const SizedBox(width: 5),
            Text(period.label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? AppPalette.accentTeal : subtext,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final border  = AppPalette.border(context);
    final subtext = AppPalette.secondaryText(context);
    final text    = AppPalette.primaryText(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) onPick(picked);
            },
            icon: const Icon(Icons.calendar_today, size: 14),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
                Text(
                  date != null ? _fmt(date!) : 'Nepasirinkta',
                  style: TextStyle(fontSize: 13, color: text),
                ),
              ],
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        if (date != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClear,
            icon: Icon(Icons.close_rounded, size: 18, color: subtext),
            tooltip: 'Išvalyti',
          ),
        ],
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SubmitButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.accentTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onPressed,
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
}