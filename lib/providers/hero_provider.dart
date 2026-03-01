import 'package:flutter/foundation.dart';
import '../models/hero.dart';
import '../services/storage_service.dart';

typedef LevelUpCallback = void Function(String userId, int oldLevel, int newLevel);

class HeroProvider extends ChangeNotifier {
  Map<String, Hero> _heroes = {};
  String? _currentUserId;

  Map<String, Hero> get heroes => Map.unmodifiable(_heroes);

  static const String _heroesKey = 'heroes';

  // Callbacks
  LevelUpCallback? onLevelUp;

  // Getters
  Hero? get currentHero {
    if (_currentUserId == null) return null;
    return _heroes[_currentUserId];
  }

  Hero? heroForUser(String userId) => _heroes[userId];

  // Set current user (called when user logs in)
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // Load from storage
  Future<void> loadData() async {
    try {
      final heroesList = await StorageService.loadList(
        _heroesKey,
        Hero.fromJson,
      );
      _heroes = {for (var hero in heroesList) hero.userId: hero};
      notifyListeners();
    } catch (e) {
      debugPrint('HeroProvider.loadData error: $e');
    }
  }

  // Initialize hero for user
  Future<Hero> initialize(String userId, String name) async {
    if (_heroes.containsKey(userId)) {
      return _heroes[userId]!;
    }

    final hero = Hero(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      level: 1,
      currentXP: 0,
      xpToNextLevel: Hero.calculateXPForLevel(1),
      appearance: const HeroAppearance(
        baseAvatar: 'default',
        skinColor: 'light',
        hairStyle: 'short',
        hairColor: 'brown',
        outfit: 'casual',
      ),
    );

    _heroes[userId] = hero;
    await _saveHeroes();
    notifyListeners();

    return hero;
  }

  // Add XP and check for level up
  Future<bool> addXP(String userId, int amount) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      final oldLevel = hero.level;
      final updatedHero = hero.addXP(amount);
      _heroes[userId] = updatedHero;

      // Check for level up
      if (updatedHero.level > oldLevel) {
        onLevelUp?.call(userId, oldLevel, updatedHero.level);
      }

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.addXP error: $e');
      return false;
    }
  }

  // Update streak
  Future<bool> updateStreak(String userId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActive = hero.lastActiveDate;

      int newStreak = hero.currentStreak;
      int newLongestStreak = hero.longestStreak;

      if (lastActive == null) {
        // First activity
        newStreak = 1;
      } else {
        final lastActiveDay = DateTime(
          lastActive.year,
          lastActive.month,
          lastActive.day,
        );
        final daysDifference = today.difference(lastActiveDay).inDays;

        if (daysDifference == 0) {
          // Same day, no change
          return true;
        } else if (daysDifference == 1) {
          // Consecutive day
          newStreak = hero.currentStreak + 1;
        } else {
          // Streak broken
          newStreak = 1;
        }
      }

      // Update longest streak
      if (newStreak > newLongestStreak) {
        newLongestStreak = newStreak;
      }

      _heroes[userId] = hero.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        lastActiveDate: now,
      );

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.updateStreak error: $e');
      return false;
    }
  }

  // Equip item
  Future<bool> equipItem(String userId, String itemId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      // Check if item is unlocked
      if (!hero.unlockedItems.contains(itemId)) return false;

      // Check if already equipped
      if (hero.equippedItems.contains(itemId)) return true;

      final updatedItems = [...hero.equippedItems, itemId];
      _heroes[userId] = hero.copyWith(equippedItems: updatedItems);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.equipItem error: $e');
      return false;
    }
  }

  // Unequip item
  Future<bool> unequipItem(String userId, String itemId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      if (!hero.equippedItems.contains(itemId)) return true;

      final updatedItems = hero.equippedItems.where((i) => i != itemId).toList();
      _heroes[userId] = hero.copyWith(equippedItems: updatedItems);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.unequipItem error: $e');
      return false;
    }
  }

  // Unlock item
  Future<bool> unlockItem(String userId, String itemId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      if (hero.unlockedItems.contains(itemId)) return true;

      final updatedItems = [...hero.unlockedItems, itemId];
      _heroes[userId] = hero.copyWith(unlockedItems: updatedItems);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.unlockItem error: $e');
      return false;
    }
  }

  // Add badge
  Future<bool> addBadge(String userId, String badgeId) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      if (hero.badges.contains(badgeId)) return true;

      final updatedBadges = [...hero.badges, badgeId];
      _heroes[userId] = hero.copyWith(badges: updatedBadges);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.addBadge error: $e');
      return false;
    }
  }

  // Update appearance
  Future<bool> updateAppearance(String userId, HeroAppearance appearance) async {
    try {
      final hero = _heroes[userId];
      if (hero == null) return false;

      _heroes[userId] = hero.copyWith(appearance: appearance);

      await _saveHeroes();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('HeroProvider.updateAppearance error: $e');
      return false;
    }
  }

  // Persistence
  Future<void> _saveHeroes() async {
    await StorageService.saveList(
      _heroesKey,
      _heroes.values.toList(),
      (h) => h.toJson(),
    );
  }
}
