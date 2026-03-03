import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reward.dart';
import '../../providers/reward_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_app_bar.dart';
import 'redemption_page.dart';
import 'reward_edit_page.dart';

class RewardManagementPage extends StatelessWidget {
  const RewardManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardProvider = context.watch<RewardProvider>();
    final rewards = rewardProvider.rewards;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: const Text('Belohnungen verwalten'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Pending redemptions banner
          _PendingRedemptionsBanner(),
          // Rewards list
          Expanded(
            child: rewards.isEmpty
                ? EmptyState.rewards(onCreateReward: () => _openRewardEditor(context, null))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      return _RewardManagementCard(reward: reward);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openRewardEditor(BuildContext context, Reward? reward) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardEditPage(reward: reward),
      ),
    );
  }
}

class _RewardManagementCard extends StatelessWidget {
  final Reward reward;

  const _RewardManagementCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(reward.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => _deleteReward(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: InkWell(
          onTap: () => _openEditor(context),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: reward.isActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : AppColors.textSecondary.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    reward.icon,
                    style: TextStyle(
                      fontSize: 24,
                      color: reward.isActive ? null : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: reward.isActive ? null : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.price} Punkte',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (reward.hasLimitedStock) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reward.stock}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Active toggle
              Switch(
                value: reward.isActive,
                onChanged: (value) => _toggleActive(context, value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardEditPage(reward: reward),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, bool value) async {
    final rewardProvider = context.read<RewardProvider>();
    await rewardProvider.updateReward(reward.copyWith(isActive: value));
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Belohnung löschen?'),
        content: Text('Möchtest du "${reward.name}" wirklich löschen?'),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            label: 'Abbrechen',
          ),
          AppButton.destructive(
            onPressed: () => Navigator.pop(context, true),
            label: 'Löschen',
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _deleteReward(BuildContext context) {
    final rewardProvider = context.read<RewardProvider>();
    rewardProvider.deleteReward(reward.id);

    AppSnackbar.success(context, '${reward.name} gelöscht');
  }
}

class _PendingRedemptionsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<RewardProvider>().pendingRedemptions.length;

    if (pendingCount == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RedemptionPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withAlpha(40),
              AppColors.gold.withAlpha(20),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🎁', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Einlösungen warten',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$pendingCount ${pendingCount == 1 ? 'Anfrage' : 'Anfragen'} offen',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
