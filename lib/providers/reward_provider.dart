import 'package:flutter/foundation.dart';
import '../models/reward.dart';
import '../models/purchase.dart';
import '../models/enums.dart';
import '../services/storage_service.dart';
import 'points_provider.dart';

class RewardProvider extends ChangeNotifier {
  List<Reward> _rewards = [];
  Map<String, List<Purchase>> _purchases = {};

  PointsProvider? _pointsProvider;

  List<Reward> get rewards => List.unmodifiable(_rewards);
  Map<String, List<Purchase>> get purchases => Map.unmodifiable(_purchases);

  static const String _rewardsKey = 'rewards';
  static const String _purchasesKey = 'purchases';

  // Inject PointsProvider for point deduction
  void setPointsProvider(PointsProvider provider) {
    _pointsProvider = provider;
  }

  // Getters
  List<Reward> get availableRewards {
    return _rewards.where((r) => r.isAvailable).toList();
  }

  List<Purchase> userPurchases(String userId) {
    return _purchases[userId] ?? [];
  }

  List<Purchase> get pendingRedemptions {
    final pending = <Purchase>[];
    for (final userPurchases in _purchases.values) {
      pending.addAll(
        userPurchases.where((p) => p.status == PurchaseStatus.pendingRedemption),
      );
    }
    return pending;
  }

  List<Purchase> purchaseHistory(String userId) {
    final userPurchases = _purchases[userId] ?? [];
    return List.from(userPurchases)
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
  }

  Reward? getRewardById(String rewardId) {
    try {
      return _rewards.firstWhere((r) => r.id == rewardId);
    } catch (_) {
      return null;
    }
  }

  // Load from storage
  Future<void> loadData() async {
    try {
      // Load rewards
      _rewards = await StorageService.loadList(
        _rewardsKey,
        Reward.fromJson,
      );

      // Load purchases
      final purchasesList = await StorageService.loadList(
        _purchasesKey,
        Purchase.fromJson,
      );

      // Group by userId
      _purchases = {};
      for (final purchase in purchasesList) {
        if (!_purchases.containsKey(purchase.userId)) {
          _purchases[purchase.userId] = [];
        }
        _purchases[purchase.userId]!.add(purchase);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('RewardProvider.loadData error: $e');
    }
  }

  // Create reward
  Future<void> createReward(Reward reward) async {
    _rewards.add(reward);
    await _saveRewards();
    notifyListeners();
  }

  // Update reward
  Future<void> updateReward(Reward reward) async {
    final index = _rewards.indexWhere((r) => r.id == reward.id);
    if (index != -1) {
      _rewards[index] = reward;
      await _saveRewards();
      notifyListeners();
    }
  }

  // Delete reward
  Future<void> deleteReward(String rewardId) async {
    _rewards.removeWhere((r) => r.id == rewardId);
    await _saveRewards();
    notifyListeners();
  }

  // Purchase reward
  Future<bool> purchaseReward(String rewardId, String userId) async {
    try {
      final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
      if (rewardIndex == -1) return false;

      final reward = _rewards[rewardIndex];

      // Check availability
      if (!reward.isAvailable) return false;

      // Check points
      if (_pointsProvider == null) {
        debugPrint('RewardProvider: PointsProvider not set');
        return false;
      }

      // Deduct points
      final success = await _pointsProvider!.spend(
        userId,
        reward.price,
        rewardId,
        'Kauf: ${reward.name}',
      );

      if (!success) return false;

      // Reduce stock if limited
      if (reward.hasLimitedStock) {
        _rewards[rewardIndex] = reward.copyWith(
          stock: reward.stock! - 1,
        );
      }

      // Create purchase
      final purchase = Purchase(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rewardId: rewardId,
        userId: userId,
        totalPrice: reward.price,
        purchasedAt: DateTime.now(),
      );

      if (!_purchases.containsKey(userId)) {
        _purchases[userId] = [];
      }
      _purchases[userId]!.add(purchase);

      await _saveRewards();
      await _savePurchases();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('RewardProvider.purchaseReward error: $e');
      return false;
    }
  }

  // Request redemption (child wants to redeem)
  Future<bool> requestRedemption(String purchaseId) async {
    try {
      for (final userId in _purchases.keys) {
        final purchaseIndex = _purchases[userId]!.indexWhere((p) => p.id == purchaseId);
        if (purchaseIndex != -1) {
          final purchase = _purchases[userId]![purchaseIndex];

          if (purchase.status != PurchaseStatus.purchased) return false;

          _purchases[userId]![purchaseIndex] = purchase.copyWith(
            status: PurchaseStatus.pendingRedemption,
          );

          await _savePurchases();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('RewardProvider.requestRedemption error: $e');
      return false;
    }
  }

  // Confirm redemption (parent confirms)
  Future<bool> confirmRedemption(String purchaseId, String parentId) async {
    try {
      for (final userId in _purchases.keys) {
        final purchaseIndex = _purchases[userId]!.indexWhere((p) => p.id == purchaseId);
        if (purchaseIndex != -1) {
          final purchase = _purchases[userId]![purchaseIndex];

          if (purchase.status != PurchaseStatus.pendingRedemption) return false;

          _purchases[userId]![purchaseIndex] = purchase.copyWith(
            status: PurchaseStatus.redeemed,
            redeemedAt: DateTime.now(),
            redeemedBy: parentId,
          );

          await _savePurchases();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('RewardProvider.confirmRedemption error: $e');
      return false;
    }
  }

  // Cancel redemption request
  Future<bool> cancelRedemption(String purchaseId) async {
    try {
      for (final userId in _purchases.keys) {
        final purchaseIndex = _purchases[userId]!.indexWhere((p) => p.id == purchaseId);
        if (purchaseIndex != -1) {
          final purchase = _purchases[userId]![purchaseIndex];

          if (purchase.status != PurchaseStatus.pendingRedemption) return false;

          _purchases[userId]![purchaseIndex] = purchase.copyWith(
            status: PurchaseStatus.purchased,
          );

          await _savePurchases();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('RewardProvider.cancelRedemption error: $e');
      return false;
    }
  }

  // Persistence helpers
  Future<void> _saveRewards() async {
    await StorageService.saveList(
      _rewardsKey,
      _rewards,
      (r) => r.toJson(),
    );
  }

  Future<void> _savePurchases() async {
    final allPurchases = <Purchase>[];
    for (final purchases in _purchases.values) {
      allPurchases.addAll(purchases);
    }
    await StorageService.saveList(
      _purchasesKey,
      allPurchases,
      (p) => p.toJson(),
    );
  }
}
