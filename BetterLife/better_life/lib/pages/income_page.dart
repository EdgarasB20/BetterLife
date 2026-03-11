import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/income_service.dart';
import '../theme/app_palette.dart';
import 'widgets/add_income_sheet.dart';
import 'widgets/profile_action_button.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  // final IncomeService _incomeService = IncomeService();
  // String get _uid => FirebaseAuth.instance.currentUser!.uid;
  
  // Lokalus saugojimas - duomenų sąrašas atmintyje
  List<Income> _incomes = [];

  Future<void> _openAddIncome() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddIncomeSheet(
          onSave: (income) async {
            // await _incomeService.addIncome(_uid, income);
            setState(() {
              _incomes.add(income);
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pajama pridėta')),
              );
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
            // await _incomeService.updateIncome(_uid, income.id, updatedIncome);
            setState(() {
              final index = _incomes.indexWhere((e) => e.id == income.id);
              if (index != -1) {
                _incomes[index] = updatedIncome;
              }
            });
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
    // await _incomeService.deleteIncome(_uid, incomeId);
    setState(() {
      _incomes.removeWhere((income) => income.id == incomeId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pajama ištrinta')),
      );
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
        actions: [
          const ProfileActionButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppPalette.accentPurple,
        foregroundColor: Colors.white,
        onPressed: _openAddIncome,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pridėti'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (_incomes.isEmpty)
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
                    'Nėra pajamų',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: text, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pridėk savo pirmą pajamą',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtext),
                  ),
                ],
              ),
            )
          else
            ..._incomes.map((income) {
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
                    backgroundColor: AppPalette.accentPurple.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.attach_money_rounded,
                      color: AppPalette.accentPurple,
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
                      Text(
                      income.note,
                      style: TextStyle(color: subtext),
                      ),
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
      ),
    );
  }
}