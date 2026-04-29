import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/calorie_entry.dart';
import '../services/calorie_service.dart';
import '../theme/app_palette.dart';
import 'widgets/add_calorie_sheet.dart';
import 'widgets/profile_action_button.dart';

class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  final CalorieService _calorieService = CalorieService();
  DateTime _selectedDay = DateTime.now();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _openAddSheet() async {
    CalorieEntry? savedEntry;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCalorieSheet(
        initialDate: _selectedDay,
        onSave: (calories, date, note) async {
          final entry = CalorieEntry(
            id: '',
            calories: calories,
            date: date,
            note: note,
          );

          await _calorieService.addEntry(_uid, entry);
          savedEntry = entry;
        },
      ),
    );

    if (!mounted || savedEntry == null) return;

    setState(() => _selectedDay = _normalize(savedEntry!.date));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kalorijų įrašas išsaugotas')),
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

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Kalorijos'),
        actions: const [ProfileActionButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pridėti'),
      ),
      body: StreamBuilder<List<CalorieEntry>>(
        stream: _calorieService.watchDayEntries(_uid, _selectedDay),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          final total = entries.fold<int>(
            0,
            (sum, entry) => sum + entry.calories,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: AppPalette.heroGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dienos suvestinė',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$total kcal',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDay),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDay = _selectedDay.subtract(
                            const Duration(days: 1),
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Pasirinkta diena',
                            style: TextStyle(color: subtext),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy MMMM d').format(_selectedDay),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDay = _selectedDay.add(
                            const Duration(days: 1),
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dienos įrašai',
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (entries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    'Šiai dienai kalorijų įrašų dar nėra.',
                    style: TextStyle(color: subtext),
                  ),
                )
              else
                ...entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppPalette.accentOrange
                                .withOpacity(.16),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppPalette.accentOrange,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.calories} kcal',
                                  style: TextStyle(
                                    color: text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(entry.date),
                                  style: TextStyle(color: subtext),
                                ),
                                if (entry.note.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.note.trim(),
                                    style: TextStyle(color: text),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
