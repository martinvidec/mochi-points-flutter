import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/xp_progress_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    int currentXP = 50,
    int maxXP = 100,
    int level = 5,
    bool animated = true,
    double height = 12,
    bool showLevel = true,
    bool showXpText = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: XpProgressBar(
          currentXP: currentXP,
          maxXP: maxXP,
          level: level,
          animated: animated,
          height: height,
          showLevel: showLevel,
          showXpText: showXpText,
        ),
      ),
    );
  }

  group('XpProgressBar', () {
    group('Rendering', () {
      testWidgets('renders without error', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(XpProgressBar), findsOneWidget);
      });

      testWidgets('shows level badge when showLevel is true', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(level: 10, showLevel: true));

        expect(find.text('Level 10'), findsOneWidget);
      });

      testWidgets('hides level badge when showLevel is false', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(level: 10, showLevel: false));

        expect(find.text('Level 10'), findsNothing);
      });

      testWidgets('shows XP text when showXpText is true', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          currentXP: 75,
          maxXP: 150,
          showXpText: true,
        ));

        expect(find.text('75 / 150'), findsOneWidget);
      });

      testWidgets('hides XP text when showXpText is false', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          currentXP: 75,
          maxXP: 150,
          showXpText: false,
        ));

        expect(find.text('75 / 150'), findsNothing);
      });
    });

    group('Progress Calculation', () {
      testWidgets('shows correct progress at 0%', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          currentXP: 0,
          maxXP: 100,
        ));

        expect(find.text('0 / 100'), findsOneWidget);
      });

      testWidgets('shows correct progress at 50%', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          currentXP: 50,
          maxXP: 100,
        ));

        expect(find.text('50 / 100'), findsOneWidget);
      });

      testWidgets('shows correct progress at 100%', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          currentXP: 100,
          maxXP: 100,
        ));

        expect(find.text('100 / 100'), findsOneWidget);
      });

      testWidgets('handles zero maxXP gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          currentXP: 0,
          maxXP: 0,
        ));

        // Should not crash
        expect(find.byType(XpProgressBar), findsOneWidget);
      });
    });

    group('Visual Structure', () {
      testWidgets('contains ClipRRect for rounded corners', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(ClipRRect), findsWidgets);
      });

      testWidgets('uses Column layout', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('contains Row for header', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showLevel: true, showXpText: true));

        expect(find.byType(Row), findsWidgets);
      });
    });

    group('Animation', () {
      testWidgets('renders when animated is true', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(animated: true));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(XpProgressBar), findsOneWidget);
      });

      testWidgets('renders when animated is false', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(animated: false));

        expect(find.byType(XpProgressBar), findsOneWidget);
      });

      testWidgets('handles XP change animation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(currentXP: 25, maxXP: 100));
        await tester.pump();

        // Update XP
        await tester.pumpWidget(createTestWidget(currentXP: 75, maxXP: 100));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('75 / 100'), findsOneWidget);
      });
    });

    group('Height Configuration', () {
      testWidgets('uses custom height', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(height: 20));

        expect(find.byType(XpProgressBar), findsOneWidget);
      });

      testWidgets('uses default height', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(XpProgressBar), findsOneWidget);
      });
    });

    group('Level Badge Styling', () {
      testWidgets('level badge contains correct text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(level: 15));

        expect(find.text('Level 15'), findsOneWidget);
      });

      testWidgets('level badge has Container for styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showLevel: true));

        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles level 1', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(level: 1));

        expect(find.text('Level 1'), findsOneWidget);
      });

      testWidgets('handles high level', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(level: 100));

        expect(find.text('Level 100'), findsOneWidget);
      });

      testWidgets('handles large XP values', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          currentXP: 99999,
          maxXP: 100000,
        ));

        expect(find.text('99999 / 100000'), findsOneWidget);
      });

      testWidgets('renders all elements together', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          currentXP: 150,
          maxXP: 300,
          level: 12,
          showLevel: true,
          showXpText: true,
        ));

        expect(find.text('Level 12'), findsOneWidget);
        expect(find.text('150 / 300'), findsOneWidget);
      });
    });
  });
}
