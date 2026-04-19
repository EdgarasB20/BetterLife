import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_palette.dart';
import 'widgets/profile_action_button.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class Goal {
  final String id;
  final String name;
  final double target;
  final double initialSaved;
  double saved;
  double monthlyContribution;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  /// Auto-contribution mode: if true, monthly contribution is applied
  /// automatically based on elapsed months since [lastAutoApplied].
  bool autoContribute;
  DateTime? lastAutoApplied;

  Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.initialSaved,
    required this.saved,
    required this.monthlyContribution,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.autoContribute = false,
    this.lastAutoApplied,
  });

  double get progress => target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => saved >= target;
  double get remaining => (target - saved).clamp(0, double.infinity);

  double recommendedMonthly([DateTime? now]) {
    final current = now ?? DateTime.now();
    final months = endDate.difference(current).inDays / 30;
    if (months <= 0) return remaining;
    return remaining / months;
  }

  /// Returns how many whole months have elapsed since [lastAutoApplied]
  /// (or [startDate] if never applied) up to now.
  int pendingAutoMonths([DateTime? now]) {
    if (monthlyContribution <= 0) return 0;
    final current = now ?? DateTime.now();
    final since = lastAutoApplied ?? startDate;
    final months = current.difference(since).inDays ~/ 30;
    return months.clamp(0, 9999);
  }

  /// Applies all pending auto months and updates [lastAutoApplied].
  /// Returns the amount that was added.
  double applyAutoContributions([DateTime? now]) {
    final current = now ?? DateTime.now();
    final months = pendingAutoMonths(current);
    if (months <= 0) return 0;
    final added = (monthlyContribution * months)
        .clamp(0, remaining)
        .toDouble();
    saved = (saved + added).clamp(0, target);
    lastAutoApplied = current;
    return added;
  }
}

// ─── Sort options ─────────────────────────────────────────────────────────────

enum SortField { createdAt, startDate, endDate, target, progress }

enum SortOrder { asc, desc }

extension SortFieldLabel on SortField {
  String get label => switch (this) {
        SortField.createdAt => 'Sukūrimo data',
        SortField.startDate => 'Pradžios data',
        SortField.endDate   => 'Pabaigos data',
        SortField.target    => 'Suma',
        SortField.progress  => 'Progresas',
      };

  IconData get icon => switch (this) {
        SortField.createdAt => Icons.calendar_today_rounded,
        SortField.startDate => Icons.play_arrow_rounded,
        SortField.endDate   => Icons.flag_rounded,
        SortField.target    => Icons.euro_rounded,
        SortField.progress  => Icons.show_chart_rounded,
      };
}

// ─── Goal templates ───────────────────────────────────────────────────────────

class _GoalTemplate {
  final String icon;
  final String name;
  final String category;
  const _GoalTemplate(this.icon, this.name, this.category);
}

const _kTemplates = [
  _GoalTemplate('🏠', 'Nekilnojamasis turtas', 'NT'),
  _GoalTemplate('🚗', 'Automobilis', 'NT'),
  _GoalTemplate('🏖️', 'Kelionė', 'Pramogos'),
  _GoalTemplate('🎮', 'Elektronika', 'Pramogos'),
  _GoalTemplate('🎓', 'Studijos', 'Augimas'),
  _GoalTemplate('📚', 'Kursai', 'Augimas'),
  _GoalTemplate('💍', 'Vestuvės', 'Šeima'),
  _GoalTemplate('👶', 'Vaikas', 'Šeima'),
  _GoalTemplate('🏋️', 'Sportas', 'Sveikata'),
  _GoalTemplate('💊', 'Medicina', 'Sveikata'),
  _GoalTemplate('🛋️', 'Baldai', 'Buitis'),
  _GoalTemplate('🔧', 'Remontas', 'Buitis'),
  _GoalTemplate('💰', 'Santaupos', 'Finansai'),
  _GoalTemplate('📈', 'Investicijos', 'Finansai'),
  _GoalTemplate('🎸', 'Hobis', 'Pramogos'),
  _GoalTemplate('✈️', 'Emigracija', 'NT'),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) => const _GoalsView();
}

