import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../theme/app_palette.dart';
import 'widgets/add_expense_sheet.dart';
import 'widgets/profile_action_button.dart';

enum ExpenseSort {
  newest,
  oldest,
  highest,
  lowest,
  category,
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final ExpenseService _expenseService = ExpenseService();

  DateTime _selectedMonth = DateTime.now();
  ExpenseCategory? _selectedCategory;
  ExpenseSort _sort = ExpenseSort.newest;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _openAddExpense() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddExpenseSheet(
          onSave: (expense) async {
            await _expenseService.addExpense(_uid, expense);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Išlaida pridėta')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _openEditExpense(Expense expense) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddExpenseSheet(
          initialExpense: expense,
          onSave: (updatedExpense) async {
            await _expenseService.updateExpense(_uid, expense.id, updatedExpense);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Išlaida atnaujinta')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _deleteExpense(String expenseId) async {
    await _expenseService.deleteExpense(_uid, expenseId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Išlaida ištrinta')),
      );
    }
  }

  Future<void> _confirmDelete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final surface = AppPalette.surface(dialogContext);
        final text = AppPalette.primaryText(dialogContext);
        final subtext = AppPalette.secondaryText(dialogContext);

        return AlertDialog(
          backgroundColor: surface,
          title: Text('Ištrinti išlaidą?', style: TextStyle(color: text)),
          content: Text(
            'Ar tikrai nori ištrinti "${expense.note.isEmpty ? expense.category.label : expense.note}"?',
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
      await _deleteExpense(expense.id);
    }
  }

  Future<void> _showExpenseDetails(Expense expense) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final surface = AppPalette.surface(sheetContext);
        final border = AppPalette.border(sheetContext);
        final text = AppPalette.primaryText(sheetContext);
        final subtext = AppPalette.secondaryText(sheetContext);

        return FractionallySizedBox(
          heightFactor: 0.74,
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: SingleChildScrollView(
                  child: Column(
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
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: expense.category.color.withOpacity(.15),
                        child: Text(
                          expense.category.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        expense.note.isEmpty ? expense.category.label : expense.note,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '-€${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.accentGreen,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: expense.category.icon,
                              label: 'Kategorija',
                              value: expense.category.shortLabel,
                            ),
                            _DetailRow(
                              icon: Icons.calendar_month_rounded,
                              label: 'Data',
                              value: DateFormat('dd.MM.yyyy').format(expense.date),
                            ),
                            _DetailRow(
                              icon: Icons.notes_rounded,
                              label: 'Pastaba',
                              value: expense.note.isEmpty ? '—' : expense.note,
                            ),
                            _DetailRow(
                              icon: Icons.schedule_rounded,
                              label: 'Sukurta',
                              value: expense.createdAt != null
                                  ? DateFormat('yyyy-MM-dd HH:mm')
                                      .format(expense.createdAt!)
                                  : '—',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                side: BorderSide(color: border),
                              ),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _openEditExpense(expense);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Redaguoti'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              onPressed: () async {
                                Navigator.pop(sheetContext);
                                await _confirmDelete(expense);
                              },
                              icon: const Icon(Icons.delete_rounded),
                              label: const Text('Ištrinti'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(
                          'Uždaryti',
                          style: TextStyle(color: subtext),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Expense> _processExpenses(List<Expense> expenses) {
    var list = expenses.toList();

    if (_selectedCategory != null) {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }

    switch (_sort) {
      case ExpenseSort.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ExpenseSort.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ExpenseSort.highest:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case ExpenseSort.lowest:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case ExpenseSort.category:
        list.sort((a, b) => a.category.label.compareTo(b.category.label));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Pirma prisijunk'),
        ),
      );
    }

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
        title: const Text('Išlaidos'),
        actions: [
          PopupMenuButton<ExpenseSort>(
            color: surface,
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ExpenseSort.newest,
                child: Text('Naujausios viršuje'),
              ),
              PopupMenuItem(
                value: ExpenseSort.oldest,
                child: Text('Seniausios viršuje'),
              ),
              PopupMenuItem(
                value: ExpenseSort.highest,
                child: Text('Didžiausios sumos'),
              ),
              PopupMenuItem(
                value: ExpenseSort.lowest,
                child: Text('Mažiausios sumos'),
              ),
              PopupMenuItem(
                value: ExpenseSort.category,
                child: Text('Pagal kategoriją'),
              ),
            ],
          ),
          const ProfileActionButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppPalette.accentGreen,
        foregroundColor: Colors.black,
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pridėti'),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.watchMonthlyExpenses(_uid, _selectedMonth),
        builder: (context, snapshot) {
          final rawExpenses = snapshot.data ?? [];
          final expenses = _processExpenses(rawExpenses);

          final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
          final biggest = expenses.isEmpty
              ? 0.0
              : expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
          final average = expenses.isEmpty ? 0.0 : total / expenses.length;

          final Map<ExpenseCategory, double> grouped = {};
          for (final expense in expenses) {
            grouped[expense.category] = (grouped[expense.category] ?? 0) + expense.amount;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
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
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
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
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
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
                  children: [
                    SizedBox(
                      height: 240,
                      child: expenses.isEmpty
                          ? Center(
                              child: Text(
                                'Šį mėnesį išlaidų dar nėra',
                                style: TextStyle(color: subtext),
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    centerSpaceRadius: 62,
                                    sectionsSpace: 4,
                                    sections: grouped.entries.map((entry) {
                                      return PieChartSectionData(
                                        value: entry.value,
                                        color: entry.key.color,
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
                                      '€${total.toStringAsFixed(2)}',
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: grouped.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: entry.key.color.withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: entry.key.color.withOpacity(.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(entry.key.emoji),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.key.label} • €${entry.value.toStringAsFixed(2)}',
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
              Row(
                children: [
                  _StatCard(
                    title: 'Įrašai',
                    value: '${expenses.length}',
                    icon: Icons.receipt_long_rounded,
                    color: Colors.deepPurple.shade300,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: 'Vidurkis',
                    value: '€${average.toStringAsFixed(2)}',
                    icon: Icons.analytics_rounded,
                    color: AppPalette.accentGreen,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: 'Didžiausia',
                    value: '€${biggest.toStringAsFixed(2)}',
                    icon: Icons.trending_up_rounded,
                    color: Colors.orange.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: _selectedCategory == null,
                        label: const Text('Visos'),
                        selectedColor: AppPalette.accentGreen.withOpacity(.18),
                        backgroundColor: surface,
                        shape: StadiumBorder(side: BorderSide(color: border)),
                        onSelected: (_) {
                          setState(() => _selectedCategory = null);
                        },
                      ),
                    ),
                    ...ExpenseCategory.values.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: _selectedCategory == category,
                          label: Text(category.shortLabel),
                          selectedColor: category.color.withOpacity(.18),
                          backgroundColor: surface,
                          shape: StadiumBorder(side: BorderSide(color: border)),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory =
                                  _selectedCategory == category ? null : category;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting && rawExpenses.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (expenses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 54, color: subtext),
                      const SizedBox(height: 12),
                      Text(
                        'Nėra išlaidų pagal pasirinktą laikotarpį arba filtrą',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtext),
                      ),
                    ],
                  ),
                )
              else
                ...expenses.map((expense) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border),
                    ),
                    child: ListTile(
                      onTap: () => _showExpenseDetails(expense),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: expense.category.color.withOpacity(.15),
                        child: Text(expense.category.emoji),
                      ),
                      title: Text(
                        expense.note.isEmpty ? expense.category.label : expense.note,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      subtitle: Text(
                        '${expense.category.shortLabel} • ${DateFormat('dd.MM.yyyy').format(expense.date)}',
                        style: TextStyle(color: subtext),
                      ),
                      trailing: PopupMenuButton<String>(
                        color: surface,
                        onSelected: (value) async {
                          if (value == 'view') {
                            await _showExpenseDetails(expense);
                          } else if (value == 'edit') {
                            await _openEditExpense(expense);
                          } else if (value == 'delete') {
                            await _confirmDelete(expense);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'view',
                            child: Text('Peržiūrėti'),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Redaguoti'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Ištrinti'),
                          ),
                        ],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '-€${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppPalette.accentGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Detaliau',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtext,
                              ),
                            ),
                          ],
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: subtext)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppPalette.accentPurple.withOpacity(.15),
            child: Icon(icon, size: 18, color: AppPalette.accentPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: subtext)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}