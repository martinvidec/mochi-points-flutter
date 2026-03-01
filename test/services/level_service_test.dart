import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/level_service.dart';

void main() {
  group('LevelService', () {
    group('xpBetweenLevels', () {
      test('Level 1 requires 100 XP', () {
        expect(LevelService.xpBetweenLevels(1), 100);
      });

      test('Level 2 requires 150 XP', () {
        expect(LevelService.xpBetweenLevels(2), 150);
      });

      test('Level 3 requires 200 XP', () {
        expect(LevelService.xpBetweenLevels(3), 200);
      });

      test('Level 10 requires 550 XP', () {
        expect(LevelService.xpBetweenLevels(10), 550);
      });
    });

    group('xpForLevel', () {
      test('Level 1 requires 0 cumulative XP', () {
        expect(LevelService.xpForLevel(1), 0);
      });

      test('Level 2 requires 100 cumulative XP', () {
        expect(LevelService.xpForLevel(2), 100);
      });

      test('Level 3 requires 250 cumulative XP', () {
        expect(LevelService.xpForLevel(3), 250);
      });

      test('Level 4 requires 450 cumulative XP', () {
        expect(LevelService.xpForLevel(4), 450);
      });
    });

    group('levelForXP', () {
      test('0 XP = Level 1', () {
        expect(LevelService.levelForXP(0), 1);
      });

      test('99 XP = Level 1', () {
        expect(LevelService.levelForXP(99), 1);
      });

      test('100 XP = Level 2', () {
        expect(LevelService.levelForXP(100), 2);
      });

      test('249 XP = Level 2', () {
        expect(LevelService.levelForXP(249), 2);
      });

      test('250 XP = Level 3', () {
        expect(LevelService.levelForXP(250), 3);
      });

      test('450 XP = Level 4', () {
        expect(LevelService.levelForXP(450), 4);
      });
    });

    group('progressToNextLevel', () {
      test('0 XP = 0% progress', () {
        expect(LevelService.progressToNextLevel(0), 0.0);
      });

      test('50 XP = 50% progress to level 2', () {
        expect(LevelService.progressToNextLevel(50), 0.5);
      });

      test('100 XP = 0% progress to level 3', () {
        expect(LevelService.progressToNextLevel(100), 0.0);
      });

      test('175 XP = 50% progress to level 3', () {
        expect(LevelService.progressToNextLevel(175), 0.5);
      });
    });

    group('titleForLevel', () {
      test('Level 1 = Mochi Novice', () {
        expect(LevelService.titleForLevel(1), 'Mochi Novice');
      });

      test('Level 10 = Mochi Novice', () {
        expect(LevelService.titleForLevel(10), 'Mochi Novice');
      });

      test('Level 11 = Mochi Apprentice', () {
        expect(LevelService.titleForLevel(11), 'Mochi Apprentice');
      });

      test('Level 25 = Mochi Apprentice', () {
        expect(LevelService.titleForLevel(25), 'Mochi Apprentice');
      });

      test('Level 26 = Mochi Champion', () {
        expect(LevelService.titleForLevel(26), 'Mochi Champion');
      });

      test('Level 50 = Mochi Champion', () {
        expect(LevelService.titleForLevel(50), 'Mochi Champion');
      });

      test('Level 51 = Mochi Legend', () {
        expect(LevelService.titleForLevel(51), 'Mochi Legend');
      });
    });

    group('wouldLevelUp', () {
      test('Adding 100 XP from 0 levels up', () {
        expect(LevelService.wouldLevelUp(0, 100), true);
      });

      test('Adding 50 XP from 0 does not level up', () {
        expect(LevelService.wouldLevelUp(0, 50), false);
      });

      test('Adding 150 XP from 100 levels up', () {
        expect(LevelService.wouldLevelUp(100, 150), true);
      });
    });
  });
}
