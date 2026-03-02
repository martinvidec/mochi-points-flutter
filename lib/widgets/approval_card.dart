import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

class ApprovalCard extends StatelessWidget {
  final User child;
  final Quest quest;
  final QuestInstance instance;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ApprovalCard({
    super.key,
    required this.child,
    required this.quest,
    required this.instance,
    required this.onApprove,
    required this.onReject,
  });

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.success.withAlpha(102),
                  child: Text(
                    child.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (instance.completedAt != null)
                        Text(
                          'Abgeschlossen: ${_formatDate(instance.completedAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quest info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: quest.rarityColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(quest.icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.stars, size: 16, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text('${quest.rewardPoints} Punkte'),
                          const SizedBox(width: 12),
                          Icon(Icons.trending_up, size: 16, color: AppColors.rarityRare),
                          const SizedBox(width: 4),
                          Text('${quest.rewardXP} XP'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                AppButton.destructive(
                  onPressed: onReject,
                  label: 'Ablehnen',
                  icon: Icons.close,
                  expanded: true,
                ),
                const SizedBox(width: 8),
                AppButton.primary(
                  onPressed: onApprove,
                  label: 'Bestätigen',
                  icon: Icons.check,
                  expanded: true,
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.text,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
