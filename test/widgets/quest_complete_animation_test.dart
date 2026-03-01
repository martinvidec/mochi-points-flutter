import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_application_1/widgets/quest_complete_animation.dart';
import 'package:flutter_application_1/widgets/xp_progress_bar.dart';
import 'package:flutter_application_1/models/quest.dart';
import 'package:flutter_application_1/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Quest createTestQuest({
    String name = 'Test Quest',
    String icon = '⭐',
    QuestRarity rarity = QuestRarity.common,
    int rewardPoints = 10,
    int rewardXP = 25,
  }) {
    return Quest(
      id: 'quest-1',
      familyId: 'family-1',
      createdBy: 'parent-1',
      name: name,
      icon: icon,
      type: QuestType.daily,
      rarity: rarity,
      rewardPoints: rewardPoints,
      rewardXP: rewardXP,
      createdAt: DateTime.now(),
    );
  }

  Widget createTestWidget({
    Quest? quest,
    int earnedPoints = 10,
    int earnedXP = 25,
    int currentXP = 50,
    int xpToNextLevel = 100,
    int currentLevel = 5,
    int? streak,
    VoidCallback? onComplete,
  }) {
    return MaterialApp(
      home: QuestCompleteAnimation(
        quest: quest ?? createTestQuest(),
        earnedPoints: earnedPoints,
        earnedXP: earnedXP,
        currentXP: currentXP,
        xpToNextLevel: xpToNextLevel,
        currentLevel: currentLevel,
        streak: streak,
        onComplete: onComplete ?? () {},
      ),
    );
  }

  // Helper to skip animation and settle all timers
  Future<void> skipAnimationAndSettle(WidgetTester tester) async {
    // Tap to skip animation
    await tester.tap(find.byType(QuestCompleteAnimation));
    await tester.pump();
    // Let confetti and other animations settle
    await tester.pump(const Duration(seconds: 3));
  }

  group('QuestCompleteAnimation', () {
    group('Rendering', () {
      testWidgets('renders without error', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byType(QuestCompleteAnimation), findsOneWidget);
      });

      testWidgets('displays quest complete header', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.text('Quest Abgeschlossen!'), findsOneWidget);
      });

      testWidgets('displays quest name', (WidgetTester tester) async {
        final quest = createTestQuest(name: 'Clean Room');
        await tester.pumpWidget(createTestWidget(quest: quest));
        await skipAnimationAndSettle(tester);

        expect(find.text('Clean Room'), findsOneWidget);
      });

      testWidgets('displays quest icon', (WidgetTester tester) async {
        final quest = createTestQuest(icon: '🧹');
        await tester.pumpWidget(createTestWidget(quest: quest));
        await skipAnimationAndSettle(tester);

        expect(find.text('🧹'), findsOneWidget);
      });

      testWidgets('displays trophy icons', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byIcon(Icons.emoji_events), findsNWidgets(2));
      });
    });

    group('Points Display', () {
      testWidgets('displays points icon', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(earnedPoints: 15));
        await skipAnimationAndSettle(tester);

        expect(find.byIcon(Icons.stars), findsOneWidget);
      });

      testWidgets('displays Punkte label', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(earnedPoints: 15));
        await skipAnimationAndSettle(tester);

        expect(find.text('Punkte'), findsOneWidget);
      });

      testWidgets('displays earned points after animation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(earnedPoints: 25));
        await skipAnimationAndSettle(tester);

        expect(find.text('+25'), findsOneWidget);
      });
    });

    group('XP Display', () {
      testWidgets('displays XP progress bar', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byType(XpProgressBar), findsOneWidget);
      });

      testWidgets('displays XP icon', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });
    });

    group('Streak Display', () {
      testWidgets('shows streak when provided', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(streak: 5));
        await skipAnimationAndSettle(tester);

        expect(find.text('5 Tage Streak!'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });

      testWidgets('does not show streak when null', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(streak: null));
        await skipAnimationAndSettle(tester);

        expect(find.textContaining('Streak'), findsNothing);
      });

      testWidgets('does not show streak when 0', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(streak: 0));
        await skipAnimationAndSettle(tester);

        expect(find.textContaining('Streak'), findsNothing);
      });
    });

    group('Confetti', () {
      testWidgets('contains confetti widget', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byType(ConfettiWidget), findsOneWidget);
      });
    });

    group('Button', () {
      testWidgets('shows Weiter button after skip', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.text('Weiter'), findsOneWidget);
      });

      testWidgets('calls onComplete when button tapped', (WidgetTester tester) async {
        var completed = false;
        await tester.pumpWidget(createTestWidget(
          onComplete: () => completed = true,
        ));
        await skipAnimationAndSettle(tester);

        // Tap the button
        await tester.tap(find.text('Weiter'));
        await tester.pump();

        expect(completed, true);
      });
    });

    group('Skip Functionality', () {
      testWidgets('tapping skips animation and shows button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 50));

        // Tap to skip
        await tester.tap(find.byType(QuestCompleteAnimation));
        await tester.pump(const Duration(seconds: 3));

        // Button should be visible now
        expect(find.text('Weiter'), findsOneWidget);
      });

      testWidgets('tapping after skip calls onComplete', (WidgetTester tester) async {
        var completed = false;
        await tester.pumpWidget(createTestWidget(
          onComplete: () => completed = true,
        ));
        await skipAnimationAndSettle(tester);

        // Tap to complete
        await tester.tap(find.text('Weiter'));
        await tester.pump();

        expect(completed, true);
      });
    });

    group('Rarity Styling', () {
      testWidgets('renders with common rarity', (WidgetTester tester) async {
        final quest = createTestQuest(rarity: QuestRarity.common);
        await tester.pumpWidget(createTestWidget(quest: quest));
        await skipAnimationAndSettle(tester);

        expect(find.byType(QuestCompleteAnimation), findsOneWidget);
      });

      testWidgets('renders with rare rarity', (WidgetTester tester) async {
        final quest = createTestQuest(rarity: QuestRarity.rare);
        await tester.pumpWidget(createTestWidget(quest: quest));
        await skipAnimationAndSettle(tester);

        expect(find.byType(QuestCompleteAnimation), findsOneWidget);
      });

      testWidgets('renders with epic rarity', (WidgetTester tester) async {
        final quest = createTestQuest(rarity: QuestRarity.epic);
        await tester.pumpWidget(createTestWidget(quest: quest));
        await skipAnimationAndSettle(tester);

        expect(find.byType(QuestCompleteAnimation), findsOneWidget);
      });

      testWidgets('renders with legendary rarity', (WidgetTester tester) async {
        final quest = createTestQuest(rarity: QuestRarity.legendary);
        await tester.pumpWidget(createTestWidget(quest: quest));
        await skipAnimationAndSettle(tester);

        expect(find.byType(QuestCompleteAnimation), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles zero earned points', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(earnedPoints: 0));
        await skipAnimationAndSettle(tester);

        expect(find.text('+0'), findsOneWidget);
      });

      testWidgets('handles zero earned XP', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(earnedXP: 0));
        await skipAnimationAndSettle(tester);

        expect(find.text('+0 XP'), findsOneWidget);
      });

      testWidgets('handles large point values', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(earnedPoints: 9999));
        await skipAnimationAndSettle(tester);

        expect(find.text('+9999'), findsOneWidget);
      });

      testWidgets('handles high streak count', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(streak: 100));
        await skipAnimationAndSettle(tester);

        expect(find.text('100 Tage Streak!'), findsOneWidget);
      });
    });

    group('Visual Elements', () {
      testWidgets('renders GestureDetector for tap handling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byType(GestureDetector), findsWidgets);
      });

      testWidgets('renders Material widget', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byType(Material), findsWidgets);
      });

      testWidgets('renders ElevatedButton for continue', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });
  });
}
