import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reward.dart';
import '../../providers/reward_provider.dart';
import '../../widgets/error_state.dart';
import 'reward_edit_page.dart';

class RewardManagementPage extends StatelessWidget {
  const RewardManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardProvider = context.watch<RewardProvider>();
    final rewards = rewardProvider.rewards;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belohnungen verwalten'),
        centerTitle: true,
      ),
      body: rewards.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return _RewardManagementCard(reward: reward);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRewardEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Neue Belohnung'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Belohnungen',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle Belohnungen, die deine Kinder\nim Shop kaufen können.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openRewardEditor(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Erste Belohnung erstellen'),
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
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _openEditor(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: reward.isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      reward.icon,
                      style: TextStyle(
                        fontSize: 24,
                        color: reward.isActive ? null : Colors.grey,
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
                          color: reward.isActive ? null : Colors.grey,
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
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (reward.hasLimitedStock) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${reward.stock}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
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
        title: const Text('Belohnung löschen?'),
        content: Text('Möchtest du "${reward.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
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
