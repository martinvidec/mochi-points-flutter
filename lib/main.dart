import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/quest_provider.dart';
import 'providers/points_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/eaty_provider.dart';
import 'providers/cart_item_provider.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/hero_home_page.dart';
import 'pages/parent_dashboard_page.dart';
import 'pages/setup/family_setup_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => QuestProvider()),
        ChangeNotifierProvider(create: (context) => PointsProvider()),
        ChangeNotifierProvider(create: (context) => ChallengeProvider()),
        ChangeNotifierProvider(create: (context) => EatyProvider()),
        ChangeNotifierProvider(create: (context) => CartItemProvider()),
      ],
      child: const MochiPointsApp(),
    ),
  );
}

class MochiPointsApp extends StatelessWidget {
  const MochiPointsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mochi Points',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7E7E), // Sakura pink
          primary: const Color(0xFFFF7E7E), // Sakura pink
          secondary: const Color(0xFFFFD23F), // Yuzu yellow
          tertiary: const Color(0xFF7EAE4E), // Matcha green
          surface: const Color(0xFFFFF3E0), // Light cream
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/family-setup': (context) => const FamilySetupPage(),
        '/hero-home': (context) => const HeroHomePage(),
        '/parent-dashboard': (context) => const ParentDashboardPage(),
      },
    );
  }
}
