import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../services/budget_service.dart';
import '../services/expense_service.dart';
import '../theme/app_palette.dart';
import 'widgets/add_budget_sheet.dart';
import 'widgets/profile_action_button.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final ExpenseService _expenseService = ExpenseService();
  final BudgetService _budgetService = BudgetService();

  DateTime _selectedMonth = DateTime.now();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _openBudgetEditor(
    ExpenseCategory category,
    Budget? existing,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddBudgetSheet(
          category: category,
          month: _selectedMonth,
          initialBudget: existing,
          onSave: (budget) async {
            await _budgetService.setBudget(_uid, budget);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Biudžetas išsaugotas')),
              );
            }
          },
        );
      },
    );
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
        title: const Text('Biudžetas'),
        actions: const [
          ProfileActionButton(),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.watchMonthlyExpenses(_uid, _selectedMonth),
        builder: (context, expenseSnap) {
          final expenses = expenseSnap.data ?? [];

          final spentByCategory = <ExpenseCategory, double>{};
          for (final expense in expenses) {
            spentByCategory[expense.category] =
                (spentByCategory[expense.category] ?? 0) + expense.amount;
          }

          return StreamBuilder<List<Budget>>(
            stream: _budgetService.watchMonthlyBudgets(_uid, _selectedMonth),
            builder: (context, budgetSnap) {
              final budgets = budgetSnap.data ?? [];
              final budgetByCategory = {
                for (final b in budgets) b.category: b,
              };

              final totalSpent =
                  spentByCategory.values.fold<double>(0, (a, b) => a + b);
              final totalLimit = budgetByCategory.values.fold<double>(
                0,
                (a, b) => a + b.limit,
              );

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
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white),
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
                          icon: const Icon(Icons.chevron_right_rounded,
                              color: Colors.white),
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
                        Text(
                          'Mėnesio suvestinė',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Išleista: €${totalSpent.toStringAsFixed(2)}',
                          style: TextStyle(color: subtext),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bendras limitas: €${totalLimit.toStringAsFixed(2)}',
                          style: TextStyle(color: subtext),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ExpenseCategory.values.map((category) {
                    final budget = budgetByCategory[category];
                    final limit = budget?.limit ?? 0;
                    final spent = spentByCategory[category] ?? 0;
                    final progress =
                        limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);

                    return InkWell(
                      onTap: () => _openBudgetEditor(category, budget),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      category.color.withOpacity(.15),
                                  child: Text(category.emoji),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: text,
                                    ),
                                  ),
                                ),
                                Text(
                                  limit > 0
                                      ? '€${limit.toStringAsFixed(2)}'
                                      : 'Nustatyk',
                                  style: TextStyle(
                                    color: limit > 0
                                        ? text
                                        : AppPalette.accentGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Išleista: €${spent.toStringAsFixed(2)}',
                              style: TextStyle(color: subtext),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: progress,
                                backgroundColor:
                                    category.color.withOpacity(.15),
                                color: category.color,
                              ),
                            ),
                            if (limit > 0 && spent > limit) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Viršytas limitas',
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}