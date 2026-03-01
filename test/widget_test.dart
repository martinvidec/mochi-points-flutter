import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/providers/quest_provider.dart';
import 'package:flutter_application_1/providers/points_provider.dart';
import 'package:flutter_application_1/providers/challenge_provider.dart';
import 'package:flutter_application_1/providers/reward_provider.dart';
import 'package:flutter_application_1/providers/hero_provider.dart';
import 'package:flutter_application_1/providers/achievement_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => QuestProvider()),
        ChangeNotifierProvider(create: (context) => PointsProvider()),
        ChangeNotifierProvider(create: (context) => ChallengeProvider()),
        ChangeNotifierProvider(create: (context) => RewardProvider()),
        ChangeNotifierProvider(create: (context) => HeroProvider()),
        ChangeNotifierProvider(create: (context) => AchievementProvider()),
      ],
      child: const MochiPointsApp(),
    );
  }

  group('App Startup', () {
    testWidgets('App loads without error', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // App should render
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App has correct title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'Mochi Points');
    });

    testWidgets('App shows splash page initially', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Should show splash page with loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('App uses dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.brightness, Brightness.dark);
    });

    testWidgets('Debug banner is hidden', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, false);
    });
  });

  group('Navigation Routes', () {
    testWidgets('App has required routes defined', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));

      expect(app.routes, isNotNull);
      expect(app.routes!.containsKey('/login'), true);
      expect(app.routes!.containsKey('/hero-home'), true);
      expect(app.routes!.containsKey('/parent-dashboard'), true);
      expect(app.routes!.containsKey('/family-setup'), true);
    });
  });

  group('Provider Setup', () {
    testWidgets('All providers are accessible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Find the context and verify providers
      final BuildContext context = tester.element(find.byType(MaterialApp));

      expect(
        () => Provider.of<AuthProvider>(context, listen: false),
        returnsNormally,
      );
      expect(
        () => Provider.of<QuestProvider>(context, listen: false),
        returnsNormally,
      );
      expect(
        () => Provider.of<PointsProvider>(context, listen: false),
        returnsNormally,
      );
      expect(
        () => Provider.of<HeroProvider>(context, listen: false),
        returnsNormally,
      );
      expect(
        () => Provider.of<RewardProvider>(context, listen: false),
        returnsNormally,
      );
      expect(
        () => Provider.of<AchievementProvider>(context, listen: false),
        returnsNormally,
      );
    });
  });
}
