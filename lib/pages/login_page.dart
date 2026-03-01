import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _selectedUserId;

  Future<void> _handleUserTap(BuildContext context, String userId) async {
    setState(() {
      _selectedUserId = userId;
    });

    // TODO: Check if user has PIN and show PIN dialog

    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    final success = await authProvider.login(userId);

    if (success && mounted) {
      // Navigate to appropriate dashboard based on role
      final user = authProvider.currentUser;
      if (user != null) {
        if (user.isParent) {
          navigator.pushReplacementNamed('/parent-dashboard');
        } else {
          navigator.pushReplacementNamed('/hero-home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final members = authProvider.familyMembers;

            if (members.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Keine Familienmitglieder gefunden',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/family-setup');
                      },
                      child: const Text('Familie einrichten'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (authProvider.currentFamily != null) ...[
                    Text(
                      authProvider.currentFamily!.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Wer bist du?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final user = members[index];
                        return UserAvatarButton(
                          user: user,
                          isSelected: _selectedUserId == user.id,
                          onTap: () => _handleUserTap(context, user.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
