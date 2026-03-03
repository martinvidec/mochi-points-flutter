import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/error_state.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/pin_dialog.dart';
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

    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    // Check if user has a PIN set
    String? enteredPin;
    final user = authProvider.getUserById(userId);
    if (user != null && user.hasPin) {
      enteredPin = await PinDialog.show(context);
      if (enteredPin == null) {
        // User cancelled — deselect
        if (mounted) setState(() => _selectedUserId = null);
        return;
      }
    }

    final success = await authProvider.login(userId, pin: enteredPin);

    if (!mounted) return;

    if (!success) {
      AppSnackbar.error(context, 'Falscher PIN');
      setState(() => _selectedUserId = null);
      return;
    }

    // Navigate to appropriate dashboard based on role
    final loggedInUser = authProvider.currentUser;
    if (loggedInUser != null) {
      if (loggedInUser.isParent) {
        navigator.pushReplacementNamed('/parent-dashboard');
      } else {
        navigator.pushReplacementNamed('/hero-home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
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
                    AppButton.primary(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/family-setup');
                      },
                      label: 'Familie einrichten',
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
