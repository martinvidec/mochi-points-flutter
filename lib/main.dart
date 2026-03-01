import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/mochi_point_account_provider.dart';
import 'providers/mochi_point_provider.dart';
import 'providers/eaty_provider.dart';
import 'providers/cart_item_provider.dart';
import 'pages/summary_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChallengeProvider()),
        ChangeNotifierProvider(create: (context) => MochiPointAccountProvider()),
        ChangeNotifierProvider(create: (context) => MochiPointProvider()),
        ChangeNotifierProvider(create: (context) => EatyProvider()),
        ChangeNotifierProvider(create: (context) => CartItemProvider()),
      ],
      child: MochiPointsApp(),
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
          seedColor: Color(0xFFFF7E7E), // Sakura pink
          primary: Color(0xFFFF7E7E), // Sakura pink
          secondary: Color(0xFFFFD23F), // Yuzu yellow
          tertiary: Color(0xFF7EAE4E), // Matcha green
          surface: Color(0xFFFFF3E0), // Light cream
        ),
        useMaterial3: true,
      ),
      home: SummaryPage(),
    );
  }
}
