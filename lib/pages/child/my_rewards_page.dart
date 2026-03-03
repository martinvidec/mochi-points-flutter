import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/purchase.dart';
import '../../models/reward.dart';
import '../../models/enums.dart';
import '../../providers/reward_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_container.dart';

class MyRewardsPage extends StatelessWidget {
  const MyRewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Meine Belohnungen'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktiv'),
              Tab(text: 'Eingelöst'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ActiveRewardsTab(),
            _RedeemedRewardsTab(),
          ],
        ),
      ),
    );
  }
}

class _ActiveRewardsTab extends StatelessWidget {
  const _ActiveRewardsTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final rewardProvider = context.watch<RewardProvider>();
    final userId = authProvider.currentUser?.id ?? '';

    final purchases = rewardProvider.userPurchases(userId).where((p) =>
        p.status == PurchaseStatus.purchased ||
        p.status == PurchaseStatus.pendingRedemption).toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

    if (purchases.isEmpty) {
      return const EmptyState(
        icon: Icons.card_giftcard_outlined,
        title: 'Keine aktiven Belohnungen',
        description: 'Kaufe Belohnungen im Shop!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        final reward = rewardProvider.getRewardById(purchase.rewardId);
        return _PurchaseCard(
          purchase: purchase,
          reward: reward,
          showRedeemButton: true,
        );
      },
    );
  }
}

class _RedeemedRewardsTab extends StatelessWidget {
  const _RedeemedRewardsTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final rewardProvider = context.watch<RewardProvider>();
    final userId = authProvider.currentUser?.id ?? '';

    final purchases = rewardProvider.userPurchases(userId)
        .where((p) => p.status == PurchaseStatus.redeemed)
        .toList()
      ..sort((a, b) => (b.redeemedAt ?? b.purchasedAt)
          .compareTo(a.redeemedAt ?? a.purchasedAt));

    if (purchases.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Noch keine eingelösten Belohnungen',
        description: 'Löse deine gekauften Belohnungen ein!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        final reward = rewardProvider.getRewardById(purchase.rewardId);
        return _PurchaseCard(
          purchase: purchase,
          reward: reward,
          showRedeemButton: false,
        );
      },
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  final Reward? reward;
  final bool showRedeemButton;

  const _PurchaseCard({
    required this.purchase,
    required this.reward,
    required this.showRedeemButton,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getStatusColor().withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                reward?.icon ?? '🎁',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward?.name ?? 'Unbekannte Belohnung',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(purchase.purchasedAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(),
              ],
            ),
          ),

          // Action button
          if (showRedeemButton && purchase.status == PurchaseStatus.purchased)
            AppButton.primary(
              onPressed: () => _showRedeemDialog(context),
              label: 'Einlösen',
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
        return AppColors.rarityRare;
      case PurchaseStatus.pendingRedemption:
        return AppColors.warning;
      case PurchaseStatus.redeemed:
        return AppColors.success;
      case PurchaseStatus.expired:
        return AppColors.textSecondary;
      case PurchaseStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
        return 'Bereit zum Einlösen';
      case PurchaseStatus.pendingRedemption:
        return 'Warte auf Bestätigung';
      case PurchaseStatus.redeemed:
        return 'Eingelöst';
      case PurchaseStatus.expired:
        return 'Abgelaufen';
      case PurchaseStatus.cancelled:
        return 'Storniert';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showRedeemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Text(reward?.icon ?? '🎁', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Einlösen')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.family_restroom,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            const Text(
              'Zeige dies einem Elternteil!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ein Elternteil muss bestätigen, dass du "${reward?.name}" bekommst.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'Abbrechen',
          ),
          AppButton.primary(
            onPressed: () => _requestRedemption(dialogContext),
            label: 'Einlösen anfragen',
          ),
        ],
      ),
    );
  }

  Future<void> _requestRedemption(BuildContext dialogContext) async {
    final rewardProvider = dialogContext.read<RewardProvider>();
    Navigator.pop(dialogContext);

    final success = await rewardProvider.requestRedemption(purchase.id);

    if (dialogContext.mounted) {
      if (success) {
        AppSnackbar.success(dialogContext, 'Einlösung angefragt! Warte auf Bestätigung.');
      } else {
        AppSnackbar.error(dialogContext, 'Fehler beim Einlösen.');
      }
    }
  }
}
