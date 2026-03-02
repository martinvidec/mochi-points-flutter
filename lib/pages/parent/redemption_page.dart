import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/purchase.dart';
import '../../models/enums.dart';
import '../../providers/reward_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';

class RedemptionPage extends StatelessWidget {
  const RedemptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundStart,
        appBar: AppBar(
          title: const Text('Einlösungen'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ausstehend'),
              Tab(text: 'Verlauf'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context) {
    final rewardProvider = context.watch<RewardProvider>();
    final pending = rewardProvider.pendingRedemptions;

    if (pending.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Keine ausstehenden Einlösungen',
        description: 'Wenn deine Kinder Belohnungen einlösen möchten, erscheinen sie hier.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        return _RedemptionCard(
          purchase: pending[index],
          showActions: true,
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final rewardProvider = context.watch<RewardProvider>();

    // Get all redeemed and cancelled purchases
    final history = <Purchase>[];
    for (final userPurchases in rewardProvider.purchases.values) {
      history.addAll(userPurchases.where((p) =>
          p.status == PurchaseStatus.redeemed ||
          p.status == PurchaseStatus.cancelled));
    }
    history.sort((a, b) {
      final aDate = a.redeemedAt ?? a.purchasedAt;
      final bDate = b.redeemedAt ?? b.purchasedAt;
      return bDate.compareTo(aDate);
    });

    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'Kein Verlauf',
        description: 'Bestätigte und abgelehnte Einlösungen erscheinen hier.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return _RedemptionCard(
          purchase: history[index],
          showActions: false,
        );
      },
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  final Purchase purchase;
  final bool showActions;

  const _RedemptionCard({
    required this.purchase,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final rewardProvider = context.watch<RewardProvider>();
    final authProvider = context.watch<AuthProvider>();
    final reward = rewardProvider.getRewardById(purchase.rewardId);

    // Get child name
    final childName = authProvider.getUserById(purchase.userId)?.name ?? 'Kind';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Child info + Reward
            Row(
              children: [
                // Child avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    childName.isNotEmpty ? childName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Child name and reward
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'möchte einlösen:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge (only in history)
                if (!showActions) _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: 16),

            // Reward info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        reward?.icon ?? '🎁',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          'Gekauft am ${_formatDate(purchase.purchasedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectRedemption(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Ablehnen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmRedemption(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.text,
                      ),
                      child: const Text('Bestätigen'),
                    ),
                  ),
                ],
              ),
            ],

            // Redeemed date (in history)
            if (!showActions && purchase.redeemedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                purchase.status == PurchaseStatus.redeemed
                    ? 'Bestätigt am ${_formatDate(purchase.redeemedAt!)}'
                    : 'Abgelehnt am ${_formatDate(purchase.redeemedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isRedeemed = purchase.status == PurchaseStatus.redeemed;
    final color = isRedeemed ? AppColors.success : AppColors.error;
    final text = isRedeemed ? 'Bestätigt' : 'Abgelehnt';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _confirmRedemption(BuildContext context) async {
    final rewardProvider = context.read<RewardProvider>();
    final authProvider = context.read<AuthProvider>();
    final parentId = authProvider.currentUser?.id ?? '';

    final success = await rewardProvider.confirmRedemption(purchase.id, parentId);

    if (context.mounted) {
      if (success) {
        AppSnackbar.success(context, 'Einlösung bestätigt!');
      } else {
        AppSnackbar.error(context, 'Fehler bei der Bestätigung');
      }
    }
  }

  Future<void> _rejectRedemption(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Einlösung ablehnen?'),
        content: const Text(
          'Die Punkte werden dem Kind zurückerstattet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.text,
            ),
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    final rewardProvider = context.read<RewardProvider>();
    final success = await rewardProvider.rejectRedemption(purchase.id);

    if (context.mounted) {
      if (success) {
        AppSnackbar.success(context, 'Einlösung abgelehnt. Punkte wurden zurückerstattet.');
      } else {
        AppSnackbar.error(context, 'Fehler bei der Ablehnung');
      }
    }
  }
}
