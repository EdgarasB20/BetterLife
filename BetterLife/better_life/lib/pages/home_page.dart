import 'package:flutter/material.dart';
import '../auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Atsijungti',
          ),
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
                style: const TextStyle(color: Colors.black54),
              ),
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