import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/providers/quest_provider.dart';
import 'package:flutter_application_1/models/quest.dart';
import 'package:flutter_application_1/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuestProvider provider;

  Quest createTestQuest({
    String id = 'quest-1',
    String name = 'Test Quest',
    QuestType type = QuestType.daily,
    QuestRarity rarity = QuestRarity.common,
    int rewardPoints = 10,
    int rewardXP = 25,
    List<String> assignedTo = const [],
    int? targetCount,
  }) {
    return Quest(
      id: id,
      familyId: 'family-1',
      createdBy: 'parent-1',
      name: name,
      icon: '⭐',
      type: type,
      rarity: rarity,
      rewardPoints: rewardPoints,
      rewardXP: rewardXP,
      assignedTo: assignedTo,
      createdAt: DateTime.now(),
      targetCount: targetCount,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = QuestProvider();
  });

  group('QuestProvider', () {
    group('CRUD Operations', () {
      test('createQuest adds quest to list', () async {
        final quest = createTestQuest();

        final result = await provider.createQuest(quest);

        expect(result, true);
        expect(provider.quests.length, 1);
        expect(provider.quests.first.id, quest.id);
      });

      test('createQuest notifies listeners', () async {
        final quest = createTestQuest();
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.createQuest(quest);

        expect(notified, true);
      });

      test('updateQuest modifies existing quest', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);

        final updatedQuest = quest.copyWith(name: 'Updated Quest');
        final result = await provider.updateQuest(updatedQuest);

        expect(result, true);
        expect(provider.quests.first.name, 'Updated Quest');
      });

      test('updateQuest returns false for non-existent quest', () async {
        final quest = createTestQuest(id: 'non-existent');
        final result = await provider.updateQuest(quest);

        expect(result, false);
      });

      test('deleteQuest removes quest from list', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);

        final result = await provider.deleteQuest(quest.id);

        expect(result, true);
        expect(provider.quests, isEmpty);
      });
    });

    group('Quest Workflow', () {
      const childId = 'child-1';
      const parentId = 'parent-1';

      test('full workflow: create → accept → complete → approve', () async {
        // Track callback
        String? callbackChildId;
        int? callbackPoints;
        int? callbackXP;

        provider.onQuestApproved = ({
          required String childId,
          required int points,
          required int xp,
          required String questId,
          required String questName,
        }) {
          callbackChildId = childId;
          callbackPoints = points;
          callbackXP = xp;
        };

        // 1. Create quest
        final quest = createTestQuest(rewardPoints: 15, rewardXP: 50);
        await provider.createQuest(quest);

        // 2. Accept quest
        final acceptResult = await provider.acceptQuest(quest.id, childId);
        expect(acceptResult, true);

        final activeQuests = provider.activeQuests(childId);
        expect(activeQuests.length, 1);
        expect(activeQuests.first.status, QuestStatus.inProgress);

        // 3. Complete quest
        final instanceId = activeQuests.first.id;
        final completeResult = await provider.completeQuest(instanceId);
        expect(completeResult, true);

        expect(provider.pendingApproval.length, 1);
        expect(provider.pendingApprovalCount, 1);

        // 4. Approve quest
        final approveResult = await provider.approveQuest(instanceId, parentId);
        expect(approveResult, true);

        // Verify callback was called
        expect(callbackChildId, childId);
        expect(callbackPoints, 15);
        expect(callbackXP, 50);

        // Verify quest is completed
        expect(provider.pendingApproval, isEmpty);
      });

      test('acceptQuest creates instance with correct status', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);

        await provider.acceptQuest(quest.id, childId);

        final instances = provider.activeQuests(childId);
        expect(instances.length, 1);
        expect(instances.first.questId, quest.id);
        expect(instances.first.childId, childId);
        expect(instances.first.status, QuestStatus.inProgress);
        expect(instances.first.startedAt, isNotNull);
      });

      test('acceptQuest returns false for non-existent quest', () async {
        final result = await provider.acceptQuest('non-existent', childId);
        expect(result, false);
      });

      test('completeQuest sets status to pendingApproval', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);
        await provider.acceptQuest(quest.id, childId);

        final instanceId = provider.activeQuests(childId).first.id;
        await provider.completeQuest(instanceId);

        final pending = provider.pendingApproval;
        expect(pending.length, 1);
        expect(pending.first.status, QuestStatus.pendingApproval);
        expect(pending.first.completedAt, isNotNull);
      });

      test('approveQuest sets status to completed with approval info', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);
        await provider.acceptQuest(quest.id, childId);

        final instanceId = provider.activeQuests(childId).first.id;
        await provider.completeQuest(instanceId);
        await provider.approveQuest(instanceId, parentId);

        final completed = provider.completedToday(childId);
        expect(completed.length, 1);
        expect(completed.first.status, QuestStatus.completed);
        expect(completed.first.approvedBy, parentId);
        expect(completed.first.approvedAt, isNotNull);
      });

      test('rejectQuest resets instance to inProgress', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);
        await provider.acceptQuest(quest.id, childId);

        final instanceId = provider.activeQuests(childId).first.id;
        await provider.completeQuest(instanceId);

        final rejectResult = await provider.rejectQuest(instanceId);
        expect(rejectResult, true);

        final active = provider.activeQuests(childId);
        expect(active.length, 1);
        expect(active.first.status, QuestStatus.inProgress);
        expect(active.first.progress, 0);
      });
    });

    group('Series Quest Progress', () {
      const childId = 'child-1';

      test('incrementSeriesProgress updates progress', () async {
        final quest = createTestQuest(
          type: QuestType.series,
          targetCount: 10,
        );
        await provider.createQuest(quest);
        await provider.acceptQuest(quest.id, childId);

        final instanceId = provider.activeQuests(childId).first.id;

        await provider.incrementSeriesProgress(instanceId, 3);
        expect(provider.activeQuests(childId).first.progress, 3);

        await provider.incrementSeriesProgress(instanceId, 2);
        expect(provider.activeQuests(childId).first.progress, 5);
      });
    });

    group('Available Quests Filtering', () {
      const childId = 'child-1';

      test('availableQuests excludes inactive quests', () async {
        final activeQuest = createTestQuest(id: 'active');
        final inactiveQuest = createTestQuest(id: 'inactive').copyWith(isActive: false);

        await provider.createQuest(activeQuest);
        await provider.createQuest(inactiveQuest);

        final available = provider.availableQuests(childId);
        expect(available.length, 1);
        expect(available.first.id, 'active');
      });

      test('availableQuests excludes expired quests', () async {
        final validQuest = createTestQuest(id: 'valid');
        final expiredQuest = createTestQuest(id: 'expired').copyWith(
          deadline: DateTime.now().subtract(const Duration(days: 1)),
        );

        await provider.createQuest(validQuest);
        await provider.createQuest(expiredQuest);

        final available = provider.availableQuests(childId);
        expect(available.length, 1);
        expect(available.first.id, 'valid');
      });

      test('availableQuests excludes quests not assigned to child', () async {
        final assignedQuest = createTestQuest(
          id: 'assigned',
          assignedTo: [childId],
        );
        final unassignedQuest = createTestQuest(
          id: 'unassigned',
          assignedTo: ['other-child'],
        );
        final globalQuest = createTestQuest(id: 'global');

        await provider.createQuest(assignedQuest);
        await provider.createQuest(unassignedQuest);
        await provider.createQuest(globalQuest);

        final available = provider.availableQuests(childId);
        expect(available.length, 2);
        expect(available.map((q) => q.id), containsAll(['assigned', 'global']));
      });

      test('availableQuests excludes quests with active instances', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);
        await provider.acceptQuest(quest.id, childId);

        final available = provider.availableQuests(childId);
        expect(available, isEmpty);
      });
    });

    group('Persistence', () {
      test('quests persist after reload', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);

        // Create new provider and load
        final newProvider = QuestProvider();
        await newProvider.loadQuests();

        expect(newProvider.quests.length, 1);
        expect(newProvider.quests.first.id, quest.id);
      });

      test('instances persist after reload', () async {
        final quest = createTestQuest();
        await provider.createQuest(quest);
        await provider.acceptQuest(quest.id, 'child-1');

        // Create new provider and load
        final newProvider = QuestProvider();
        await newProvider.loadQuests();

        expect(newProvider.activeQuests('child-1').length, 1);
      });
    });

    group('onQuestApproved Callback', () {
      test('callback receives correct parameters', () async {
        String? receivedChildId;
        int? receivedPoints;
        int? receivedXP;
        String? receivedQuestId;
        String? receivedQuestName;

        provider.onQuestApproved = ({
          required String childId,
          required int points,
          required int xp,
          required String questId,
          required String questName,
        }) {
          receivedChildId = childId;
          receivedPoints = points;
          receivedXP = xp;
          receivedQuestId = questId;
          receivedQuestName = questName;
        };

        final quest = createTestQuest(
          id: 'test-quest',
          name: 'Test Quest Name',
          rewardPoints: 20,
          rewardXP: 100,
        );
        await provider.createQuest(quest);
        await provider.acceptQuest(quest.id, 'child-1');

        final instanceId = provider.activeQuests('child-1').first.id;
        await provider.completeQuest(instanceId);
        await provider.approveQuest(instanceId, 'parent-1');

        expect(receivedChildId, 'child-1');
        expect(receivedPoints, 20);
        expect(receivedXP, 100);
        expect(receivedQuestId, 'test-quest');
        expect(receivedQuestName, 'Test Quest Name');
      });

      test('callback calculates XP from points when rewardXP is 0', () async {
        int? receivedXP;

        provider.onQuestApproved = ({
          required String childId,
          required int points,
          required int xp,
          required String questId,
          required String questName,
        }) {
          receivedXP = xp;
        };

        final quest = createTestQuest(rewardPoints: 10, rewardXP: 0);
        await provider.createQuest(quest);
        await provider.acceptQuest(quest.id, 'child-1');

        final instanceId = provider.activeQuests('child-1').first.id;
        await provider.completeQuest(instanceId);
        await provider.approveQuest(instanceId, 'parent-1');

        // XP = points * 10 when rewardXP is 0
        expect(receivedXP, 100);
      });
    });
  });
}