class _GoalsView extends StatefulWidget {
  const _GoalsView();

  @override
  State<_GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<_GoalsView> {
  final List<Goal> _goals = [];

  SortField _sortField = SortField.createdAt;
  SortOrder _sortOrder = SortOrder.desc;

  // ── On init: apply pending auto-contributions ────────────────────────────

  @override
  void initState() {
    super.initState();
    _applyAllAutoContributions();
  }

  void _applyAllAutoContributions() {
    bool anyChanged = false;
    for (final g in _goals) {
      if (g.autoContribute && !g.isCompleted) {
        final added = g.applyAutoContributions();
        if (added > 0) anyChanged = true;
      }
    }
    if (anyChanged && mounted) setState(() {});
  }

  // ── CRUD helpers ─────────────────────────────────────────────────────────

  void _persistGoal(Goal goal) {
    setState(() {
      final idx = _goals.indexWhere((g) => g.id == goal.id);
      if (idx >= 0) {
        _goals[idx] = goal;
      } else {
        _goals.add(goal);
      }
    });
  }

  void _deleteGoal(String id) =>
      setState(() => _goals.removeWhere((g) => g.id == id));

  // ── Manual deposit ───────────────────────────────────────────────────────

  void _showDepositSheet(BuildContext context, Goal goal) {
    final amountCtrl = TextEditingController();
    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final text    = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
          child: StatefulBuilder(
            builder: (ctx, setS) {
              final parsed = double.tryParse(amountCtrl.text) ?? 0.0;
              final afterDeposit =
                  (goal.saved + parsed).clamp(0.0, goal.target);
              final newProgress =
                  goal.target > 0 ? afterDeposit / goal.target : 0.0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  // header
                  Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppPalette.accentTeal.withOpacity(.15),
                      child: const Icon(Icons.add_rounded,
                          color: AppPalette.accentTeal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.name,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: text)),
                          Text(
                            'Sukaupta: €${goal.saved.toStringAsFixed(2)} iš €${goal.target.toStringAsFixed(2)}',
                            style:
                                TextStyle(fontSize: 12, color: subtext),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // quick-amount chips
                  Text('Greiti įnašai',
                      style: TextStyle(fontSize: 12, color: subtext)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      if (goal.monthlyContribution > 0)
                        _QuickChip(
                          label:
                              '€${goal.monthlyContribution.toStringAsFixed(0)} (mėnesinis)',
                          onTap: () {
                            amountCtrl.text = goal.monthlyContribution
                                .toStringAsFixed(2);
                            setS(() {});
                          },
                        ),
                      for (final q in [10.0, 50.0, 100.0, 200.0, 500.0])
                        if (q <= goal.remaining)
                          _QuickChip(
                            label: '€${q.toInt()}',
                            onTap: () {
                              amountCtrl.text = q.toStringAsFixed(2);
                              setS(() {});
                            },
                          ),
                      _QuickChip(
                        label: '€${goal.remaining.toStringAsFixed(2)} (visas)',
                        onTap: () {
                          amountCtrl.text =
                              goal.remaining.toStringAsFixed(2);
                          setS(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // amount field
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    onChanged: (_) => setS(() {}),
                    decoration: InputDecoration(
                      labelText: 'Suma (€)',
                      prefixIcon: const Icon(Icons.euro_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // live progress preview
                  if (parsed > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPalette.accentTeal.withOpacity(.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppPalette.accentTeal.withOpacity(.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Po įnašo:',
                                  style: TextStyle(
                                      fontSize: 12, color: subtext)),
                              Text(
                                '€${afterDeposit.toStringAsFixed(2)}  (${(newProgress * 100).toStringAsFixed(0)}%)',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.accentTeal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: newProgress,
                              backgroundColor:
                                  AppPalette.accentTeal.withOpacity(.15),
                              color: newProgress >= 1.0
                                  ? AppPalette.accentGreen
                                  : AppPalette.accentTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        parsed > 0
                            ? 'Pridėti €${parsed.toStringAsFixed(2)}'
                            : 'Pridėti',
                        style:
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.accentTeal,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: parsed <= 0
                          ? null
                          : () {
                              goal.saved = (goal.saved + parsed)
                                  .clamp(0, goal.target);
                              Navigator.pop(ctx);
                              _persistGoal(goal);
                              if (goal.isCompleted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Row(children: [
                                      const Text('🎉  '),
                                      Text(
                                          '${goal.name} tikslas pasiektas!'),
                                    ]),
                                    backgroundColor:
                                        AppPalette.accentGreen,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Sorting ───────────────────────────────────────────────────────────────

  List<Goal> _sorted(List<Goal> goals) {
    final list = [...goals];
    list.sort((a, b) {
      int cmp = switch (_sortField) {
        SortField.createdAt => a.createdAt.compareTo(b.createdAt),
        SortField.startDate => a.startDate.compareTo(b.startDate),
        SortField.endDate   => a.endDate.compareTo(b.endDate),
        SortField.target    => a.target.compareTo(b.target),
        SortField.progress  => a.progress.compareTo(b.progress),
      };
      return _sortOrder == SortOrder.desc ? -cmp : cmp;
    });
    return list;
  }

  void _showSortSheet() {
    final border   = AppPalette.border(context);
    final surface  = AppPalette.surface(context);
    final text     = AppPalette.primaryText(context);
    final subtext  = AppPalette.secondaryText(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: BoxDecoration(
            color: surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text('Rūšiuoti pagal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: text)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: SortField.values.map((f) {
                  final active = _sortField == f;
                  return GestureDetector(
                    onTap: () {
                      setS(() => _sortField = f);
                      setState(() => _sortField = f);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
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
                          Icon(f.icon,
                              size: 14,
                              color: active
                                  ? AppPalette.accentTeal
                                  : subtext),
                          const SizedBox(width: 6),
                          Text(f.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: active
                                      ? AppPalette.accentTeal
                                      : subtext,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w400)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Kryptis',
                  style: TextStyle(fontSize: 13, color: subtext)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _OrderBtn(
                    label: 'Didėjanti',
                    icon: Icons.arrow_upward_rounded,
                    active: _sortOrder == SortOrder.asc,
                    onTap: () {
                      setS(() => _sortOrder = SortOrder.asc);
                      setState(() => _sortOrder = SortOrder.asc);
                    },
                  ),
                  const SizedBox(width: 10),
                  _OrderBtn(
                    label: 'Mažėjanti',
                    icon: Icons.arrow_downward_rounded,
                    active: _sortOrder == SortOrder.desc,
                    onTap: () {
                      setS(() => _sortOrder = SortOrder.desc);
                      setState(() => _sortOrder = SortOrder.desc);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.accentTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Taikyti',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final background = AppPalette.background(context);
    final text       = AppPalette.primaryText(context);
    final surface    = AppPalette.surface(context);
    final border     = AppPalette.border(context);
    final subtext    = AppPalette.secondaryText(context);

    final sorted = _sorted(_goals);

    final totalSaved  = _goals.fold<double>(0, (a, g) => a + g.saved);
    final totalTarget = _goals.fold<double>(0, (a, g) => a + g.target);
    final overallProgress =
        totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Tikslai',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Rūšiuoti',
                onPressed: _showSortSheet,
              ),
              if (_sortField != SortField.createdAt ||
                  _sortOrder != SortOrder.desc)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: AppPalette.accentTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const ProfileActionButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── Hero summary card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppPalette.heroGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Viso sukaupta',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('€${totalSaved.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('iš €${totalTarget.toStringAsFixed(2)}',
                    style:
                        const TextStyle(color: Colors.white60)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: overallProgress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(overallProgress * 100).toStringAsFixed(0)}% bendras progresas',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${_goals.where((g) => g.isCompleted).length}/${_goals.length} tikslų',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Active sort indicator ────────────────────────────────────
          if (_goals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(_sortField.icon, size: 13, color: subtext),
                  const SizedBox(width: 5),
                  Text(
                    '${_sortField.label}  ·  ${_sortOrder == SortOrder.desc ? 'Mažėjanti' : 'Didėjanti'}',
                    style: TextStyle(fontSize: 12, color: subtext),
                  ),
                ],
              ),
            ),

          // ── Empty state ──────────────────────────────────────────────
          if (_goals.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, size: 40, color: subtext),
                  const SizedBox(height: 12),
                  Text(
                    'Dar nėra tikslų.\nSpausk + norėdamas pridėti.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtext, height: 1.5),
                  ),
                ],
              ),
            ),

          // ── Goal cards ───────────────────────────────────────────────
          ...sorted.map((goal) => _GoalCard(
                goal: goal,
                onTap: () => _showEditSheet(context, goal),
                onDeposit: () => _showDepositSheet(context, goal),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppPalette.accentTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ─── Add sheet ────────────────────────────────────────────────────────────

  void _showAddSheet(BuildContext context) {
    final nameCtrl    = TextEditingController();
    final targetCtrl  = TextEditingController();
    final initialCtrl = TextEditingController(text: '0');
    final monthlyCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate   = DateTime.now().add(const Duration(days: 365));
    double recommended = 0;
    String? selectedCategory;
    bool autoContribute = false;

    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final text    = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    void recalc(StateSetter setS) {
      final t = double.tryParse(targetCtrl.text) ?? 0;
      final i = double.tryParse(initialCtrl.text) ?? 0;
      final months = endDate.difference(startDate).inDays / 30;
      setS(() {
        recommended =
            months > 0 ? ((t - i) / months).clamp(0, double.infinity) : 0;
      });
    }

    final categories = ['Visi', ..._kTemplates.map((t) => t.category).toSet()];

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
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text('Naujas tikslas',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: text)),
                  const SizedBox(height: 14),

                  Text('Pasirink šabloną arba įvesk savo',
                      style: TextStyle(fontSize: 12, color: subtext)),
                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final active = selectedCategory == cat ||
                            (cat == 'Visi' && selectedCategory == null);
                        return GestureDetector(
                          onTap: () => setS(() =>
                              selectedCategory =
                                  cat == 'Visi' ? null : cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 130),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppPalette.accentTeal.withOpacity(.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: active
                                    ? AppPalette.accentTeal.withOpacity(.5)
                                    : border,
                                width: active ? 1.5 : 0.8,
                              ),
                            ),
                            child: Text(cat,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: active
                                        ? AppPalette.accentTeal
                                        : subtext,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w400)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _kTemplates
                        .where((t) =>
                            selectedCategory == null ||
                            t.category == selectedCategory)
                        .map((t) {
                      final isSelected = nameCtrl.text == t.name;
                      return GestureDetector(
                        onTap: () => setS(() => nameCtrl.text = t.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppPalette.accentTeal.withOpacity(.12)
                                : surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppPalette.accentTeal.withOpacity(.5)
                                  : border,
                              width: isSelected ? 1.5 : 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t.icon,
                                  style:
                                      const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Text(t.name,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? AppPalette.accentTeal
                                          : text,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  _field(nameCtrl, 'Pavadinimas (arba savo)',
                      TextInputType.text),
                  const SizedBox(height: 12),
                  _field(
                    targetCtrl, 'Tikslinė suma (€)',
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: () => recalc(setS),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    initialCtrl, 'Pradinė sukaupta suma (€)',
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: () => recalc(setS),
                  ),
                  const SizedBox(height: 12),
                  _field(monthlyCtrl, 'Mėnesinis įnašas (€)',
                      const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Pradžios data',
                        date: startDate,
                        onPick: (d) {
                          setS(() => startDate = d);
                          recalc(setS);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateButton(
                        label: 'Galutinė data',
                        date: endDate,
                        onPick: (d) {
                          setS(() => endDate = d);
                          recalc(setS);
                        },
                      ),
                    ),
                  ]),

                  if (recommended > 0) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => monthlyCtrl.text =
                          recommended.toStringAsFixed(2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppPalette.accentTeal.withOpacity(.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppPalette.accentTeal
                                  .withOpacity(.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 14,
                                color: AppPalette.accentTeal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Rekomenduojama: €${recommended.toStringAsFixed(2)}/mėn.',
                                style: TextStyle(
                                    color: AppPalette.accentTeal,
                                    fontSize: 13),
                              ),
                            ),
                            Text('Taikyti',
                                style: TextStyle(
                                    color: AppPalette.accentTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Auto-contribution toggle ──────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: autoContribute
                          ? AppPalette.accentTeal.withOpacity(.08)
                          : surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: autoContribute
                            ? AppPalette.accentTeal.withOpacity(.4)
                            : border,
                        width: autoContribute ? 1.5 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.autorenew_rounded,
                          size: 18,
                          color: autoContribute
                              ? AppPalette.accentTeal
                              : subtext,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Automatinis įnašas',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: autoContribute
                                      ? AppPalette.accentTeal
                                      : text,
                                ),
                              ),
                              Text(
                                'Kas mėnesį automatiškai pridedamas mėnesinis įnašas',
                                style: TextStyle(
                                    fontSize: 11, color: subtext),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: autoContribute,
                          activeColor: AppPalette.accentTeal,
                          onChanged: (v) => setS(() => autoContribute = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.accentTeal,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final name   = nameCtrl.text.trim();
                        final target = double.tryParse(targetCtrl.text) ?? 0;
                        final initial =
                            double.tryParse(initialCtrl.text) ?? 0;
                        final monthly =
                            double.tryParse(monthlyCtrl.text) ?? 0;

                        if (name.isEmpty || target <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Įvesk pavadinimą ir tikslinę sumą')));
                          return;
                        }
                        if (!endDate.isAfter(startDate)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Galutinė data turi būti vėlesnė')));
                          return;
                        }

                        final goal = Goal(
                          id: const Uuid().v4(),
                          name: name,
                          target: target,
                          initialSaved: initial.clamp(0, target),
                          saved: initial.clamp(0, target),
                          monthlyContribution: monthly,
                          startDate: startDate,
                          endDate: endDate,
                          createdAt: DateTime.now(),
                          autoContribute: autoContribute,
                          lastAutoApplied:
                              autoContribute ? DateTime.now() : null,
                        );

                        Navigator.pop(ctx);
                        _persistGoal(goal);
                      },
                      child: const Text('Sukurti tikslą',
                          style:
                              TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Edit sheet ───────────────────────────────────────────────────────────

  void _showEditSheet(BuildContext context, Goal goal) {
    final savedCtrl   = TextEditingController(
        text: goal.saved.toStringAsFixed(2));
    final monthlyCtrl = TextEditingController(
        text: goal.monthlyContribution.toStringAsFixed(2));
    bool autoContribute = goal.autoContribute;

    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final text    = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
          child: StatefulBuilder(
            builder: (ctx, setS) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(goal.name,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: text)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteGoal(goal.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _field(savedCtrl, 'Sukaupta suma (€)',
                    const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _field(monthlyCtrl, 'Mėnesinis įnašas (€)',
                    const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),

                // ── Auto-contribution toggle (edit) ───────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: autoContribute
                        ? AppPalette.accentTeal.withOpacity(.08)
                        : surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: autoContribute
                          ? AppPalette.accentTeal.withOpacity(.4)
                          : border,
                      width: autoContribute ? 1.5 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.autorenew_rounded,
                        size: 18,
                        color: autoContribute
                            ? AppPalette.accentTeal
                            : subtext,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Automatinis įnašas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: autoContribute
                                    ? AppPalette.accentTeal
                                    : text,
                              ),
                            ),
                            Text(
                              'Kas mėnesį automatiškai pridedamas mėnesinis įnašas',
                              style: TextStyle(
                                  fontSize: 11, color: subtext),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: autoContribute,
                        activeColor: AppPalette.accentTeal,
                        onChanged: (v) => setS(() => autoContribute = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.accentTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      goal.saved =
                          (double.tryParse(savedCtrl.text) ?? goal.saved)
                              .clamp(0, goal.target);
                      goal.monthlyContribution =
                          double.tryParse(monthlyCtrl.text) ??
                              goal.monthlyContribution;
                      final wasOff = !goal.autoContribute && autoContribute;
                      goal.autoContribute = autoContribute;
                      // reset lastAutoApplied if just enabled
                      if (wasOff) {
                        goal.lastAutoApplied = DateTime.now();
                      }
                      Navigator.pop(context);
                      _persistGoal(goal);
                    },
                    child: const Text('Išsaugoti',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    TextInputType type, {
    VoidCallback? onChanged,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        onChanged: onChanged != null ? (_) => onChanged() : null,
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

// ─── Goal card widget ─────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  final VoidCallback onDeposit;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border  = AppPalette.border(context);
    final text    = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

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
            color: goal.isCompleted
                ? AppPalette.accentGreen.withOpacity(0.5)
                : border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      AppPalette.accentTeal.withOpacity(.15),
                  child: const Icon(Icons.flag_rounded,
                      color: AppPalette.accentTeal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(goal.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: text)),
                ),
                // ── auto badge ──
                if (goal.autoContribute) ...[
                  Tooltip(
                    message: 'Automatinis įnašas įjungtas',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppPalette.accentTeal.withOpacity(.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color:
                                AppPalette.accentTeal.withOpacity(.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.autorenew_rounded,
                              size: 11,
                              color: AppPalette.accentTeal),
                          const SizedBox(width: 3),
                          Text('Auto',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppPalette.accentTeal,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (goal.isCompleted)
                  const Icon(Icons.check_circle_rounded,
                      color: AppPalette.accentGreen, size: 20),
                const SizedBox(width: 4),
                Text('€${goal.target.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: text, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sukaupta: €${goal.saved.toStringAsFixed(2)}',
                    style: TextStyle(color: subtext, fontSize: 13)),
                Text('Liko: €${goal.remaining.toStringAsFixed(2)}',
                    style: TextStyle(color: subtext, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: goal.progress,
                backgroundColor:
                    AppPalette.accentTeal.withOpacity(.15),
                color: goal.isCompleted
                    ? AppPalette.accentGreen
                    : AppPalette.accentTeal,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(goal.progress * 100).toStringAsFixed(0)}% įvykdyta',
                  style: TextStyle(color: subtext, fontSize: 12),
                ),
                Text(
                  'iki ${_fmt(goal.endDate)}',
                  style: TextStyle(color: subtext, fontSize: 12),
                ),
              ],
            ),
            if (goal.monthlyContribution > 0) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.accentTeal.withOpacity(.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew,
                        size: 13,
                        color: AppPalette.accentTeal),
                    const SizedBox(width: 4),
                    Text(
                      '€${goal.monthlyContribution.toStringAsFixed(2)}/mėn.  ·  '
                      'Rekomenduojama: €${goal.recommendedMonthly().toStringAsFixed(2)}',
                      style: TextStyle(
                          color: AppPalette.accentTeal, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],

            // ── Deposit button ────────────────────────────────────────
            if (!goal.isCompleted) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDeposit,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Pridėti pinigų',
                      style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.accentTeal,
                    side: BorderSide(
                        color: AppPalette.accentTeal.withOpacity(.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Quick chip ───────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final border  = AppPalette.border(context);
    final subtext = AppPalette.secondaryText(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, color: subtext)),
      ),
    );
  }
}

// ─── Order toggle button ──────────────────────────────────────────────────────

class _OrderBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _OrderBtn(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final border  = AppPalette.border(context);
    final surface = AppPalette.surface(context);
    final subtext = AppPalette.secondaryText(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppPalette.accentTeal.withOpacity(.1)
                : surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppPalette.accentTeal.withOpacity(.5)
                  : border,
              width: active ? 1.5 : 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: active ? AppPalette.accentTeal : subtext),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: active ? AppPalette.accentTeal : subtext,
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Date picker button ───────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DateButton(
      {required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      icon: const Icon(Icons.calendar_today, size: 14),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}