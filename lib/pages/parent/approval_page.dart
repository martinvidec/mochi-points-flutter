import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/quest.dart';
import '../../widgets/approval_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    await context.read<QuestProvider>().loadQuests();
  }

  Future<void> _approveQuest(QuestInstance instance) async {
    final authProvider = context.read<AuthProvider>();
    final questProvider = context.read<QuestProvider>();
    final parentId = authProvider.currentUser?.id;

    if (parentId == null) return;

    final success = await questProvider.approveQuest(instance.id, parentId);

    if (mounted) {
      if (success) {
        // Find the quest to get reward amounts
        final quest = questProvider.quests
            .where((q) => q.id == instance.questId)
            .firstOrNull;

        AppSnackbar.success(
          context,
          quest != null
              ? 'Quest bestätigt! ${quest.rewardPoints} Punkte + ${quest.rewardXP} XP vergeben'
              : 'Quest bestätigt!',
        );
        _loadQuests();
      } else {
        AppSnackbar.error(context, 'Fehler beim Bestätigen der Quest');
      }
    }
  }

  Future<void> _rejectQuest(QuestInstance instance) async {
    final questProvider = context.read<QuestProvider>();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Quest ablehnen'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Grund (optional)',
              hintText: 'Warum wird die Quest abgelehnt?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Ablehnen'),
            ),
          ],
        );
      },
    );

    if (reason == null) return; // User cancelled

    final success = await questProvider.rejectQuest(
      instance.id,
      reason: reason.isEmpty ? null : reason,
    );

    if (mounted) {
      if (success) {
        AppSnackbar.success(context, 'Quest abgelehnt');
        _loadQuests();
      } else {
        AppSnackbar.error(context, 'Fehler beim Ablehnen der Quest');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final questProvider = context.watch<QuestProvider>();
    final pendingInstances = questProvider.pendingApproval;

    // Group by child
    final Map<String, List<QuestInstance>> groupedByChild = {};
    for (final instance in pendingInstances) {
      if (!groupedByChild.containsKey(instance.childId)) {
        groupedByChild[instance.childId] = [];
      }
      groupedByChild[instance.childId]!.add(instance);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Freigabe'),
      ),
      body: pendingInstances.isEmpty
          ? EmptyState.approvals()
          : RefreshIndicator(
              onRefresh: _loadQuests,
              child: ListView(
                children: groupedByChild.entries.map((entry) {
                  final childId = entry.key;
                  final instances = entry.value;
                  final child = authProvider.familyMembers
                      .where((u) => u.id == childId)
                      .firstOrNull;

                  if (child == null) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          child.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...instances.map((instance) {
                        final quest = questProvider.quests
                            .where((q) => q.id == instance.questId)
                            .firstOrNull;

                        if (quest == null) return const SizedBox.shrink();

                        return ApprovalCard(
                          child: child,
                          quest: quest,
                          instance: instance,
                          onApprove: () => _approveQuest(instance),
                          onReject: () => _rejectQuest(instance),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
