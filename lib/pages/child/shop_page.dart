import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reward.dart';
import '../../models/enums.dart';
import '../../providers/reward_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/points_display.dart';
import '../../widgets/reward_card.dart';
import '../../widgets/glass_app_bar.dart';

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
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
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
                _buildCategoryChip(RewardCategory.experience, 'Erlebnisse', Icons.celebration),
                const SizedBox(width: 8),
                _buildCategoryChip(RewardCategory.item, 'Sachen', Icons.card_giftcard),
                const SizedBox(width: 8),
                _buildCategoryChip(RewardCategory.privilege, 'Privilegien', Icons.star),
                const SizedBox(width: 8),
                _buildCategoryChip(RewardCategory.custom, 'Spezial', Icons.auto_awesome),
              ],
            ),
          ),

          // Rewards grid
          Expanded(
            child: rewards.isEmpty
                ? EmptyState.rewards()
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

  Widget _buildCategoryChip(RewardCategory? category, String label, [IconData? icon]) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      label: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                Text(label),
              ],
            )
          : Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
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
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(AppIcons.get(reward.icon), size: 24, color: Colors.white),
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
                  Icon(Icons.auto_awesome, size: 20, color: AppColors.gold),
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
          AppButton.text(
            onPressed: () => Navigator.pop(context),
            label: 'Abbrechen',
          ),
          AppButton.primary(
            onPressed: () => _purchaseReward(context, reward, userId),
            label: 'Kaufen',
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black87,
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
