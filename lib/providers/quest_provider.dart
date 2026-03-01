import 'package:flutter/foundation.dart';
import '../models/quest.dart';
import '../models/enums.dart';
import '../services/storage_service.dart';

/// Callback when a quest is approved with rewards
typedef QuestApprovedCallback = void Function({
  required String childId,
  required int points,
  required int xp,
  required String questId,
  required String questName,
});

class QuestProvider extends ChangeNotifier {
  List<Quest> _quests = [];
  Map<String, List<QuestInstance>> _instances = {};

  List<Quest> get quests => List.unmodifiable(_quests);
  Map<String, List<QuestInstance>> get instances => Map.unmodifiable(_instances);

  static const String _questsKey = 'quests';
  static const String _instancesKey = 'quest_instances';

  /// Callback triggered when a quest is approved (for awarding points/XP)
  QuestApprovedCallback? onQuestApproved;

  // Getters
  List<Quest> availableQuests(String childId) {
    return _quests.where((quest) {
      if (!quest.isActive || quest.isExpired) return false;

      // Check if quest is assigned to this child (empty = all children)
      if (quest.assignedTo.isNotEmpty && !quest.assignedTo.contains(childId)) {
        return false;
      }

      // Check if child already has an active instance
      final childInstances = _instances[childId] ?? [];
      final hasActiveInstance = childInstances.any(
        (instance) =>
            instance.questId == quest.id &&
            (instance.status == QuestStatus.inProgress ||
                instance.status == QuestStatus.pendingApproval),
      );

      return !hasActiveInstance;
    }).toList();
  }

  List<QuestInstance> activeQuests(String childId) {
    final childInstances = _instances[childId] ?? [];
    return childInstances
        .where((instance) => instance.status == QuestStatus.inProgress)
        .toList();
  }

  List<QuestInstance> get pendingApproval {
    final allInstances = <QuestInstance>[];
    for (final instances in _instances.values) {
      allInstances.addAll(
        instances.where((instance) => instance.status == QuestStatus.pendingApproval),
      );
    }
    return allInstances;
  }

  int get pendingApprovalCount => pendingApproval.length;

  List<QuestInstance> completedToday(String childId) {
    final childInstances = _instances[childId] ?? [];
    final today = DateTime.now();
    return childInstances.where((instance) {
      if (instance.status != QuestStatus.completed) return false;
      if (instance.completedAt == null) return false;
      final completedDate = instance.completedAt!;
      return completedDate.year == today.year &&
          completedDate.month == today.month &&
          completedDate.day == today.day;
    }).toList();
  }

