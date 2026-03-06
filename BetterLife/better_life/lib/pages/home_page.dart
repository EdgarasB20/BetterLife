import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'finances_page.dart';
import 'health_page.dart';
import '../theme/app_palette.dart';
import 'widgets/profile_action_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1; // Start with Home (middle tab)

  final List<Widget> _pages = const [
    FinancesPage(),
    _HomeTab(),
    HealthPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Finances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Health',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;

    final name = (user?.displayName ?? '').trim();
    final email = (user?.email ?? '').trim();

    Future<void> signOut() async {
      await auth.signOut();
      if (context.mounted) {
        // nuvalom route stack, kad neliktų užstrigusių puslapių
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [
          ProfileActionButton(),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.isNotEmpty ? 'Sveikas, $name 👋' : 'Sveikas 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                email.isNotEmpty ? 'Prisijungta: $email' : 'Prisijungta',
                style: TextStyle(color: AppPalette.secondaryText(context)),              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Atsijungti'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}