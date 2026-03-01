import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/streak_service.dart';

void main() {
  group('StreakService', () {
    group('calculateStreak', () {
      test('returns 0 for empty list', () {
        expect(StreakService.calculateStreak([]), 0);
      });

      test('returns 1 for activity today only', () {
        final today = DateTime.now();
        expect(StreakService.calculateStreak([today]), 1);
      });

      test('returns 1 for activity yesterday only', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(StreakService.calculateStreak([yesterday]), 1);
      });

      test('returns 0 if last activity was 2+ days ago', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        expect(StreakService.calculateStreak([twoDaysAgo]), 0);
      });

      test('counts consecutive days correctly', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dates = [
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
          today.subtract(const Duration(days: 3)),
        ];
        expect(StreakService.calculateStreak(dates), 4);
      });

      test('stops counting at gap', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dates = [
          today,
          today.subtract(const Duration(days: 1)),
          // Gap: day 2 missing
          today.subtract(const Duration(days: 3)),
          today.subtract(const Duration(days: 4)),
        ];
        expect(StreakService.calculateStreak(dates), 2);
      });

      test('handles duplicate dates', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dates = [
          today,
          today, // Duplicate
          DateTime(today.year, today.month, today.day, 10, 30), // Same day
          today.subtract(const Duration(days: 1)),
        ];
        expect(StreakService.calculateStreak(dates), 2);
      });

      test('handles unsorted dates', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dates = [
          today.subtract(const Duration(days: 2)),
          today,
          today.subtract(const Duration(days: 1)),
        ];
        expect(StreakService.calculateStreak(dates), 3);
      });
    });

    group('streakBonusMultiplier', () {
      test('returns 1.0 for streak < 7', () {
        expect(StreakService.streakBonusMultiplier(0), 1.0);
        expect(StreakService.streakBonusMultiplier(3), 1.0);
        expect(StreakService.streakBonusMultiplier(6), 1.0);
      });

      test('returns 1.1 for streak 7-13', () {
        expect(StreakService.streakBonusMultiplier(7), 1.1);
        expect(StreakService.streakBonusMultiplier(10), 1.1);
        expect(StreakService.streakBonusMultiplier(13), 1.1);
      });

      test('returns 1.15 for streak 14-29', () {
        expect(StreakService.streakBonusMultiplier(14), 1.15);
        expect(StreakService.streakBonusMultiplier(20), 1.15);
        expect(StreakService.streakBonusMultiplier(29), 1.15);
      });

      test('returns 1.25 for streak 30-99', () {
        expect(StreakService.streakBonusMultiplier(30), 1.25);
        expect(StreakService.streakBonusMultiplier(50), 1.25);
        expect(StreakService.streakBonusMultiplier(99), 1.25);
      });

      test('returns 1.5 for streak 100+', () {
        expect(StreakService.streakBonusMultiplier(100), 1.5);
        expect(StreakService.streakBonusMultiplier(365), 1.5);
        expect(StreakService.streakBonusMultiplier(1000), 1.5);
      });
    });

    group('streakBonusPercent', () {
      test('returns correct percentages', () {
        expect(StreakService.streakBonusPercent(0), 0);
        expect(StreakService.streakBonusPercent(6), 0);
        expect(StreakService.streakBonusPercent(7), 10);
        expect(StreakService.streakBonusPercent(14), 15);
        expect(StreakService.streakBonusPercent(30), 25);
        expect(StreakService.streakBonusPercent(100), 50);
      });
    });

    group('checkStreakMilestone', () {
      test('returns milestone when crossed', () {
        expect(StreakService.checkStreakMilestone(6, 7), 7);
        expect(StreakService.checkStreakMilestone(13, 14), 14);
        expect(StreakService.checkStreakMilestone(29, 30), 30);
        expect(StreakService.checkStreakMilestone(59, 60), 60);
        expect(StreakService.checkStreakMilestone(99, 100), 100);
        expect(StreakService.checkStreakMilestone(364, 365), 365);
      });

      test('returns null when no milestone crossed', () {
        expect(StreakService.checkStreakMilestone(5, 6), isNull);
        expect(StreakService.checkStreakMilestone(7, 8), isNull);
        expect(StreakService.checkStreakMilestone(15, 20), isNull);
      });

      test('returns first milestone when multiple crossed', () {
        expect(StreakService.checkStreakMilestone(5, 15), 7);
      });
    });

    group('checkAllMilestones', () {
      test('returns empty list when no milestones crossed', () {
        expect(StreakService.checkAllMilestones(5, 6), isEmpty);
        expect(StreakService.checkAllMilestones(8, 10), isEmpty);
      });

      test('returns single milestone', () {
        expect(StreakService.checkAllMilestones(6, 7), [7]);
        expect(StreakService.checkAllMilestones(29, 30), [30]);
      });

      test('returns multiple milestones when skipping', () {
        expect(StreakService.checkAllMilestones(5, 15), [7, 14]);
        expect(StreakService.checkAllMilestones(0, 100), [7, 14, 30, 60, 100]);
      });
    });

    group('isStreakActive', () {
      test('returns false for null date', () {
        expect(StreakService.isStreakActive(null), false);
      });

      test('returns true for activity today', () {
        final today = DateTime.now();
        expect(StreakService.isStreakActive(today), true);
      });

      test('returns true for activity yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(StreakService.isStreakActive(yesterday), true);
      });

      test('returns false for activity 2+ days ago', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        expect(StreakService.isStreakActive(twoDaysAgo), false);
      });
    });

    group('hasActivityToday', () {
      test('returns false for null date', () {
        expect(StreakService.hasActivityToday(null), false);
      });

      test('returns true for activity today', () {
        final today = DateTime.now();
        expect(StreakService.hasActivityToday(today), true);
      });

      test('returns false for activity yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(StreakService.hasActivityToday(yesterday), false);
      });
    });

    group('daysUntilStreakBreaks', () {
      test('returns 0 for null date', () {
        expect(StreakService.daysUntilStreakBreaks(null), 0);
      });

      test('returns 2 for activity today', () {
        final today = DateTime.now();
        expect(StreakService.daysUntilStreakBreaks(today), 2);
      });

      test('returns 1 for activity yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(StreakService.daysUntilStreakBreaks(yesterday), 1);
      });

      test('returns 0 for activity 2+ days ago', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        expect(StreakService.daysUntilStreakBreaks(twoDaysAgo), 0);
      });
    });

    group('nextMilestone', () {
      test('returns correct next milestone', () {
        expect(StreakService.nextMilestone(0), 7);
        expect(StreakService.nextMilestone(6), 7);
        expect(StreakService.nextMilestone(7), 14);
        expect(StreakService.nextMilestone(14), 30);
        expect(StreakService.nextMilestone(30), 60);
        expect(StreakService.nextMilestone(60), 100);
        expect(StreakService.nextMilestone(100), 365);
      });

      test('returns null when all milestones reached', () {
        expect(StreakService.nextMilestone(365), isNull);
        expect(StreakService.nextMilestone(500), isNull);
      });
    });

    group('progressToNextMilestone', () {
      test('returns correct progress', () {
        expect(StreakService.progressToNextMilestone(0), 0.0);
        expect(StreakService.progressToNextMilestone(7), 0.0);
        expect(StreakService.progressToNextMilestone(14), 0.0);
      });

      test('returns 1.0 when all milestones reached', () {
        expect(StreakService.progressToNextMilestone(365), 1.0);
        expect(StreakService.progressToNextMilestone(500), 1.0);
      });

      test('calculates partial progress', () {
        // Progress to 7 (from 0)
        expect(StreakService.progressToNextMilestone(3), closeTo(3 / 7, 0.01));

        // Progress to 14 (from 7)
        expect(StreakService.progressToNextMilestone(10), closeTo(3 / 7, 0.01));

        // Progress to 30 (from 14)
        expect(StreakService.progressToNextMilestone(22), 0.5);
      });
    });

    group('streakMessage', () {
      test('returns start message for inactive streak', () {
        expect(
          StreakService.streakMessage(5, isActive: false),
          'Starte heute eine neue Serie!',
        );
      });

      test('returns begin message for streak 0', () {
        expect(StreakService.streakMessage(0), 'Beginne deine Serie!');
      });

      test('returns good start for streak 1', () {
        expect(
          StreakService.streakMessage(1),
          'Guter Start! Mach morgen weiter!',
        );
      });

      test('returns countdown message for streak < 7', () {
        expect(StreakService.streakMessage(5), contains('2 Tage bis zum Bonus'));
      });

      test('returns bonus message for streak >= 7', () {
        expect(StreakService.streakMessage(7), contains('+10% Bonus'));
        expect(StreakService.streakMessage(14), contains('+15% Bonus'));
        expect(StreakService.streakMessage(30), contains('+25% Bonus'));
        expect(StreakService.streakMessage(100), contains('+50% Bonus'));
      });
    });

    group('milestones constant', () {
      test('contains expected values', () {
        expect(StreakService.milestones, [7, 14, 30, 60, 100, 365]);
      });

      test('is sorted ascending', () {
        for (int i = 1; i < StreakService.milestones.length; i++) {
          expect(
            StreakService.milestones[i],
            greaterThan(StreakService.milestones[i - 1]),
          );
        }
      });
    });
  });
}