  // Load from storage
  Future<void> loadQuests() async {
    try {
      _quests = await StorageService.loadList(_questsKey, Quest.fromJson);

      // Load instances
      final instancesList = await StorageService.loadList(
        _instancesKey,
        QuestInstance.fromJson,
      );

      // Group by childId
      _instances = {};
      for (final instance in instancesList) {
        if (!_instances.containsKey(instance.childId)) {
          _instances[instance.childId] = [];
        }
        _instances[instance.childId]!.add(instance);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('QuestProvider.loadQuests error: $e');
    }
  }

  // CRUD Operations
  Future<bool> createQuest(Quest quest) async {
    try {
      _quests.add(quest);
      await _saveQuests();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QuestProvider.createQuest error: $e');
      return false;
    }
  }

  Future<bool> updateQuest(Quest quest) async {
    try {
      final index = _quests.indexWhere((q) => q.id == quest.id);
      if (index == -1) return false;

      _quests[index] = quest;
      await _saveQuests();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QuestProvider.updateQuest error: $e');
      return false;
    }
  }

  Future<bool> deleteQuest(String questId) async {
    try {
      _quests.removeWhere((q) => q.id == questId);
      await _saveQuests();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QuestProvider.deleteQuest error: $e');
      return false;
    }
  }

  // Quest Workflow
  Future<bool> acceptQuest(String questId, String childId) async {
    try {
      final quest = _quests.where((q) => q.id == questId).firstOrNull;
      if (quest == null) return false;

      final instance = QuestInstance(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        questId: questId,
        childId: childId,
        status: QuestStatus.inProgress,
        target: quest.targetCount ?? 1,
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      if (!_instances.containsKey(childId)) {
        _instances[childId] = [];
      }
      _instances[childId]!.add(instance);

      await _saveInstances();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QuestProvider.acceptQuest error: $e');
      return false;
    }
  }

  Future<bool> completeQuest(String instanceId) async {
    try {
      QuestInstance? instance;
      String? childId;

      for (final entry in _instances.entries) {
        final found = entry.value.where((i) => i.id == instanceId).firstOrNull;
        if (found != null) {
          instance = found;
          childId = entry.key;
          break;
        }
      }

      if (instance == null || childId == null) return false;

      final updatedInstance = instance.copyWith(
        status: QuestStatus.pendingApproval,
        progress: instance.target,
        completedAt: DateTime.now(),
      );

      final index = _instances[childId]!.indexWhere((i) => i.id == instanceId);
      _instances[childId]![index] = updatedInstance;

      await _saveInstances();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QuestProvider.completeQuest error: $e');
      return false;
    }
  }

  Future<bool> approveQuest(String instanceId, String parentId) async {
    try {
      QuestInstance? instance;
      String? childId;

      for (final entry in _instances.entries) {
        final found = entry.value.where((i) => i.id == instanceId).firstOrNull;
        if (found != null) {
          instance = found;
          childId = entry.key;
          break;
        }
      }

      if (instance == null || childId == null) return false;

      // Get the quest for reward amounts
      final quest = _quests.where((q) => q.id == instance!.questId).firstOrNull;
      if (quest == null) return false;

      final updatedInstance = instance.copyWith(
        status: QuestStatus.completed,
        approvedAt: DateTime.now(),
        approvedBy: parentId,
      );

      final index = _instances[childId]!.indexWhere((i) => i.id == instanceId);
      _instances[childId]![index] = updatedInstance;

      await _saveInstances();
      notifyListeners();

      // Trigger callback to award points and XP
      final points = quest.rewardPoints;
      final xp = quest.rewardXP > 0 ? quest.rewardXP : quest.rewardPoints * 10;

      onQuestApproved?.call(
        childId: childId,
        points: points,
        xp: xp,
        questId: quest.id,
        questName: quest.name,
      );

      return true;
    } catch (e) {
      debugPrint('QuestProvider.approveQuest error: $e');
      return false;
    }
  }

  Future<bool> rejectQuest(String instanceId, {String? reason}) async {
    try {
      QuestInstance? instance;
      String? childId;

      for (final entry in _instances.entries) {
        final found = entry.value.where((i) => i.id == instanceId).firstOrNull;
        if (found != null) {
          instance = found;
          childId = entry.key;
          break;
        }
      }

      if (instance == null || childId == null) return false;

      final updatedInstance = instance.copyWith(
        status: QuestStatus.inProgress,
        progress: 0,
      );

      final index = _instances[childId]!.indexWhere((i) => i.id == instanceId);
      _instances[childId]![index] = updatedInstance;

      await _saveInstances();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QuestProvider.rejectQuest error: $e');
      return false;
    }
  }

  Future<bool> incrementSeriesProgress(String instanceId, int amount) async {
    try {
      QuestInstance? instance;
      String? childId;

      for (final entry in _instances.entries) {
        final found = entry.value.where((i) => i.id == instanceId).firstOrNull;
        if (found != null) {
          instance = found;
          childId = entry.key;
          break;
        }
      }

      if (instance == null || childId == null) return false;

      final newProgress = instance.progress + amount;
      final updatedInstance = instance.copyWith(progress: newProgress);

      final index = _instances[childId]!.indexWhere((i) => i.id == instanceId);
      _instances[childId]![index] = updatedInstance;

      await _saveInstances();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QuestProvider.incrementSeriesProgress error: $e');
      return false;
    }
  }

  // Persistence helpers
  Future<void> _saveQuests() async {
    await StorageService.saveList(_questsKey, _quests, (q) => q.toJson());
  }

  Future<void> _saveInstances() async {
    final allInstances = <QuestInstance>[];
    for (final instances in _instances.values) {
      allInstances.addAll(instances);
    }
    await StorageService.saveList(
      _instancesKey,
      allInstances,
      (i) => i.toJson(),
    );
  }
}
