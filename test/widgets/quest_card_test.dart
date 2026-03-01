import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/quest_card.dart';
import 'package:flutter_application_1/models/quest.dart';
import 'package:flutter_application_1/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Quest createTestQuest({
    String id = 'quest-1',
    String name = 'Test Quest',
    String? description,
    String icon = '⭐',
    QuestType type = QuestType.daily,
    QuestRarity rarity = QuestRarity.common,
    int rewardPoints = 10,
    int rewardXP = 25,
    String? unit,
  }) {
    return Quest(
      id: id,
      familyId: 'family-1',
      createdBy: 'parent-1',
      name: name,
      description: description,
      icon: icon,
      type: type,
      rarity: rarity,
      rewardPoints: rewardPoints,
      rewardXP: rewardXP,
      createdAt: DateTime.now(),
      targetCount: type == QuestType.series ? 10 : null,
      unit: unit,
    );
  }

  QuestInstance createTestInstance({
    String questId = 'quest-1',
    QuestStatus status = QuestStatus.inProgress,
    int progress = 0,
    int target = 1,
    int currentStreak = 0,
  }) {
    return QuestInstance(
      id: 'instance-1',
      questId: questId,
      childId: 'child-1',
      status: status,
      progress: progress,
      target: target,
      currentStreak: currentStreak,
      createdAt: DateTime.now(),
    );
  }

  Widget createTestWidget(Quest quest, {QuestInstance? instance}) {
    return MaterialApp(
      home: Scaffold(
        body: QuestCard(
          quest: quest,
          instance: instance,
          onTap: () {},
        ),
      ),
    );
  }

  group('QuestCard', () {
    group('Rendering', () {
      testWidgets('renders quest name', (WidgetTester tester) async {
        final quest = createTestQuest(name: 'Clean Room');

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('Clean Room'), findsOneWidget);
      });

      testWidgets('renders quest icon', (WidgetTester tester) async {
        final quest = createTestQuest(icon: '🧹');

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('🧹'), findsOneWidget);
      });

      testWidgets('renders reward points', (WidgetTester tester) async {
        final quest = createTestQuest(rewardPoints: 15);

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('15 Punkte'), findsOneWidget);
      });

      testWidgets('renders reward XP', (WidgetTester tester) async {
        final quest = createTestQuest(rewardXP: 50);

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('50 XP'), findsOneWidget);
      });

      testWidgets('renders description when provided', (WidgetTester tester) async {
        final quest = createTestQuest(description: 'Clean your room thoroughly');

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('Clean your room thoroughly'), findsOneWidget);
      });

      testWidgets('does not render description when null', (WidgetTester tester) async {
        final quest = createTestQuest(description: null);

        await tester.pumpWidget(createTestWidget(quest));

        // Only the quest name should be visible, no description
        expect(find.text('Test Quest'), findsOneWidget);
      });
    });

    group('Rarity Display', () {
      testWidgets('shows "Gewöhnlich" for common rarity', (WidgetTester tester) async {
        final quest = createTestQuest(rarity: QuestRarity.common);

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('Gewöhnlich'), findsOneWidget);
      });

      testWidgets('shows "Selten" for rare rarity', (WidgetTester tester) async {
        final quest = createTestQuest(rarity: QuestRarity.rare);

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('Selten'), findsOneWidget);
      });

      testWidgets('shows "Episch" for epic rarity', (WidgetTester tester) async {
        final quest = createTestQuest(rarity: QuestRarity.epic);

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('Episch'), findsOneWidget);
      });

      testWidgets('shows "Legendär" for legendary rarity', (WidgetTester tester) async {
        final quest = createTestQuest(rarity: QuestRarity.legendary);

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.text('Legendär'), findsOneWidget);
      });
    });

    group('Status Display', () {
      testWidgets('shows "Verfügbar" when no instance', (WidgetTester tester) async {
        final quest = createTestQuest();

        await tester.pumpWidget(createTestWidget(quest, instance: null));

        expect(find.text('Verfügbar'), findsOneWidget);
      });

      testWidgets('shows "In Bearbeitung" for inProgress status', (WidgetTester tester) async {
        final quest = createTestQuest();
        final instance = createTestInstance(status: QuestStatus.inProgress);

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.text('In Bearbeitung'), findsOneWidget);
      });

      testWidgets('shows "Wartet auf Freigabe" for pendingApproval', (WidgetTester tester) async {
        final quest = createTestQuest();
        final instance = createTestInstance(status: QuestStatus.pendingApproval);

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.text('Wartet auf Freigabe'), findsOneWidget);
      });

      testWidgets('shows "Abgeschlossen" for completed status', (WidgetTester tester) async {
        final quest = createTestQuest();
        final instance = createTestInstance(status: QuestStatus.completed);

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.text('Abgeschlossen'), findsOneWidget);
      });

      testWidgets('shows "Abgelaufen" for expired status', (WidgetTester tester) async {
        final quest = createTestQuest();
        final instance = createTestInstance(status: QuestStatus.expired);

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.text('Abgelaufen'), findsOneWidget);
      });
    });

    group('Streak Display', () {
      testWidgets('shows streak when > 0', (WidgetTester tester) async {
        final quest = createTestQuest();
        final instance = createTestInstance(currentStreak: 5);

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.text('5 Streak'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });

      testWidgets('does not show streak when 0', (WidgetTester tester) async {
        final quest = createTestQuest();
        final instance = createTestInstance(currentStreak: 0);

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.text('0 Streak'), findsNothing);
      });
    });

    group('Series Quest Progress', () {
      testWidgets('shows progress bar for series quest', (WidgetTester tester) async {
        final quest = createTestQuest(type: QuestType.series);
        final instance = createTestInstance(
          status: QuestStatus.inProgress,
          progress: 5,
          target: 10,
        );

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Fortschritt'), findsOneWidget);
        expect(find.text('5/10'), findsOneWidget);
      });

      testWidgets('shows progress with unit', (WidgetTester tester) async {
        final quest = createTestQuest(type: QuestType.series, unit: 'Seiten');
        final instance = createTestInstance(
          status: QuestStatus.inProgress,
          progress: 3,
          target: 10,
        );

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.text('3/10 Seiten'), findsOneWidget);
      });

      testWidgets('does not show progress for non-series quest', (WidgetTester tester) async {
        final quest = createTestQuest(type: QuestType.daily);
        final instance = createTestInstance(status: QuestStatus.inProgress);

        await tester.pumpWidget(createTestWidget(quest, instance: instance));

        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text('Fortschritt'), findsNothing);
      });
    });

    group('Interaction', () {
      testWidgets('calls onTap when tapped', (WidgetTester tester) async {
        var tapped = false;
        final quest = createTestQuest();

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: QuestCard(
              quest: quest,
              onTap: () => tapped = true,
            ),
          ),
        ));

        await tester.tap(find.byType(QuestCard));
        await tester.pumpAndSettle();

        expect(tapped, true);
      });

      testWidgets('renders inside a Card widget', (WidgetTester tester) async {
        final quest = createTestQuest();

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('has InkWell for tap feedback', (WidgetTester tester) async {
        final quest = createTestQuest();

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.byType(InkWell), findsOneWidget);
      });
    });

    group('Icons', () {
      testWidgets('shows stars icon for points', (WidgetTester tester) async {
        final quest = createTestQuest();

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.byIcon(Icons.stars), findsOneWidget);
      });

      testWidgets('shows trending_up icon for XP', (WidgetTester tester) async {
        final quest = createTestQuest();

        await tester.pumpWidget(createTestWidget(quest));

        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });
    });
  });
}
