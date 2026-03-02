import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quest.dart';
import '../models/enums.dart';
import '../providers/quest_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/error_state.dart';

class QuestDetailPage extends StatelessWidget {
  final Quest quest;
  final QuestInstance? instance;

  const QuestDetailPage({
    super.key,
    required this.quest,
    this.instance,
  });

  String _getTypeText() {
    switch (quest.type) {
      case QuestType.daily:
        return 'Täglich';
      case QuestType.weekly:
        return 'Wöchentlich';
      case QuestType.epic:
        return 'Episch';
      case QuestType.series:
        return 'Serie';
    }
  }

  String _getRarityText() {
    switch (quest.rarity) {
      case QuestRarity.common:
        return 'Gewöhnlich';
      case QuestRarity.rare:
        return 'Selten';
      case QuestRarity.epic:
        return 'Episch';
      case QuestRarity.legendary:
        return 'Legendär';
    }
  }

  Future<void> _acceptQuest(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final questProvider = context.read<QuestProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final success = await questProvider.acceptQuest(quest.id, userId);

    if (context.mounted) {
      if (success) {
        AppSnackbar.success(context, 'Quest angenommen!');
        Navigator.of(context).pop();
      } else {
        AppSnackbar.error(context, 'Fehler beim Annehmen der Quest');
      }
    }
  }

  Future<void> _completeQuest(BuildContext context) async {
    final questProvider = context.read<QuestProvider>();

    if (instance == null) return;

    final success = await questProvider.completeQuest(instance!.id);

    if (context.mounted) {
      if (success) {
        AppSnackbar.success(context, 'Quest als erledigt markiert!');
        Navigator.of(context).pop();
      } else {
        AppSnackbar.error(context, 'Fehler beim Markieren der Quest');
      }
    }
  }

  Future<void> _incrementProgress(BuildContext context) async {
    final questProvider = context.read<QuestProvider>();

    if (instance == null) return;

    final success = await questProvider.incrementSeriesProgress(instance!.id, 1);

    if (context.mounted) {
      if (success) {
        AppSnackbar.success(context, 'Fortschritt +1');
      } else {
        AppSnackbar.error(context, 'Fehler beim Update des Fortschritts');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      appBar: AppBar(
        title: const Text('Quest Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    quest.rarityColor,
                    quest.rarityColor.withAlpha(128),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        quest.icon,
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    quest.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: quest.rarityColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getRarityText(),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rarityRare.withAlpha(51),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getTypeText(),
                          style: const TextStyle(
                            color: AppColors.rarityRare,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  if (quest.description != null) ...[
                    const Text(
                      'Beschreibung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quest.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Rewards
                  const Text(
                    'Belohnung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.stars, color: AppColors.gold, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '${quest.rewardPoints} Punkte',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Icon(Icons.trending_up, color: AppColors.rarityRare, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '${quest.rewardXP} XP',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Deadline
                  if (quest.hasDeadline) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: quest.isExpired ? AppColors.error : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          quest.isExpired
                              ? 'Abgelaufen'
                              : 'Frist: ${quest.deadline!.day}.${quest.deadline!.month}.${quest.deadline!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: quest.isExpired ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Streak
                  if (instance != null && instance!.currentStreak > 0) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: AppColors.primaryEnd,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${instance!.currentStreak} Tag${instance!.currentStreak > 1 ? "e" : ""} Streak',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Progress (for series)
                  if (instance != null && quest.isSeries) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Fortschritt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: instance!.progressPercent,
                            backgroundColor: AppColors.textSecondary.withAlpha(77),
                            valueColor: AlwaysStoppedAnimation<Color>(quest.rarityColor),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${instance!.progress}/${instance!.target}${quest.unit != null ? " ${quest.unit}" : ""}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(context),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    if (instance == null) {
      // Available quest
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _acceptQuest(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: quest.rarityColor,
              foregroundColor: AppColors.text,
            ),
            child: const Text(
              'Quest annehmen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    // Check status
    switch (instance!.status) {
      case QuestStatus.inProgress:
        if (quest.isSeries && !instance!.isComplete) {
          // Series quest with +1 button
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _incrementProgress(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '+1',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (instance!.isComplete) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _completeQuest(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.text,
                        ),
                        child: const Text(
                          'Als erledigt markieren',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        } else {
          // Regular quest
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _completeQuest(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.text,
                ),
                child: const Text(
                  'Als erledigt markieren',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }
      case QuestStatus.pendingApproval:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Warte auf Bestätigung',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      case QuestStatus.completed:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Abgeschlossen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
