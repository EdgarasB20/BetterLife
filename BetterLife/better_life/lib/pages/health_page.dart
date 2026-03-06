import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'widgets/profile_action_button.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        actions: const [
          ProfileActionButton(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Health',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your health here',
              style: TextStyle(color: subtext),
            ),
          ],
        ),
      ),
    );
  }
}