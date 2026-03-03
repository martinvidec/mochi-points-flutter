import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../models/enums.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class QuestCard extends StatelessWidget {
  final Quest quest;
  final QuestInstance? instance;
  final VoidCallback onTap;

  const QuestCard({
    super.key,
    required this.quest,
    this.instance,
    required this.onTap,
  });

  String _getStatusText() {
    if (instance == null) return 'Verfügbar';
    switch (instance!.status) {
      case QuestStatus.available:
        return 'Verfügbar';
      case QuestStatus.inProgress:
        return 'In Bearbeitung';
      case QuestStatus.pendingApproval:
        return 'Wartet auf Freigabe';
      case QuestStatus.completed:
        return 'Abgeschlossen';
      case QuestStatus.expired:
        return 'Abgelaufen';
    }
  }

  Color _getStatusColor() {
    if (instance == null) return AppColors.rarityRare;
    switch (instance!.status) {
      case QuestStatus.available:
        return AppColors.rarityRare;
      case QuestStatus.inProgress:
        return AppColors.warning;
      case QuestStatus.pendingApproval:
        return AppColors.rarityEpic;
      case QuestStatus.completed:
        return AppColors.success;
      case QuestStatus.expired:
        return AppColors.textSecondary;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: quest.rarityColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        quest.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Rarity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: quest.rarityColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRarityText(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
              if (quest.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  quest.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Points and XP
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quest.rewardPoints} Punkte',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.rarityRare,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quest.rewardXP} XP',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (instance != null && instance!.currentStreak > 0) ...[
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${instance!.currentStreak} Streak',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              // Progress bar for series quests or in-progress instances
              if (instance != null && quest.isSeries) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fortschritt',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${instance!.progress}/${instance!.target}${quest.unit != null ? " ${quest.unit}" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: instance!.progressPercent,
                      backgroundColor: AppColors.textSecondary.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation<Color>(quest.rarityColor),
                    ),
                  ],
                ),
              ],
            ],
        ),
      ),
    );
  }
}

