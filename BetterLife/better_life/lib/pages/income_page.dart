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

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final IncomeService _incomeService = IncomeService();
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DateTime _selectedMonth = DateTime.now();
  IncomePeriod _selectedPeriod = IncomePeriod.month;
  IncomeSortField _sortField = IncomeSortField.date;
  SortDirection _sortDirection = SortDirection.desc;

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

  Stream<List<Income>> get _incomeStream {
    final now = DateTime.now();
    final chartStart = _chartStartDate(now);
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final streamStart = monthStart.isBefore(chartStart)
        ? monthStart
        : chartStart;
    return _incomeService.watchIncomesSince(_uid, streamStart);
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
            await _incomeService.addIncome(_uid, income);
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
            await _incomeService.updateIncome(_uid, income.id, updatedIncome);
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
    await _incomeService.deleteIncome(_uid, incomeId);
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

  @override
  Widget build(BuildContext context) {
    // final user = FirebaseAuth.instance.currentUser;
    // if (user == null) {
    //   return const Scaffold(
    //     body: Center(
    //       child: Text('Pirma prisijunk'),
    //     ),
    //   );
    // }

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
        actions: [const ProfileActionButton()],
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Įvyko klaida: ${snapshot.error}'));
          }

          final incomes = snapshot.data ?? [];

          final monthStart = DateTime(
            _selectedMonth.year,
            _selectedMonth.month,
            1,
          );
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
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: IncomeChart(
                  incomes: snapshot.data ?? [],
                  selectedPeriod: _selectedPeriod,
                  onPeriodSelected: (period) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                  textColor: text,
                  borderColor: border,
                  surfaceColor: surface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppPalette.heroGradient,
                ),
                child: Row(
                  children: [
                    IconButton(
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
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                          );
                        });
                      },
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
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
                child: filteredIncomes.isEmpty
                    ? Column(
                        children: [
                          Text(
                            '0.00 €',
                            style: TextStyle(
                              color: text,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Šiame mėnesyje pajamų nėra',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: subtext),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 240,
                            child: filteredIncomes.isEmpty
                                ? Center(
                                    child: Text(
                                      'Šiame mėnesyje pajamų nėra',
                                      style: TextStyle(color: subtext),
                                    ),
                                  )
                                : RepaintBoundary(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        PieChart(
                                          PieChartData(
                                            centerSpaceRadius: 62,
                                            sectionsSpace: 4,
                                            sections: sortedCategories.map((
                                              entry,
                                            ) {
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
                                            Text(
                                              'Mėnesio suma',
                                              style: TextStyle(color: subtext),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${monthTotal.toStringAsFixed(2)} €',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                                color: text,
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
                              final percentage = (sum / monthTotal * 100)
                                  .toStringAsFixed(1);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: category.color.withOpacity(.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(category.emoji),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${category.label} • ${sum.toStringAsFixed(2)} € ($percentage%)',
                                      style: TextStyle(color: text),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
