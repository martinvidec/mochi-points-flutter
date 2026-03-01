import 'package:flutter/material.dart';
import '../models/reward.dart';
import '../models/enums.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final int userBalance;
  final VoidCallback onPurchase;

  const RewardCard({
    super.key,
    required this.reward,
    required this.userBalance,
    required this.onPurchase,
  });

  bool get canAfford => userBalance >= reward.price;
  bool get isAvailable => reward.isAvailable && canAfford;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(reward.category).withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        reward.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (reward.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reward.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const Spacer(),

                // Stock indicator
                if (reward.hasLimitedStock) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: reward.stock! > 0 ? Colors.grey.shade600 : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Noch ${reward.stock}',
                        style: TextStyle(
                          fontSize: 12,
                          color: reward.stock! > 0 ? Colors.grey.shade600 : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Price and buy button
                Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE66D).withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${reward.price}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: canAfford ? Colors.black87 : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Buy button
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: isAvailable ? onPurchase : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE66D),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Kaufen',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Locked overlay
          if (!canAfford)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.white.withAlpha(200),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Noch ${reward.price - userBalance} Punkte',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Out of stock overlay
          if (reward.hasLimitedStock && reward.stock == 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.remove_shopping_cart,
                        color: Colors.white.withAlpha(200),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ausverkauft',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(RewardCategory category) {
    switch (category) {
      case RewardCategory.experience:
        return Colors.purple;
      case RewardCategory.item:
        return Colors.blue;
      case RewardCategory.privilege:
        return Colors.orange;
      case RewardCategory.custom:
        return Colors.teal;
    }
  }
}
