import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
import '../services/income_service.dart';
import '../theme/app_palette.dart';
import 'widgets/add_income_sheet.dart';
import 'widgets/income_chart.dart';
import 'widgets/profile_action_button.dart';

enum IncomeSortField { date, amount }

enum SortDirection { asc, desc }

enum IncomeChartType { trend, categories }

class IncomePage extends StatefulWidget {
  final IncomeService? incomeService;
  final String? Function()? currentUserId;
  final DateTime? initialMonth;
  final Widget? profileAction;

  const IncomePage({
    super.key,
    this.incomeService,
    this.currentUserId,
    this.initialMonth,
    this.profileAction,
  });

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  late final IncomeService _incomeService;

  String? get _uid {
    final currentUserId = widget.currentUserId;
    if (currentUserId != null) {
      return currentUserId();
    }

    return FirebaseAuth.instance.currentUser?.uid;
  }

  String get _requiredUid {
    final uid = _uid;
    if (uid == null) {
      throw StateError('IncomePage requires an authenticated user.');
    }

    return uid;
  }

  late DateTime _selectedMonth;
  IncomePeriod _selectedPeriod = IncomePeriod.month;
  IncomeChartType _selectedChartType = IncomeChartType.categories;
  IncomeSortField _sortField = IncomeSortField.date;
  SortDirection _sortDirection = SortDirection.desc;
  Stream<List<Income>>? _incomeStream;
  List<Income> _latestIncomes = [];
  String? _streamUid;
  DateTime? _streamStart;

