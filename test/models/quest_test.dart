import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/quest.dart';
import 'package:flutter_application_1/models/enums.dart';

void main() {
  group('Quest', () {
    late Quest testQuest;

    setUp(() {
      testQuest = Quest(
        id: 'quest-1',
        familyId: 'family-1',
        createdBy: 'parent-1',
        name: 'Clean Room',
        description: 'Clean your room thoroughly',
        icon: '🧹',
        type: QuestType.daily,
        rarity: QuestRarity.common,
        rewardPoints: 10,
        rewardXP: 25,
        assignedTo: ['child-1', 'child-2'],
        isActive: true,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        targetCount: 1,
        unit: 'times',
      );
    });

    group('JSON Serialization', () {
      test('toJson returns correct map', () {
        final json = testQuest.toJson();

        expect(json['id'], 'quest-1');
        expect(json['familyId'], 'family-1');
        expect(json['createdBy'], 'parent-1');
        expect(json['name'], 'Clean Room');
        expect(json['description'], 'Clean your room thoroughly');
        expect(json['icon'], '🧹');
        expect(json['type'], 'daily');
        expect(json['rarity'], 'common');
        expect(json['rewardPoints'], 10);
        expect(json['rewardXP'], 25);
        expect(json['assignedTo'], ['child-1', 'child-2']);
        expect(json['isActive'], true);
        expect(json['targetCount'], 1);
        expect(json['unit'], 'times');
      });

      test('fromJson creates correct Quest', () {
        final json = testQuest.toJson();
        final restored = Quest.fromJson(json);

        expect(restored.id, testQuest.id);
        expect(restored.familyId, testQuest.familyId);
        expect(restored.name, testQuest.name);
        expect(restored.type, testQuest.type);
        expect(restored.rarity, testQuest.rarity);
        expect(restored.rewardPoints, testQuest.rewardPoints);
        expect(restored.assignedTo, testQuest.assignedTo);
      });

      test('JSON roundtrip preserves all fields', () {
        final json = testQuest.toJson();
        final restored = Quest.fromJson(json);
        final jsonAgain = restored.toJson();

        expect(jsonAgain, json);
      });

      test('handles null optional fields', () {
        final quest = Quest(
          id: 'quest-2',
          familyId: 'family-1',
          createdBy: 'parent-1',
          name: 'Simple Quest',
          icon: '⭐',
          type: QuestType.daily,
          rarity: QuestRarity.common,
          rewardPoints: 5,
          rewardXP: 10,
          createdAt: DateTime(2024, 1, 15),
        );

        final json = quest.toJson();
        expect(json['description'], isNull);
        expect(json['deadline'], isNull);
        expect(json['targetCount'], isNull);
        expect(json['unit'], isNull);

        final restored = Quest.fromJson(json);
        expect(restored.description, isNull);
        expect(restored.deadline, isNull);
      });

      test('handles deadline serialization', () {
        final questWithDeadline = testQuest.copyWith(
          deadline: DateTime(2024, 2, 1, 23, 59),
        );

        final json = questWithDeadline.toJson();
        expect(json['deadline'], isNotNull);

        final restored = Quest.fromJson(json);
        expect(restored.deadline, DateTime(2024, 2, 1, 23, 59));
      });
    });

    group('Computed Properties', () {
      test('isSeries returns true for series type', () {
        final seriesQuest = testQuest.copyWith(type: QuestType.series);
        expect(seriesQuest.isSeries, true);
      });

      test('isSeries returns false for non-series types', () {
        expect(testQuest.isSeries, false);

        final weeklyQuest = testQuest.copyWith(type: QuestType.weekly);
        expect(weeklyQuest.isSeries, false);
      });

      test('hasDeadline returns correct value', () {
        expect(testQuest.hasDeadline, false);

        final questWithDeadline = testQuest.copyWith(
          deadline: DateTime.now().add(const Duration(days: 7)),
        );
        expect(questWithDeadline.hasDeadline, true);
      });

      test('isExpired returns true for past deadline', () {
        final expiredQuest = testQuest.copyWith(
          deadline: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(expiredQuest.isExpired, true);
      });

      test('isExpired returns false for future deadline', () {
        final activeQuest = testQuest.copyWith(
          deadline: DateTime.now().add(const Duration(days: 7)),
        );
        expect(activeQuest.isExpired, false);
      });

      test('isExpired returns false for no deadline', () {
        expect(testQuest.isExpired, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updated = testQuest.copyWith(
          name: 'Updated Name',
          rewardPoints: 20,
        );

        expect(updated.name, 'Updated Name');
        expect(updated.rewardPoints, 20);
        expect(updated.id, testQuest.id);
        expect(updated.type, testQuest.type);
      });

      test('preserves original when no changes', () {
        final copy = testQuest.copyWith();

        expect(copy.id, testQuest.id);
        expect(copy.name, testQuest.name);
        expect(copy.rewardPoints, testQuest.rewardPoints);
      });
    });

    group('Rarity Types', () {
      test('all rarity types serialize correctly', () {
        for (final rarity in QuestRarity.values) {
          final quest = testQuest.copyWith(rarity: rarity);
          final json = quest.toJson();
          final restored = Quest.fromJson(json);
          expect(restored.rarity, rarity);
        }
      });
    });

    group('Quest Types', () {
      test('all quest types serialize correctly', () {
        for (final type in QuestType.values) {
          final quest = testQuest.copyWith(type: type);
          final json = quest.toJson();
          final restored = Quest.fromJson(json);
          expect(restored.type, type);
        }
      });
    });
  });

  group('QuestInstance', () {
    late QuestInstance testInstance;

    setUp(() {
      testInstance = QuestInstance(
        id: 'instance-1',
        questId: 'quest-1',
        childId: 'child-1',
        status: QuestStatus.inProgress,
        progress: 3,
        target: 10,
        currentStreak: 5,
        startedAt: DateTime(2024, 1, 15, 10, 0),
        createdAt: DateTime(2024, 1, 15, 9, 0),
      );
    });

    group('JSON Serialization', () {
      test('toJson returns correct map', () {
        final json = testInstance.toJson();

        expect(json['id'], 'instance-1');
        expect(json['questId'], 'quest-1');
        expect(json['childId'], 'child-1');
        expect(json['status'], 'inProgress');
        expect(json['progress'], 3);
        expect(json['target'], 10);
        expect(json['currentStreak'], 5);
      });

      test('fromJson creates correct QuestInstance', () {
        final json = testInstance.toJson();
        final restored = QuestInstance.fromJson(json);

        expect(restored.id, testInstance.id);
        expect(restored.questId, testInstance.questId);
        expect(restored.status, testInstance.status);
        expect(restored.progress, testInstance.progress);
      });

      test('JSON roundtrip preserves all fields', () {
        final json = testInstance.toJson();
        final restored = QuestInstance.fromJson(json);
        final jsonAgain = restored.toJson();

        expect(jsonAgain, json);
      });

      test('handles completed instance with approval', () {
        final completed = testInstance.copyWith(
          status: QuestStatus.completed,
          completedAt: DateTime(2024, 1, 16, 15, 0),
          approvedAt: DateTime(2024, 1, 16, 18, 0),
          approvedBy: 'parent-1',
        );

        final json = completed.toJson();
        final restored = QuestInstance.fromJson(json);

        expect(restored.status, QuestStatus.completed);
        expect(restored.completedAt, DateTime(2024, 1, 16, 15, 0));
        expect(restored.approvedAt, DateTime(2024, 1, 16, 18, 0));
        expect(restored.approvedBy, 'parent-1');
      });
    });

    group('Computed Properties', () {
      test('progressPercent calculates correctly', () {
        expect(testInstance.progressPercent, 0.3);

        final halfDone = testInstance.copyWith(progress: 5);
        expect(halfDone.progressPercent, 0.5);

        final complete = testInstance.copyWith(progress: 10);
        expect(complete.progressPercent, 1.0);
      });

      test('progressPercent handles zero target', () {
        final zeroTarget = testInstance.copyWith(target: 0);
        expect(zeroTarget.progressPercent, 0);
      });

      test('isComplete returns true when progress >= target', () {
        expect(testInstance.isComplete, false);

        final complete = testInstance.copyWith(progress: 10);
        expect(complete.isComplete, true);

        final overComplete = testInstance.copyWith(progress: 15);
        expect(overComplete.isComplete, true);
      });

      test('isPending returns true for pendingApproval status', () {
        expect(testInstance.isPending, false);

        final pending = testInstance.copyWith(
          status: QuestStatus.pendingApproval,
        );
        expect(pending.isPending, true);
      });
    });

    group('Status Transitions', () {
      test('all status values serialize correctly', () {
        for (final status in QuestStatus.values) {
          final instance = testInstance.copyWith(status: status);
          final json = instance.toJson();
          final restored = QuestInstance.fromJson(json);
          expect(restored.status, status);
        }
      });

      test('status can transition from available to inProgress', () {
        final available = QuestInstance(
          id: 'i-1',
          questId: 'q-1',
          childId: 'c-1',
          status: QuestStatus.available,
          createdAt: DateTime.now(),
        );

        final started = available.copyWith(
          status: QuestStatus.inProgress,
          startedAt: DateTime.now(),
        );

        expect(started.status, QuestStatus.inProgress);
        expect(started.startedAt, isNotNull);
      });

      test('status can transition to pendingApproval', () {
        final inProgress = testInstance.copyWith(
          status: QuestStatus.inProgress,
          progress: 10,
        );

        final pending = inProgress.copyWith(
          status: QuestStatus.pendingApproval,
          completedAt: DateTime.now(),
        );

        expect(pending.status, QuestStatus.pendingApproval);
        expect(pending.completedAt, isNotNull);
      });

      test('status can transition to completed with approval', () {
        final pending = testInstance.copyWith(
          status: QuestStatus.pendingApproval,
          progress: 10,
          completedAt: DateTime.now(),
        );

        final completed = pending.copyWith(
          status: QuestStatus.completed,
          approvedAt: DateTime.now(),
          approvedBy: 'parent-1',
        );

        expect(completed.status, QuestStatus.completed);
        expect(completed.approvedAt, isNotNull);
        expect(completed.approvedBy, 'parent-1');
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updated = testInstance.copyWith(
          progress: 7,
          currentStreak: 6,
        );

        expect(updated.progress, 7);
        expect(updated.currentStreak, 6);
        expect(updated.id, testInstance.id);
        expect(updated.questId, testInstance.questId);
      });
    });
  });
}
