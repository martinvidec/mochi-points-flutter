import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../providers/points_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/points_display.dart';

enum TransactionFilter { all, earned, spent }

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  TransactionFilter _filter = TransactionFilter.all;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final pointsProvider = context.watch<PointsProvider>();
    final userId = authProvider.currentUser?.id ?? '';
    final balance = pointsProvider.balance(userId);
    final transactions = pointsProvider.getTransactionHistory(userId);

    final filteredTransactions = _applyFilter(transactions);

    return GlassScaffold(
      appBar: const GlassAppBar(
        title: Text('Transaktionen'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Balance header
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 0,
            child: Center(
              child: PointsDisplay(
                points: balance,
                variant: PointsDisplayVariant.large,
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip(
                  label: 'Alle',
                  filter: TransactionFilter.all,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Verdient',
                  filter: TransactionFilter.earned,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Ausgegeben',
                  filter: TransactionFilter.spent,
                  color: AppColors.error,
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: filteredTransactions.isEmpty
                ? EmptyState.transactions()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(filteredTransactions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required TransactionFilter filter,
    Color? color,
  }) {
    final isSelected = _filter == filter;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = filter;
        });
      },
      selectedColor: color?.withAlpha(50) ?? Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: color ?? Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? Theme.of(context).colorScheme.primary) : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isPositive = transaction.amount > 0;
    final amountColor = isPositive ? AppColors.success : AppColors.error;
    final amountPrefix = isPositive ? '+' : '';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getTypeColor(transaction.type).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getTypeIcon(transaction.type),
                  color: _getTypeColor(transaction.type),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Description and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? _getTypeLabel(transaction.type),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(transaction.createdAt),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Amount and balance after
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${transaction.amount}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '= ${transaction.balanceAfter}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  List<Transaction> _applyFilter(List<Transaction> transactions) {
    switch (_filter) {
      case TransactionFilter.all:
        return transactions;
      case TransactionFilter.earned:
        return transactions.where((t) => t.isEarned).toList();
      case TransactionFilter.spent:
        return transactions.where((t) => t.isSpent).toList();
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.questComplete:
        return Icons.check_circle;
      case TransactionType.purchase:
        return Icons.shopping_bag;
      case TransactionType.bonus:
        return Icons.card_giftcard;
      case TransactionType.adjustment:
        return Icons.tune;
      case TransactionType.refund:
        return Icons.replay;
    }
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.questComplete:
        return AppColors.success;
      case TransactionType.purchase:
        return AppColors.warning;
      case TransactionType.bonus:
        return AppColors.rarityEpic;
      case TransactionType.adjustment:
        return AppColors.rarityRare;
      case TransactionType.refund:
        return AppColors.teal;
    }
  }

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.questComplete:
        return 'Quest abgeschlossen';
      case TransactionType.purchase:
        return 'Einkauf';
      case TransactionType.bonus:
        return 'Bonus';
      case TransactionType.adjustment:
        return 'Anpassung';
      case TransactionType.refund:
        return 'Rückerstattung';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (date == today) {
      return 'Heute, $time';
    } else if (date == yesterday) {
      return 'Gestern, $time';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}, $time';
    }
  }
}
