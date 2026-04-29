import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'calories_page.dart';
import 'habit_tracker_page.dart' as habit_tracker;
import 'steps_page.dart';
import 'widgets/profile_action_button.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Prisijunk, kad matytum savo sveikatos duomenis.'),
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
        title: const Text('Health'),
        actions: const [
          ProfileActionButton(),
        ],
      ),
      body: ListView(
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
                  'Sveikatos suvestinė',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sek savo žingsnius\nir mitybą',
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
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CaloriesPage(),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppPalette.accentOrange.withOpacity(.15),
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
                            'Kalorijos',
                            style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dienos įrašai ir bendra kalorijų suma',
                            style: TextStyle(color: subtext),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: subtext),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const habit_tracker.HealthPage(),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppPalette.accentTeal.withOpacity(.15),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: AppPalette.accentTeal,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Įpročiai',
                            style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sek ir kurk naujus įpročius',
                            style: TextStyle(color: subtext),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: subtext),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StepsPage(),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppPalette.accentTeal.withOpacity(.15),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        color: AppPalette.accentTeal,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Žingsniai',
                            style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kalendorius, dienos žingsniai ir progresas',
                            style: TextStyle(color: subtext),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: subtext),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
