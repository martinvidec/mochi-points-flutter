import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_application_1/widgets/level_up_animation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    int oldLevel = 5,
    int newLevel = 6,
    List<String>? unlockedRewards,
    VoidCallback? onComplete,
  }) {
    return MaterialApp(
      home: LevelUpAnimation(
        oldLevel: oldLevel,
        newLevel: newLevel,
        unlockedRewards: unlockedRewards,
        onComplete: onComplete ?? () {},
      ),
    );
  }

  // Helper to skip animation and settle all timers
  Future<void> skipAnimationAndSettle(WidgetTester tester) async {
    // Tap to skip animation
    await tester.tap(find.byType(LevelUpAnimation));
    await tester.pump();
    // Let confetti and other animations settle
    await tester.pump(const Duration(seconds: 4));
  }

  group('LevelUpAnimation', () {
    group('Rendering', () {
      testWidgets('renders without error', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byType(LevelUpAnimation), findsOneWidget);
      });

      testWidgets('displays LEVEL UP! text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.text('LEVEL UP!'), findsOneWidget);
      });

      testWidgets('displays level numbers during animation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 10, newLevel: 11));
        await skipAnimationAndSettle(tester);
        // After animation completes, both old and new level should be visible
        // (old faded out but still in widget tree)
        expect(find.text('10'), findsOneWidget);
        expect(find.text('11'), findsOneWidget);
      });

      testWidgets('displays new level after animation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 10, newLevel: 11));
        await skipAnimationAndSettle(tester);

        expect(find.text('11'), findsOneWidget);
      });

      testWidgets('displays arrow icon', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await skipAnimationAndSettle(tester);

        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });
    });

    group('Title Changes', () {
      testWidgets('shows new title when crossing tier boundary (1-10 to 11)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 10, newLevel: 11));
        await skipAnimationAndSettle(tester);

        expect(find.text('Neuer Titel freigeschaltet!'), findsOneWidget);
        expect(find.text('Mochi Apprentice'), findsOneWidget);
      });

      testWidgets('shows new title when crossing tier boundary (25 to 26)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 25, newLevel: 26));
        await skipAnimationAndSettle(tester);

        expect(find.text('Neuer Titel freigeschaltet!'), findsOneWidget);
        expect(find.text('Mochi Champion'), findsOneWidget);
      });

      testWidgets('shows new title when crossing tier boundary (50 to 51)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 50, newLevel: 51));
        await skipAnimationAndSettle(tester);

        expect(find.text('Neuer Titel freigeschaltet!'), findsOneWidget);
        expect(find.text('Mochi Legend'), findsOneWidget);
      });

      testWidgets('does not show title change within same tier', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 5, newLevel: 6));
        await skipAnimationAndSettle(tester);

        expect(find.text('Neuer Titel freigeschaltet!'), findsNothing);
      });

      testWidgets('shows military tech icon with new title', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 10, newLevel: 11));
        await skipAnimationAndSettle(tester);

        expect(find.byIcon(Icons.military_tech), findsOneWidget);
      });
    });

    group('Rewards Preview', () {
      testWidgets('shows rewards when provided', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          unlockedRewards: ['New Avatar', 'Special Badge'],
        ));
        await skipAnimationAndSettle(tester);

        expect(find.text('Freigeschaltet'), findsOneWidget);
        expect(find.text('New Avatar'), findsOneWidget);
        expect(find.text('Special Badge'), findsOneWidget);
      });

      testWidgets('shows check icons for rewards', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          unlockedRewards: ['Reward 1', 'Reward 2'],
        ));
        await skipAnimationAndSettle(tester);

        expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      });

      testWidgets('shows gift icon for rewards section', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          unlockedRewards: ['Reward 1'],
        ));
        await skipAnimationAndSettle(tester);

        expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      });

      testWidgets('does not show rewards section when empty', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(unlockedRewards: null));
        await skipAnimationAndSettle(tester);

        expect(find.text('Freigeschaltet'), findsNothing);
      });

      testWidgets('does not show rewards section when list is empty', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(unlockedRewards: []));
        await skipAnimationAndSettle(tester);

        expect(find.text('Freigeschaltet'), findsNothing);
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
        await tester.tap(find.byType(LevelUpAnimation));
        await tester.pump(const Duration(seconds: 4));

        // Button should be visible now
        expect(find.text('Weiter'), findsOneWidget);
      });

      testWidgets('tapping after skip calls onComplete', (WidgetTester tester) async {
        var completed = false;
        await tester.pumpWidget(createTestWidget(
          onComplete: () => completed = true,
        ));
        await skipAnimationAndSettle(tester);

        await tester.tap(find.text('Weiter'));
        await tester.pump();

        expect(completed, true);
      });
    });

    group('Level Colors', () {
      testWidgets('renders with Novice tier colors (level 1-10)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 1, newLevel: 2));
        await skipAnimationAndSettle(tester);

        expect(find.byType(LevelUpAnimation), findsOneWidget);
      });

      testWidgets('renders with Apprentice tier colors (level 11-25)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 14, newLevel: 15));
        await skipAnimationAndSettle(tester);

        expect(find.byType(LevelUpAnimation), findsOneWidget);
      });

      testWidgets('renders with Champion tier colors (level 26-50)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 30, newLevel: 31));
        await skipAnimationAndSettle(tester);

        expect(find.byType(LevelUpAnimation), findsOneWidget);
      });

      testWidgets('renders with Legend tier colors (level 51+)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 55, newLevel: 56));
        await skipAnimationAndSettle(tester);

        expect(find.byType(LevelUpAnimation), findsOneWidget);
      });
    });

    group('Multi-Level Ups', () {
      testWidgets('handles multiple level ups at once', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 1, newLevel: 5));
        await skipAnimationAndSettle(tester);

        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('handles level up crossing multiple tiers', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 9, newLevel: 26));
        await skipAnimationAndSettle(tester);

        // Should show new title for highest tier reached
        expect(find.text('Mochi Champion'), findsOneWidget);
        expect(find.text('26'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles level 1 to 2', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 1, newLevel: 2));
        await skipAnimationAndSettle(tester);

        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('handles high level values', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(oldLevel: 99, newLevel: 100));
        await skipAnimationAndSettle(tester);

        expect(find.text('100'), findsOneWidget);
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
