import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/hero.dart';

void main() {
  group('HeroAppearance', () {
    late HeroAppearance testAppearance;

    setUp(() {
      testAppearance = const HeroAppearance(
        baseAvatar: 'avatar_1',
        skinColor: 'light',
        hairStyle: 'short',
        hairColor: 'brown',
        outfit: 'casual',
        accessory: 'glasses',
        pet: 'cat',
      );
    });

    group('JSON Serialization', () {
      test('toJson returns correct map', () {
        final json = testAppearance.toJson();

        expect(json['baseAvatar'], 'avatar_1');
        expect(json['skinColor'], 'light');
        expect(json['hairStyle'], 'short');
        expect(json['hairColor'], 'brown');
        expect(json['outfit'], 'casual');
        expect(json['accessory'], 'glasses');
        expect(json['pet'], 'cat');
      });

      test('fromJson creates correct HeroAppearance', () {
        final json = testAppearance.toJson();
        final restored = HeroAppearance.fromJson(json);

        expect(restored.baseAvatar, testAppearance.baseAvatar);
        expect(restored.skinColor, testAppearance.skinColor);
        expect(restored.hairStyle, testAppearance.hairStyle);
        expect(restored.accessory, testAppearance.accessory);
        expect(restored.pet, testAppearance.pet);
      });

      test('JSON roundtrip preserves all fields', () {
        final json = testAppearance.toJson();
        final restored = HeroAppearance.fromJson(json);
        final jsonAgain = restored.toJson();

        expect(jsonAgain, json);
      });

      test('handles null optional fields', () {
        const appearance = HeroAppearance(
          baseAvatar: 'avatar_2',
          skinColor: 'medium',
          hairStyle: 'long',
          hairColor: 'black',
          outfit: 'sporty',
        );

        final json = appearance.toJson();
        expect(json['accessory'], isNull);
        expect(json['pet'], isNull);

        final restored = HeroAppearance.fromJson(json);
        expect(restored.accessory, isNull);
        expect(restored.pet, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updated = testAppearance.copyWith(
          hairColor: 'blonde',
          outfit: 'formal',
        );

        expect(updated.hairColor, 'blonde');
        expect(updated.outfit, 'formal');
        expect(updated.baseAvatar, testAppearance.baseAvatar);
        expect(updated.skinColor, testAppearance.skinColor);
      });

      test('preserves original when no changes', () {
        final copy = testAppearance.copyWith();

        expect(copy.baseAvatar, testAppearance.baseAvatar);
        expect(copy.accessory, testAppearance.accessory);
      });
    });
  });

  group('Hero', () {
    late Hero testHero;
    late HeroAppearance testAppearance;

    setUp(() {
      testAppearance = const HeroAppearance(
        baseAvatar: 'avatar_1',
        skinColor: 'light',
        hairStyle: 'short',
        hairColor: 'brown',
        outfit: 'casual',
      );

      testHero = Hero(
        id: 'hero-1',
        userId: 'user-1',
        name: 'TestHero',
        level: 5,
        currentXP: 50,
        xpToNextLevel: 300,
        currentStreak: 7,
        longestStreak: 14,
        lastActiveDate: DateTime(2024, 1, 15),
        activityDates: [
          DateTime(2024, 1, 15),
          DateTime(2024, 1, 14),
          DateTime(2024, 1, 13),
        ],
        appearance: testAppearance,
        unlockedItems: ['item-1', 'item-2'],
        equippedItems: ['item-1'],
        badges: ['streak-7'],
      );
    });

    group('JSON Serialization', () {
      test('toJson returns correct map', () {
        final json = testHero.toJson();

        expect(json['id'], 'hero-1');
        expect(json['userId'], 'user-1');
        expect(json['name'], 'TestHero');
        expect(json['level'], 5);
        expect(json['currentXP'], 50);
        expect(json['xpToNextLevel'], 300);
        expect(json['currentStreak'], 7);
        expect(json['longestStreak'], 14);
        expect(json['unlockedItems'], ['item-1', 'item-2']);
        expect(json['equippedItems'], ['item-1']);
        expect(json['badges'], ['streak-7']);
        expect(json['appearance'], isA<Map<String, dynamic>>());
      });

      test('fromJson creates correct Hero', () {
        final json = testHero.toJson();
        final restored = Hero.fromJson(json);

        expect(restored.id, testHero.id);
        expect(restored.userId, testHero.userId);
        expect(restored.name, testHero.name);
        expect(restored.level, testHero.level);
        expect(restored.currentXP, testHero.currentXP);
        expect(restored.currentStreak, testHero.currentStreak);
        expect(restored.appearance.baseAvatar, testAppearance.baseAvatar);
      });

      test('JSON roundtrip preserves all fields', () {
        final json = testHero.toJson();
        final restored = Hero.fromJson(json);
        final jsonAgain = restored.toJson();

        expect(jsonAgain['id'], json['id']);
        expect(jsonAgain['name'], json['name']);
        expect(jsonAgain['level'], json['level']);
        expect(jsonAgain['currentXP'], json['currentXP']);
        expect(jsonAgain['unlockedItems'], json['unlockedItems']);
      });

      test('handles null lastActiveDate', () {
        final heroNoActivity = Hero(
          id: 'hero-2',
          userId: 'user-2',
          name: 'NewHero',
          xpToNextLevel: 100,
          appearance: testAppearance,
        );

        final json = heroNoActivity.toJson();
        expect(json['lastActiveDate'], isNull);

        final restored = Hero.fromJson(json);
        expect(restored.lastActiveDate, isNull);
      });

      test('serializes activityDates correctly', () {
        final json = testHero.toJson();
        expect(json['activityDates'], isA<List>());
        expect(json['activityDates'].length, 3);

        final restored = Hero.fromJson(json);
        expect(restored.activityDates.length, 3);
        expect(restored.activityDates[0], DateTime(2024, 1, 15));
      });
    });

    group('Computed Properties', () {
      test('xpProgress calculates correctly', () {
        expect(testHero.xpProgress, closeTo(50 / 300, 0.001));

        final halfProgress = testHero.copyWith(currentXP: 150);
        expect(halfProgress.xpProgress, 0.5);
      });

      test('title returns correct value for level', () {
        final novice = testHero.copyWith(level: 5);
        expect(novice.title, 'Mochi Novice');

        final apprentice = testHero.copyWith(level: 15);
        expect(apprentice.title, 'Mochi Apprentice');

        final champion = testHero.copyWith(level: 30);
        expect(champion.title, 'Mochi Champion');

        final legend = testHero.copyWith(level: 55);
        expect(legend.title, 'Mochi Legend');
      });
    });

    group('Level Calculation', () {
      test('calculateXPForLevel returns correct values', () {
        expect(Hero.calculateXPForLevel(1), 100);
        expect(Hero.calculateXPForLevel(2), 150);
        expect(Hero.calculateXPForLevel(3), 200);
        expect(Hero.calculateXPForLevel(10), 550);
      });

      test('addXP increases XP correctly', () {
        final hero = Hero(
          id: 'h-1',
          userId: 'u-1',
          name: 'Test',
          level: 1,
          currentXP: 0,
          xpToNextLevel: 100,
          appearance: testAppearance,
        );

        final afterXP = hero.addXP(50);
        expect(afterXP.currentXP, 50);
        expect(afterXP.level, 1);
      });

      test('addXP triggers level up', () {
        final hero = Hero(
          id: 'h-1',
          userId: 'u-1',
          name: 'Test',
          level: 1,
          currentXP: 0,
          xpToNextLevel: 100,
          appearance: testAppearance,
        );

        final afterLevelUp = hero.addXP(100);
        expect(afterLevelUp.level, 2);
        expect(afterLevelUp.currentXP, 0);
        expect(afterLevelUp.xpToNextLevel, 150);
      });

      test('addXP handles multiple level ups', () {
        final hero = Hero(
          id: 'h-1',
          userId: 'u-1',
          name: 'Test',
          level: 1,
          currentXP: 0,
          xpToNextLevel: 100,
          appearance: testAppearance,
        );

        // 100 XP for level 1->2, 150 XP for level 2->3
        final afterMultipleLevelUp = hero.addXP(250);
        expect(afterMultipleLevelUp.level, 3);
        expect(afterMultipleLevelUp.currentXP, 0);
        expect(afterMultipleLevelUp.xpToNextLevel, 200);
      });

      test('addXP handles overflow XP correctly', () {
        final hero = Hero(
          id: 'h-1',
          userId: 'u-1',
          name: 'Test',
          level: 1,
          currentXP: 0,
          xpToNextLevel: 100,
          appearance: testAppearance,
        );

        final afterXP = hero.addXP(175);
        expect(afterXP.level, 2);
        expect(afterXP.currentXP, 75);
        expect(afterXP.xpToNextLevel, 150);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updated = testHero.copyWith(
          name: 'UpdatedHero',
          level: 10,
          currentStreak: 15,
        );

        expect(updated.name, 'UpdatedHero');
        expect(updated.level, 10);
        expect(updated.currentStreak, 15);
        expect(updated.id, testHero.id);
        expect(updated.userId, testHero.userId);
      });

      test('can update appearance', () {
        final newAppearance = testAppearance.copyWith(
          hairColor: 'red',
        );

        final updated = testHero.copyWith(appearance: newAppearance);
        expect(updated.appearance.hairColor, 'red');
        expect(updated.appearance.skinColor, testAppearance.skinColor);
      });

      test('can update lists', () {
        final updated = testHero.copyWith(
          unlockedItems: ['item-1', 'item-2', 'item-3'],
          badges: ['streak-7', 'streak-14'],
        );

        expect(updated.unlockedItems.length, 3);
        expect(updated.badges.length, 2);
      });
    });

    group('Edge Cases', () {
      test('handles empty lists', () {
        final hero = Hero(
          id: 'h-1',
          userId: 'u-1',
          name: 'New',
          xpToNextLevel: 100,
          appearance: testAppearance,
        );

        expect(hero.activityDates, isEmpty);
        expect(hero.unlockedItems, isEmpty);
        expect(hero.equippedItems, isEmpty);
        expect(hero.badges, isEmpty);

        final json = hero.toJson();
        final restored = Hero.fromJson(json);

        expect(restored.activityDates, isEmpty);
        expect(restored.unlockedItems, isEmpty);
      });

      test('defaults are applied correctly', () {
        final hero = Hero(
          id: 'h-1',
          userId: 'u-1',
          name: 'New',
          xpToNextLevel: 100,
          appearance: testAppearance,
        );

        expect(hero.level, 1);
        expect(hero.currentXP, 0);
        expect(hero.currentStreak, 0);
        expect(hero.longestStreak, 0);
      });
    });
  });
}
