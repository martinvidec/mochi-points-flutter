import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HeroHomePage extends StatelessWidget {
  const HeroHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mochi Hero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Text(
                  'Willkommen, ${authProvider.currentUser?.name ?? "Hero"}!',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Child Dashboard - Coming Soon'),
            const SizedBox(height: 16),
            const Text('Features:'),
            const Text('• Quest Board'),
            const Text('• Hero Card'),
            const Text('• Rewards Shop'),
            const Text('• Achievements'),
          ],
        ),
      ),
    );
  }
}
