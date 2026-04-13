import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/step_entry.dart';
import '../services/steps_service.dart';
import '../theme/app_palette.dart';
import 'widgets/add_steps_sheet.dart';
import 'widgets/profile_action_button.dart';

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  final StepsService _stepsService = StepsService();

  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  Future<void> _openEditor({int initialSteps = 0, int initialGoal = 10000}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStepsSheet(
        date: _selectedDay,
        initialSteps: initialSteps,
        initialGoal: initialGoal,
        onSave: (steps, goal) async {
          await _stepsService.setDaySteps(
            uid: _uid,
            day: _selectedDay,
            steps: steps,
            goal: goal,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Žingsniai išsaugoti')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Pirma prisijunk')),
      );
    }

    final background = AppPalette.background(context);
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    final today = _normalize(DateTime.now());
    final selected = _normalize(_selectedDay);
    final monthDays = _daysInMonth(_selectedMonth);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Žingsniai'),
        actions: const [ProfileActionButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Įvesti žingsnius'),
      ),
      body: StreamBuilder<List<StepEntry>>(
        stream: _stepsService.watchMonth(_uid, _selectedMonth),
        builder: (context, monthSnapshot) {
          final monthEntries = monthSnapshot.data ?? [];
          final byId = {for (final e in monthEntries) e.id: e};

          return StreamBuilder<StepEntry?>(
            stream: _stepsService.watchDay(_uid, _selectedDay),
            builder: (context, daySnapshot) {
              final dayEntry = daySnapshot.data;
              final steps = dayEntry?.steps ?? 0;
              final goal = dayEntry?.goal ?? 10000;
              final progress = goal <= 0 ? 0.0 : (steps / goal).clamp(0.0, 1.0);

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
                              _selectedDay = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month,
                                1,
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
                              _selectedDay = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month,
                                1,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calendar days grid
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
                        final d = DateTime(_selectedMonth.year, _selectedMonth.month, index + 1);
                        final id = StepEntry.idFromDate(d);
                        final hasData = byId.containsKey(id);
                        final isToday = _normalize(d) == today;
                        final isSelected = _normalize(d) == selected;

                        Color bg = Colors.transparent;
                        Color fg = text;
                        BorderSide b = BorderSide(color: border);

                        if (isToday) {
                          b = const BorderSide(color: AppPalette.accentPurple, width: 1.5);
                        }
                        if (isSelected) {
                          bg = AppPalette.accentGreen.withOpacity(.18);
                          b = const BorderSide(color: AppPalette.accentGreen, width: 1.5);
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
                                Text('${index + 1}', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: hasData ? AppPalette.accentGreen : Colors.transparent,
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

                  // Selected day details
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
                        const SizedBox(height: 10),
                        Text(
                          '$steps žingsnių',
                          style: TextStyle(
                            color: text,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tikslas: $goal',
                          style: TextStyle(color: subtext),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: progress,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Progresas: ${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: subtext),
                        ),
                        const SizedBox(height: 12),
                        if (steps == 0)
                          Text(
                            'Nėra veiklų',
                            style: TextStyle(
                              color: subtext,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _openEditor(
                            initialSteps: steps,
                            initialGoal: goal,
                          ),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Redaguoti dieną'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}