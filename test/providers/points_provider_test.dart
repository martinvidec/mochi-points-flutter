import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/providers/points_provider.dart';
import 'package:flutter_application_1/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PointsProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = PointsProvider();
  });

  group('PointsProvider', () {
    group('Initialization', () {
      test('balance returns 0 for uninitialized user', () {
        expect(provider.balance('user-1'), 0);
      });

      test('initialize creates account with zero balance', () async {
        await provider.initialize('user-1');

        expect(provider.balance('user-1'), 0);
        expect(provider.accounts['user-1'], isNotNull);
      });

      test('initialize is idempotent', () async {
        await provider.initialize('user-1');
        await provider.earn('user-1', 100, TransactionType.questComplete);
        await provider.initialize('user-1');

        // Balance should still be 100
        expect(provider.balance('user-1'), 100);
      });
    });

    group('Earn Points', () {
      test('earn increases balance', () async {
        await provider.earn('user-1', 50, TransactionType.questComplete);

        expect(provider.balance('user-1'), 50);
      });

      test('earn accumulates correctly', () async {
        await provider.earn('user-1', 50, TransactionType.questComplete);
        await provider.earn('user-1', 30, TransactionType.bonus);
        await provider.earn('user-1', 20, TransactionType.questComplete);

        expect(provider.balance('user-1'), 100);
      });

      test('earn creates transaction record', () async {
        await provider.earn(
          'user-1',
          50,
          TransactionType.questComplete,
          referenceId: 'quest-1',
          description: 'Completed quest',
        );

        final transactions = provider.getTransactionHistory('user-1');
        expect(transactions.length, 1);
        expect(transactions.first.amount, 50);
        expect(transactions.first.type, TransactionType.questComplete);
        expect(transactions.first.referenceId, 'quest-1');
        expect(transactions.first.description, 'Completed quest');
        expect(transactions.first.balanceAfter, 50);
      });

      test('earn updates totalEarned', () async {
        await provider.earn('user-1', 50, TransactionType.questComplete);
        await provider.earn('user-1', 30, TransactionType.bonus);

        final account = provider.accounts['user-1']!;
        expect(account.totalEarned, 80);
      });

      test('earn notifies listeners', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.earn('user-1', 50, TransactionType.questComplete);

        expect(notified, true);
      });
    });

    group('Spend Points', () {
      test('spend decreases balance', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        final result = await provider.spend('user-1', 30, 'reward-1', 'Bought reward');

        expect(result, true);
        expect(provider.balance('user-1'), 70);
      });

      test('spend fails when insufficient balance', () async {
        await provider.earn('user-1', 20, TransactionType.questComplete);
        final result = await provider.spend('user-1', 50, 'reward-1', 'Expensive reward');

        expect(result, false);
        expect(provider.balance('user-1'), 20);
      });

      test('spend creates transaction with negative amount', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        await provider.spend('user-1', 30, 'reward-1', 'Bought reward');

        final transactions = provider.getTransactionHistory('user-1');
        final spendTransaction = transactions.firstWhere(
          (t) => t.type == TransactionType.purchase,
        );

        expect(spendTransaction.amount, -30);
        expect(spendTransaction.balanceAfter, 70);
        expect(spendTransaction.referenceId, 'reward-1');
      });

      test('spend updates totalSpent', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        await provider.spend('user-1', 30, 'reward-1', 'Reward 1');
        await provider.spend('user-1', 20, 'reward-2', 'Reward 2');

        final account = provider.accounts['user-1']!;
        expect(account.totalSpent, 50);
      });

      test('spend exactly at balance succeeds', () async {
        await provider.earn('user-1', 50, TransactionType.questComplete);
        final result = await provider.spend('user-1', 50, 'reward-1', 'All points');

        expect(result, true);
        expect(provider.balance('user-1'), 0);
      });
    });

    group('Transaction History', () {
      test('getTransactionHistory returns all transactions sorted by date', () async {
        await provider.earn('user-1', 50, TransactionType.questComplete);
        await Future.delayed(const Duration(milliseconds: 10));
        await provider.earn('user-1', 30, TransactionType.bonus);
        await Future.delayed(const Duration(milliseconds: 10));
        await provider.spend('user-1', 20, 'reward-1', 'Reward');

        final transactions = provider.getTransactionHistory('user-1');

        expect(transactions.length, 3);
        // Should be sorted newest first
        expect(transactions[0].type, TransactionType.purchase);
        expect(transactions[1].type, TransactionType.bonus);
        expect(transactions[2].type, TransactionType.questComplete);
      });

      test('getTransactionHistory filters by type', () async {
        await provider.earn('user-1', 50, TransactionType.questComplete);
        await provider.earn('user-1', 30, TransactionType.bonus);
        await provider.spend('user-1', 20, 'reward-1', 'Reward');

        final questTransactions = provider.getTransactionHistory(
          'user-1',
          filter: TransactionType.questComplete,
        );

        expect(questTransactions.length, 1);
        expect(questTransactions.first.type, TransactionType.questComplete);
      });

      test('recentTransactions respects limit', () async {
        for (int i = 0; i < 15; i++) {
          await provider.earn('user-1', 10, TransactionType.questComplete);
        }

        final recent = provider.recentTransactions('user-1', limit: 5);
        expect(recent.length, 5);
      });

      test('recentTransactions returns newest first', () async {
        await provider.earn(
          'user-1',
          10,
          TransactionType.questComplete,
          description: 'first',
        );
        await Future.delayed(const Duration(milliseconds: 10));
        await provider.earn(
          'user-1',
          20,
          TransactionType.questComplete,
          description: 'second',
        );

        final recent = provider.recentTransactions('user-1');
        expect(recent.first.description, 'second');
        expect(recent.last.description, 'first');
      });
    });

    group('Weekly Earned', () {
      test('weeklyEarned calculates points earned this week', () async {
        await provider.earn('user-1', 50, TransactionType.questComplete);
        await provider.earn('user-1', 30, TransactionType.bonus);

        expect(provider.weeklyEarned('user-1'), 80);
      });

      test('weeklyEarned excludes spent points', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        await provider.spend('user-1', 30, 'reward-1', 'Reward');

        // Only earned should count, not spent
        expect(provider.weeklyEarned('user-1'), 100);
      });

      test('weeklyEarned returns 0 for no transactions', () {
        expect(provider.weeklyEarned('user-1'), 0);
      });
    });

    group('Multiple Users', () {
      test('handles multiple users independently', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        await provider.earn('user-2', 50, TransactionType.questComplete);

        expect(provider.balance('user-1'), 100);
        expect(provider.balance('user-2'), 50);
      });

      test('transactions are separate per user', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        await provider.earn('user-2', 50, TransactionType.questComplete);

        expect(provider.getTransactionHistory('user-1').length, 1);
        expect(provider.getTransactionHistory('user-2').length, 1);
      });
    });

    group('Persistence', () {
      test('accounts persist after reload', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);

        final newProvider = PointsProvider();
        await newProvider.loadData();

        expect(newProvider.balance('user-1'), 100);
      });

      test('transactions persist after reload', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        await provider.spend('user-1', 30, 'reward-1', 'Reward');

        final newProvider = PointsProvider();
        await newProvider.loadData();

        expect(newProvider.getTransactionHistory('user-1').length, 2);
      });

      test('account totals persist correctly', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        await provider.spend('user-1', 30, 'reward-1', 'Reward');

        final newProvider = PointsProvider();
        await newProvider.loadData();

        final account = newProvider.accounts['user-1']!;
        expect(account.totalEarned, 100);
        expect(account.totalSpent, 30);
        expect(account.balance, 70);
      });
    });

    group('Transaction Types', () {
      test('all transaction types work correctly', () async {
        await provider.earn('user-1', 50, TransactionType.questComplete);
        await provider.earn('user-1', 20, TransactionType.bonus);
        await provider.earn('user-1', 10, TransactionType.adjustment);
        await provider.earn('user-1', 5, TransactionType.refund);

        expect(provider.balance('user-1'), 85);

        final transactions = provider.getTransactionHistory('user-1');
        expect(
          transactions.map((t) => t.type).toSet(),
          containsAll([
            TransactionType.questComplete,
            TransactionType.bonus,
            TransactionType.adjustment,
            TransactionType.refund,
          ]),
        );
      });
    });

    group('Edge Cases', () {
      test('handles zero amount earn', () async {
        await provider.earn('user-1', 0, TransactionType.bonus);

        expect(provider.balance('user-1'), 0);
        expect(provider.getTransactionHistory('user-1').length, 1);
      });

      test('handles zero amount spend', () async {
        await provider.earn('user-1', 100, TransactionType.questComplete);
        final result = await provider.spend('user-1', 0, 'free', 'Free item');

        expect(result, true);
        expect(provider.balance('user-1'), 100);
      });

      test('handles large amounts', () async {
        await provider.earn('user-1', 1000000, TransactionType.bonus);
        await provider.spend('user-1', 999999, 'big-purchase', 'Big purchase');

        expect(provider.balance('user-1'), 1);
      });
    });

    group('Integration: Quest Complete Flow', () {
      test('earning points for quest completion creates proper record', () async {
        // Simulate what happens when a quest is approved
        final questId = 'quest-123';
        final childId = 'child-1';
        final points = 25;

        final result = await provider.earn(
          childId,
          points,
          TransactionType.questComplete,
          referenceId: questId,
          description: 'Completed: Clean Room',
        );

        expect(result, true);
        expect(provider.balance(childId), 25);

        final transaction = provider.getTransactionHistory(childId).first;
        expect(transaction.type, TransactionType.questComplete);
        expect(transaction.referenceId, questId);
        expect(transaction.description, contains('Clean Room'));
        expect(transaction.isEarned, true);
        expect(transaction.isSpent, false);
      });
    });
  });
}
