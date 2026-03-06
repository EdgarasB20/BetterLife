import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/theme_controller.dart';

class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final initials = _userInitials(user);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => showProfileSheet(context),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppPalette.accentPurple.withOpacity(.18),
          child: Text(
            initials,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppPalette.accentPurple,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showProfileSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final user = FirebaseAuth.instance.currentUser;
      final surface = AppPalette.surface(sheetContext);
      final border = AppPalette.border(sheetContext);
      final text = AppPalette.primaryText(sheetContext);
      final subtext = AppPalette.secondaryText(sheetContext);

      final name = (user?.displayName ?? '').trim();
      final email = (user?.email ?? '').trim();
      final uid = user?.uid ?? '—';
      final createdAt = user?.metadata.creationTime;
      final lastSignIn = user?.metadata.lastSignInTime;

      return FractionallySizedBox(
        heightFactor: 0.82,
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
                      backgroundColor: AppPalette.accentPurple.withOpacity(.15),
                      child: Text(
                        _userInitials(user),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.accentPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name.isNotEmpty ? name : 'Vartotojas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isNotEmpty ? email : 'El. paštas nenurodytas',
                      style: TextStyle(color: subtext),
                    ),
                    const SizedBox(height: 22),
                    _SectionCard(
                      title: 'Paskyra',
                      children: [
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'El. paštas',
                          value: email.isNotEmpty ? email : '—',
                        ),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'UID',
                          value: _compactUid(uid),
                        ),
                        _InfoRow(
                          icon: Icons.event_available_rounded,
                          label: 'Sukurta',
                          value: createdAt != null
                              ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt)
                              : '—',
                        ),
                        _InfoRow(
                          icon: Icons.login_rounded,
                          label: 'Paskutinis prisijungimas',
                          value: lastSignIn != null
                              ? DateFormat('yyyy-MM-dd HH:mm').format(lastSignIn)
                              : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Nustatymai',
                      children: [
                        AnimatedBuilder(
                          animation: themeController,
                          builder: (_, __) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Išvaizda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: text,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SegmentedButton<ThemeMode>(
                                  segments: const [
                                    ButtonSegment<ThemeMode>(
                                      value: ThemeMode.light,
                                      icon: Icon(Icons.light_mode_rounded),
                                      label: Text('Light'),
                                    ),
                                    ButtonSegment<ThemeMode>(
                                      value: ThemeMode.dark,
                                      icon: Icon(Icons.dark_mode_rounded),
                                      label: Text('Dark'),
                                    ),
                                  ],
                                  selected: {themeController.themeMode},
                                  onSelectionChanged: (selection) {
                                    themeController.setThemeMode(selection.first);
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.resolveWith<Color?>(
                                      (states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return AppPalette.accentGreen.withOpacity(.15);
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          await AuthService().signOut();
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Atsijungti'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: border),
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Uždaryti'),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppPalette.accentGreen.withOpacity(.15),
            child: Icon(icon, size: 18, color: AppPalette.accentGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: subtext),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _compactUid(String uid) {
  if (uid.length <= 12) return uid;
  return '${uid.substring(0, 6)}...${uid.substring(uid.length - 4)}';
}

String _userInitials(User? user) {
  final name = (user?.displayName ?? '').trim();
  if (name.isNotEmpty) {
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  final email = (user?.email ?? '').trim();
  if (email.isNotEmpty) {
    return email.substring(0, 1).toUpperCase();
  }

  return 'U';
}