  @override
  void initState() {
    super.initState();
    _incomeService = widget.incomeService ?? IncomeService();
    _selectedMonth = _clampToCurrentMonth(
      widget.initialMonth ?? DateTime.now(),
    );
  }

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);

  DateTime _currentMonth() => _monthStart(DateTime.now());

  DateTime _clampToCurrentMonth(DateTime date) {
    final month = _monthStart(date);
    final currentMonth = _currentMonth();

    return month.isAfter(currentMonth) ? currentMonth : month;
  }

  bool get _isCurrentMonth =>
      _monthStart(_selectedMonth).isAtSameMomentAs(_currentMonth());

  void _goToCurrentMonth() {
    if (_isCurrentMonth) {
      return;
    }

    setState(() {
      _selectedMonth = _currentMonth();
    });
  }

  String get _sortFieldLabel {
    switch (_sortField) {
      case IncomeSortField.amount:
        return 'Suma';
      case IncomeSortField.date:
      default:
        return 'Data';
    }
  }

  String get _sortDirectionLabel {
    switch (_sortDirection) {
      case SortDirection.asc:
        return 'Didėjančiai';
      case SortDirection.desc:
      default:
        return 'Mažėjančiai';
    }
  }

  int _compareIncome(Income a, Income b) {
    final comparison = _sortField == IncomeSortField.amount
        ? a.amount.compareTo(b.amount)
        : a.date.compareTo(b.date);

    return _sortDirection == SortDirection.asc ? comparison : -comparison;
  }

  DateTime _incomeStreamStart() {
    final now = DateTime.now();
    final chartStart = _chartStartDate(now);
    final monthStart = _monthStart(_selectedMonth);

    return monthStart.isBefore(chartStart) ? monthStart : chartStart;
  }

  void _ensureIncomeStream(String uid) {
    final streamStart = _incomeStreamStart();
    if (_incomeStream != null &&
        _streamUid == uid &&
        _streamStart == streamStart) {
      return;
    }

    _streamUid = uid;
    _streamStart = streamStart;
    _incomeStream = _incomeService.watchIncomesSince(uid, streamStart);
  }

  DateTime _chartStartDate(DateTime now) {
    switch (_selectedPeriod) {
      case IncomePeriod.week:
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
      case IncomePeriod.month:
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
      case IncomePeriod.sixMonths:
        return DateTime(now.year, now.month - 5, 1);
      case IncomePeriod.year:
        return DateTime(now.year, now.month - 11, 1);
    }
  }

  Future<void> _openAddIncome() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddIncomeSheet(
          onSave: (income) async {
            await _incomeService.addIncome(_requiredUid, income);
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Pajama pridėta')));
            }
          },
        );
      },
    );
  }

  Future<void> _openEditIncome(Income income) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddIncomeSheet(
          initialIncome: income,
          onSave: (updatedIncome) async {
            await _incomeService.updateIncome(
              _requiredUid,
              income.id,
              updatedIncome,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pajama atnaujinta')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _deleteIncome(String incomeId) async {
    await _incomeService.deleteIncome(_requiredUid, incomeId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pajama ištrinta')));
    }
  }

  Future<void> _confirmDelete(Income income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final surface = AppPalette.surface(dialogContext);
        final text = AppPalette.primaryText(dialogContext);
        final subtext = AppPalette.secondaryText(dialogContext);

        return AlertDialog(
          backgroundColor: surface,
          title: Text('Ištrinti pajamą?', style: TextStyle(color: text)),
          content: Text(
            'Ar tikrai nori ištrinti "${income.category.label}"?',
            style: TextStyle(color: subtext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Atšaukti'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ištrinti'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteIncome(income.id);
    }
  }

  Widget _buildChartTypeButton({
    required IncomeChartType type,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color surfaceColor,
  }) {
    final isSelected = _selectedChartType == type;

    return ChoiceChip(
      key: ValueKey('income-chart-type-${type.name}'),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : textColor,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppPalette.accentPurple,
      backgroundColor: surfaceColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : textColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) {
        if (isSelected) {
          return;
        }

        setState(() {
          _selectedChartType = type;
        });
      },
    );
  }

  Widget _buildChartEmptyState(Color subtext) {
    return Center(
      child: Text(
        'Nėra pajamų šiame laikotarpyje',
        textAlign: TextAlign.center,
        style: TextStyle(color: subtext),
      ),
    );
  }

  Widget _buildCategoryChart({
    required List<MapEntry<IncomeCategory, double>> sortedCategories,
    required double monthTotal,
    required Color textColor,
    required Color subtext,
  }) {
    if (sortedCategories.isEmpty || monthTotal <= 0) {
      return SizedBox(height: 260, child: _buildChartEmptyState(subtext));
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: RepaintBoundary(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 62,
                    sectionsSpace: 4,
                    sections: sortedCategories.map((entry) {
                      final category = entry.key;
                      final sum = entry.value;
                      return PieChartSectionData(
                        value: sum,
                        color: category.color,
                        radius: 22,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mėnesio suma', style: TextStyle(color: subtext)),
                    const SizedBox(height: 6),
                    Text(
                      '${monthTotal.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedCategories.map((entry) {
            final category = entry.key;
            final sum = entry.value;
            final percentage = (sum / monthTotal * 100).toStringAsFixed(1);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: category.color.withOpacity(.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.emoji),
                  const SizedBox(width: 8),
                  Text(
                    '${category.label} • ${sum.toStringAsFixed(2)} € ($percentage%)',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Pirma prisijunk')));
    }

    _ensureIncomeStream(uid);

    final background = AppPalette.background(context);
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Pajamos'),
        actions: [widget.profileAction ?? const ProfileActionButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppPalette.accentPurple,
        foregroundColor: Colors.white,
        onPressed: _openAddIncome,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pridėti'),
      ),
      body: StreamBuilder<List<Income>>(
        stream: _incomeStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _latestIncomes = snapshot.data!;
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              _latestIncomes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _latestIncomes.isEmpty) {
            return Center(child: Text('Įvyko klaida: ${snapshot.error}'));
          }

          final incomes = snapshot.data ?? _latestIncomes;

          final monthStart = _monthStart(_selectedMonth);
          final monthEnd = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + 1,
            1,
          );
          final filteredIncomes = incomes
              .where(
                (income) =>
                    income.date.isAfter(
                      monthStart.subtract(const Duration(days: 1)),
                    ) &&
                    income.date.isBefore(monthEnd.add(const Duration(days: 1))),
              )
              .toList();
          filteredIncomes.sort(_compareIncome);

          final monthTotal = filteredIncomes.fold<double>(
            0,
            (sum, income) => sum + income.amount,
          );

          final categorySums = <IncomeCategory, double>{};
          for (final income in filteredIncomes) {
            categorySums[income.category] =
                (categorySums[income.category] ?? 0) + income.amount;
          }
          final sortedCategories = categorySums.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppPalette.heroGradient,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          key: const ValueKey('income-previous-month'),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month - 1,
                              );
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Pasirinktas mėnuo',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('yyyy MMMM').format(_selectedMonth),
                                textAlign: TextAlign.center,
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
                          key: const ValueKey('income-next-month'),
                          onPressed: _isCurrentMonth
                              ? null
                              : () {
                                  setState(() {
                                    _selectedMonth = _clampToCurrentMonth(
                                      DateTime(
                                        _selectedMonth.year,
                                        _selectedMonth.month + 1,
                                      ),
                                    );
                                  });
                                },
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: Colors.white,
                          disabledColor: Colors.white38,
                        ),
                      ],
                    ),
                    if (!_isCurrentMonth) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        key: const ValueKey('income-current-month'),
                        onPressed: _goToCurrentMonth,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(.14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.today_rounded, size: 18),
                        label: const Text('Grįžti'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChartTypeButton(
                          type: IncomeChartType.categories,
                          label: 'Kategorijos',
                          icon: Icons.pie_chart_rounded,
                          textColor: text,
                          surfaceColor: surface,
                        ),
                        _buildChartTypeButton(
                          type: IncomeChartType.trend,
                          label: 'Tendencija',
                          icon: Icons.show_chart_rounded,
                          textColor: text,
                          surfaceColor: surface,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _selectedChartType == IncomeChartType.trend
                          ? IncomeChart(
                              key: const ValueKey('income-trend-chart'),
                              incomes: incomes,
                              selectedPeriod: _selectedPeriod,
                              onPeriodSelected: (period) {
                                setState(() {
                                  _selectedPeriod = period;
                                });
                              },
                              textColor: text,
                              borderColor: border,
                              surfaceColor: surface,
                            )
                          : _buildCategoryChart(
                              sortedCategories: sortedCategories,
                              monthTotal: monthTotal,
                              textColor: text,
                              subtext: subtext,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                    Text('Rūšiavimas', style: TextStyle(color: subtext)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<IncomeSortField>(
                            key: const ValueKey('income-sort-field'),
                            value: _sortField,
                            decoration: InputDecoration(
                              labelText: 'Kriterijus',
                              labelStyle: TextStyle(color: subtext),
                              filled: true,
                              fillColor: surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: border),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: IncomeSortField.date,
                                child: Text('Data'),
                              ),
                              DropdownMenuItem(
                                value: IncomeSortField.amount,
                                child: Text('Suma'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _sortField = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<SortDirection>(
                            key: const ValueKey('income-sort-direction'),
                            value: _sortDirection,
                            decoration: InputDecoration(
                              labelText: 'Kryptis',
                              labelStyle: TextStyle(color: subtext),
                              filled: true,
                              fillColor: surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: border),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: SortDirection.asc,
                                child: Text('Didėjančiai'),
                              ),
                              DropdownMenuItem(
                                value: SortDirection.desc,
                                child: Text('Mažėjančiai'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _sortDirection = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _latestIncomes.isEmpty &&
                  filteredIncomes.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (filteredIncomes.isNotEmpty)
                ...filteredIncomes.map((income) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border),
                    ),
                    child: ListTile(
                      key: ValueKey('income-item-${income.id}'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: income.category.color.withOpacity(.15),
                        child: Icon(
                          income.category.icon,
                          color: income.category.color,
                        ),
                      ),
                      title: Text(
                        income.category.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (income.note.isNotEmpty)
                            Text(income.note, style: TextStyle(color: subtext)),
                          Text(
                            DateFormat('dd.MM.yyyy').format(income.date),
                            style: TextStyle(color: subtext),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        key: ValueKey('income-menu-${income.id}'),
                        color: surface,
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _openEditIncome(income);
                          } else if (value == 'delete') {
                            await _confirmDelete(income);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Redaguoti'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Ištrinti'),
                          ),
                        ],
                        child: Text(
                          '+€${income.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppPalette.accentPurple,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
