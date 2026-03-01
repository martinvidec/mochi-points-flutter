import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    // Check if family exists
    if (authProvider.currentFamily == null) {
      // No family -> Family Setup
      Navigator.of(context).pushReplacementNamed('/family-setup');
    } else if (authProvider.isLoggedIn) {
      // Family exists and user logged in -> Dashboard
      if (authProvider.isParent) {
        Navigator.of(context).pushReplacementNamed('/parent-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/hero-home');
      }
    } else {
      // Family exists but no user logged in -> Login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
