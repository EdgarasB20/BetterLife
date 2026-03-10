import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../theme/app_palette.dart';
import 'expenses_page.dart';
import 'widgets/add_expense_sheet.dart';
import 'widgets/profile_action_button.dart';
import 'budget_page.dart';

class FinancesPage extends StatelessWidget {
  const FinancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final expenseService = ExpenseService();

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Prisijunk, kad matytum savo finansus.'),
        ),
      );
    }

    final month = DateTime.now();
    final background = AppPalette.background(context);
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    Future<void> openQuickActions() async {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppPalette.accentGreen.withOpacity(.18),
                        child: const Icon(
                          Icons.remove_rounded,
                          color: AppPalette.accentGreen,
                        ),
                      ),
                      title: Text(
                        'Pridėti išlaidą',
                        style: TextStyle(color: text),
                      ),
                      subtitle: Text(
                        'Maistas, transportas, sąskaitos ir kita',
                        style: TextStyle(color: subtext),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddExpenseSheet(
                            onSave: (expense) async {
                              await expenseService.addExpense(user.uid, expense);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Išlaida pridėta')),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppPalette.accentPurple.withOpacity(.18),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppPalette.accentPurple,
                        ),
                      ),
                      title: Text(
                        'Pridėti pajamas',
                        style: TextStyle(color: text),
                      ),
                      subtitle: Text(
                        'Padarysim kitame etape',
                        style: TextStyle(color: subtext),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pajamų modulis bus kitame etape'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppPalette.accentTeal.withOpacity(.18),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: AppPalette.accentTeal,
                        ),
                      ),
                      title: Text(
                        'Pridėti tikslą',
                        style: TextStyle(color: text),
                      ),
                      subtitle: Text(
                        'Padarysim vėliau',
                        style: TextStyle(color: subtext),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tikslų modulis bus vėliau'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Finances'),
        actions: const [
          ProfileActionButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppPalette.accentGreen,
        foregroundColor: Colors.black,
        onPressed: openQuickActions,
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.watchMonthlyExpenses(user.uid, month),
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? [];
          final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
          final recent = expenses.take(3).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: AppPalette.heroGradient,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finansų suvestinė',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Viena vieta biudžetui,\npajamoms ir išlaidoms',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.18,
                children: [
                  _FinanceCard(
                    title: 'Išlaidos',
                    value: '€${totalExpenses.toStringAsFixed(2)}',
                    subtitle: 'Šį mėnesį',
                    icon: Icons.pie_chart_rounded,
                    accent: AppPalette.accentGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExpensesPage(),
                        ),
                      );
                    },
                  ),
                  _FinanceCard(
                    title: 'Pajamos',
                    value: '—',
                    subtitle: 'Kitas etapas',
                    icon: Icons.trending_up_rounded,
                    accent: AppPalette.accentPurple,
                    onTap: () {},
                  ),
                  _FinanceCard(
                    title: 'Biudžetas',
                    value: 'Atidaryti',
                    subtitle: 'Mėnesio limitai',
                    icon: Icons.account_balance_wallet_rounded,
                    accent: Colors.orange.shade400,
                    onTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (_) => const BudgetPage(),
                      ),
                      );
                    },
                  ),
                  _FinanceCard(
                    title: 'Tikslai',
                    value: '—',
                    subtitle: 'Kitas etapas',
                    icon: Icons.flag_rounded,
                    accent: AppPalette.accentTeal,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                    Row(
                      children: [
                        Text(
                          'Naujausios išlaidos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: text,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExpensesPage(),
                              ),
                            );
                          },
                          child: const Text('Atidaryti'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        expenses.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (recent.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            'Kol kas nėra išlaidų įrašų',
                            style: TextStyle(color: subtext),
                          ),
                        ),
                      )
                    else
                      ...recent.map(
                        (expense) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: expense.category.color.withOpacity(.15),
                              child: Text(expense.category.emoji),
                            ),
                            title: Text(
                              expense.note.isEmpty
                                  ? expense.category.label
                                  : expense.note,
                              style: TextStyle(color: text),
                            ),
                            subtitle: Text(
                              expense.category.shortLabel,
                              style: TextStyle(color: subtext),
                            ),
                            trailing: Text(
                              '-€${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppPalette.accentGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _FinanceCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: accent.withOpacity(.15),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: subtext,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: subtext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}