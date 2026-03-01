import 'package:flutter/foundation.dart';
import '../models/points_account.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../services/storage_service.dart';

class PointsProvider extends ChangeNotifier {
  Map<String, PointsAccount> _accounts = {};
  Map<String, List<Transaction>> _transactions = {};

  Map<String, PointsAccount> get accounts => Map.unmodifiable(_accounts);
  Map<String, List<Transaction>> get transactions => Map.unmodifiable(_transactions);

  static const String _accountsKey = 'points_accounts';
  static const String _transactionsKey = 'transactions';

  // Getters
  int balance(String userId) {
    return _accounts[userId]?.balance ?? 0;
  }

  int weeklyEarned(String userId) {
    final userTransactions = _transactions[userId] ?? [];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return userTransactions
        .where((t) =>
            t.amount > 0 &&
            t.createdAt.isAfter(weekStartDate))
        .fold(0, (sum, t) => sum + t.amount);
  }

  List<Transaction> recentTransactions(String userId, {int limit = 10}) {
    final userTransactions = _transactions[userId] ?? [];
    final sorted = List<Transaction>.from(userTransactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  // Load from storage
  Future<void> loadData() async {
    try {
      // Load accounts
      final accountsList = await StorageService.loadList(
        _accountsKey,
        PointsAccount.fromJson,
      );
      _accounts = {for (var account in accountsList) account.userId: account};

      // Load transactions
      final transactionsList = await StorageService.loadList(
        _transactionsKey,
        Transaction.fromJson,
      );

      // Group by userId
      _transactions = {};
      for (final transaction in transactionsList) {
        if (!_transactions.containsKey(transaction.userId)) {
          _transactions[transaction.userId] = [];
        }
        _transactions[transaction.userId]!.add(transaction);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('PointsProvider.loadData error: $e');
    }
  }

  // Initialize account for user
  Future<void> initialize(String userId) async {
    if (_accounts.containsKey(userId)) return;

    final account = PointsAccount(
      userId: userId,
      lastUpdated: DateTime.now(),
    );

    _accounts[userId] = account;
    _transactions[userId] = [];

    await _saveAccounts();
    notifyListeners();
  }

  // Earn points
  Future<bool> earn(
    String userId,
    int amount,
    TransactionType type, {
    String? referenceId,
    String? description,
  }) async {
    try {
      await initialize(userId);

      final account = _accounts[userId]!;
      final updatedAccount = account.earn(amount);
      _accounts[userId] = updatedAccount;

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        amount: amount,
        balanceAfter: updatedAccount.balance,
        referenceId: referenceId,
        description: description,
        createdAt: DateTime.now(),
      );

      _transactions[userId]!.add(transaction);

      await _saveAccounts();
      await _saveTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PointsProvider.earn error: $e');
      return false;
    }
  }

  // Spend points
  Future<bool> spend(
    String userId,
    int amount,
    String referenceId,
    String description,
  ) async {
    try {
      await initialize(userId);

      final account = _accounts[userId]!;

      // Check if user can afford
      if (!account.canAfford(amount)) {
        return false;
      }

      final updatedAccount = account.spend(amount);
      _accounts[userId] = updatedAccount;

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: TransactionType.purchase,
        amount: -amount,
        balanceAfter: updatedAccount.balance,
        referenceId: referenceId,
        description: description,
        createdAt: DateTime.now(),
      );

      _transactions[userId]!.add(transaction);

      await _saveAccounts();
      await _saveTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PointsProvider.spend error: $e');
      return false;
    }
  }

  // Get transaction history
  List<Transaction> getTransactionHistory(
    String userId, {
    TransactionType? filter,
  }) {
    final userTransactions = _transactions[userId] ?? [];

    if (filter == null) {
      return List.from(userTransactions)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return userTransactions
        .where((t) => t.type == filter)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Persistence helpers
  Future<void> _saveAccounts() async {
    final accountsList = _accounts.values.toList();
    await StorageService.saveList(
      _accountsKey,
      accountsList,
      (a) => a.toJson(),
    );
  }

  Future<void> _saveTransactions() async {
    final allTransactions = <Transaction>[];
    for (final transactions in _transactions.values) {
      allTransactions.addAll(transactions);
    }
    await StorageService.saveList(
      _transactionsKey,
      allTransactions,
      (t) => t.toJson(),
    );
  }
}
