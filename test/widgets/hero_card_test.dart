import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/hero_card.dart';
import 'package:flutter_application_1/models/hero.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  app.HeroAppearance createTestAppearance() {
    return const app.HeroAppearance(
      baseAvatar: 'avatar_1',
      skinColor: 'light',
      hairStyle: 'short',
      hairColor: 'brown',
      outfit: 'casual',
    );
  }

  app.Hero createTestHero({
    String name = 'TestHero',
    int level = 5,
    int currentXP = 50,
    int xpToNextLevel = 300,
    int currentStreak = 0,
    int longestStreak = 0,
  }) {
    return app.Hero(
      id: 'hero-1',
      userId: 'user-1',
      name: name,
      level: level,
      currentXP: currentXP,
      xpToNextLevel: xpToNextLevel,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      appearance: createTestAppearance(),
    );
  }

  Widget createTestWidget(app.Hero hero, {bool compact = false}) {
    return MaterialApp(
      home: Scaffold(
        body: HeroCard(
          hero: hero,
          compact: compact,
        ),
      ),
    );
  }

  group('HeroCard', () {
    group('Full Card Rendering', () {
      testWidgets('renders hero name', (WidgetTester tester) async {
        final hero = createTestHero(name: 'Emma');

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('Emma'), findsOneWidget);
      });

      testWidgets('renders level badge', (WidgetTester tester) async {
        final hero = createTestHero(level: 12);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('Level 12'), findsOneWidget);
      });

      testWidgets('renders XP values', (WidgetTester tester) async {
        final hero = createTestHero(currentXP: 150, xpToNextLevel: 300);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('150 / 300'), findsOneWidget);
      });

      testWidgets('renders XP label', (WidgetTester tester) async {
        final hero = createTestHero();

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('XP'), findsOneWidget);
      });

      testWidgets('renders avatar initial', (WidgetTester tester) async {
        final hero = createTestHero(name: 'Emma');

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('E'), findsOneWidget);
      });
    });

    group('Level Titles', () {
      testWidgets('shows Mochi Novice for level 1-10', (WidgetTester tester) async {
        final hero = createTestHero(level: 5);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('Mochi Novice'), findsOneWidget);
      });

      testWidgets('shows Mochi Apprentice for level 11-25', (WidgetTester tester) async {
        final hero = createTestHero(level: 15);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('Mochi Apprentice'), findsOneWidget);
      });

      testWidgets('shows Mochi Champion for level 26-50', (WidgetTester tester) async {
        final hero = createTestHero(level: 35);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('Mochi Champion'), findsOneWidget);
      });

      testWidgets('shows Mochi Legend for level 51+', (WidgetTester tester) async {
        final hero = createTestHero(level: 55);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('Mochi Legend'), findsOneWidget);
      });
    });

    group('Streak Display', () {
      testWidgets('shows streak when > 0', (WidgetTester tester) async {
        final hero = createTestHero(currentStreak: 7);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('7 Tage'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });

      testWidgets('does not show streak when 0', (WidgetTester tester) async {
        final hero = createTestHero(currentStreak: 0);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('0 Tage'), findsNothing);
      });

      testWidgets('shows best streak when current < longest', (WidgetTester tester) async {
        final hero = createTestHero(currentStreak: 5, longestStreak: 14);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('Best: 14'), findsOneWidget);
      });

      testWidgets('does not show best streak when current >= longest', (WidgetTester tester) async {
        final hero = createTestHero(currentStreak: 14, longestStreak: 14);

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.text('Best: 14'), findsNothing);
      });
    });

    group('Compact Mode', () {
      testWidgets('renders hero name in compact mode', (WidgetTester tester) async {
        final hero = createTestHero(name: 'Emma');

        await tester.pumpWidget(createTestWidget(hero, compact: true));

        expect(find.text('Emma'), findsOneWidget);
      });

      testWidgets('shows abbreviated level in compact mode', (WidgetTester tester) async {
        final hero = createTestHero(level: 12);

        await tester.pumpWidget(createTestWidget(hero, compact: true));

        expect(find.textContaining('Lvl 12'), findsOneWidget);
      });

      testWidgets('does not show XP bar in compact mode', (WidgetTester tester) async {
        final hero = createTestHero();

        await tester.pumpWidget(createTestWidget(hero, compact: true));

        expect(find.text('XP'), findsNothing);
      });

      testWidgets('shows streak badge in compact mode', (WidgetTester tester) async {
        final hero = createTestHero(currentStreak: 5);

        await tester.pumpWidget(createTestWidget(hero, compact: true));

        expect(find.text('5'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('calls onTap when tapped', (WidgetTester tester) async {
        var tapped = false;
        final hero = createTestHero();

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: HeroCard(
              hero: hero,
              onTap: () => tapped = true,
            ),
          ),
        ));

        await tester.tap(find.byType(HeroCard));
        await tester.pumpAndSettle();

        expect(tapped, true);
      });
    });

    group('Avatar Appearance', () {
      testWidgets('renders avatar for different skin colors', (WidgetTester tester) async {
        final hero = createTestHero(name: 'Test');

        await tester.pumpWidget(createTestWidget(hero));

        // Avatar should render with initial
        expect(find.text('T'), findsOneWidget);
      });

      testWidgets('handles empty name gracefully', (WidgetTester tester) async {
        final hero = app.Hero(
          id: 'hero-1',
          userId: 'user-1',
          name: '',
          xpToNextLevel: 100,
          appearance: createTestAppearance(),
        );

        await tester.pumpWidget(createTestWidget(hero));

        // Should show '?' for empty name
        expect(find.text('?'), findsOneWidget);
      });
    });

    group('Visual Elements', () {
      testWidgets('renders GestureDetector for tap handling', (WidgetTester tester) async {
        final hero = createTestHero();

        await tester.pumpWidget(createTestWidget(hero));

        expect(find.byType(GestureDetector), findsOneWidget);
      });

      testWidgets('renders Container with decoration', (WidgetTester tester) async {
        final hero = createTestHero();

        await tester.pumpWidget(createTestWidget(hero));

        // Should have decorated containers
        expect(find.byType(Container), findsWidgets);
      });
    });
  });
}
