import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reward.dart';
import '../../models/enums.dart';
import '../../providers/reward_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/error_state.dart';
import '../../widgets/points_display.dart';
import '../../widgets/reward_card.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  RewardCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final pointsProvider = context.watch<PointsProvider>();
    final rewardProvider = context.watch<RewardProvider>();

    final userId = authProvider.currentUser?.id ?? '';
    final balance = pointsProvider.balance(userId);
    final rewards = _filterByCategory(rewardProvider.availableRewards);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PointsDisplay(
              points: balance,
              variant: PointsDisplayVariant.compact,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildCategoryChip(null, 'Alle'),
                const SizedBox(width: 8),
                _buildCategoryChip(RewardCategory.experience, '🎉 Erlebnisse'),
                const SizedBox(width: 8),
                _buildCategoryChip(RewardCategory.item, '🎁 Sachen'),
                const SizedBox(width: 8),
                _buildCategoryChip(RewardCategory.privilege, '⭐ Privilegien'),
                const SizedBox(width: 8),
                _buildCategoryChip(RewardCategory.custom, '✨ Spezial'),
              ],
            ),
          ),

          // Rewards grid
          Expanded(
            child: rewards.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      return RewardCard(
                        reward: reward,
                        userBalance: balance,
                        onPurchase: () => _showPurchaseDialog(context, reward, userId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(RewardCategory? category, String label) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Belohnungen verfügbar',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deine Eltern können neue Belohnungen erstellen.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  List<Reward> _filterByCategory(List<Reward> rewards) {
    if (_selectedCategory == null) return rewards;
    return rewards.where((r) => r.category == _selectedCategory).toList();
  }

  void _showPurchaseDialog(BuildContext context, Reward reward, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(reward.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reward.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Möchtest du diese Belohnung kaufen?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '${reward.price} Punkte',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => _purchaseReward(context, reward, userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Kaufen'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseReward(BuildContext dialogContext, Reward reward, String userId) async {
    final rewardProvider = dialogContext.read<RewardProvider>();
    Navigator.pop(dialogContext); // Close dialog

    final success = await rewardProvider.purchaseReward(reward.id, userId);

    if (!mounted) return;

    if (success) {
      _showSuccessSnackbar(reward);
    } else {
      _showErrorSnackbar();
    }
  }

  void _showSuccessSnackbar(Reward reward) {
    AppSnackbar.success(context, '${reward.name} gekauft!');
  }

  void _showErrorSnackbar() {
    AppSnackbar.error(context, 'Kauf fehlgeschlagen. Nicht genug Punkte?');
  }
}
