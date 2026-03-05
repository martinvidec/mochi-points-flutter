import '../models/achievement.dart';
import '../models/enums.dart';

/// Default achievements for Mochi Points
/// 15 achievements across 4 categories with mixed tiers
/// Includes 2 secret achievements (Frühaufsteher, Nachtaktiv)
const List<Achievement> defaultAchievements = [
  // ============================================
  // STREAK ACHIEVEMENTS (4)
  // ============================================
  Achievement(
    id: 'streak_7',
    name: 'Feuerstarter',
    description: 'Halte einen Streak von 7 Tagen',
    icon: 'fire',
    tier: AchievementTier.bronze,
    category: AchievementCategory.streak,
    condition: 'streak_days',
    targetValue: 7,
    rewardXP: 50,
    rewardPoints: 10,
  ),
  Achievement(
    id: 'streak_14',
    name: 'Flammenmeister',
    description: 'Halte einen Streak von 14 Tagen',
    icon: 'fire',
    tier: AchievementTier.silver,
    category: AchievementCategory.streak,
    condition: 'streak_days',
    targetValue: 14,
    rewardXP: 100,
    rewardPoints: 25,
  ),
  Achievement(
    id: 'streak_30',
    name: 'Unaufhaltsam',
    description: 'Halte einen Streak von 30 Tagen',
    icon: 'fitness',
    tier: AchievementTier.gold,
    category: AchievementCategory.streak,
    condition: 'streak_days',
    targetValue: 30,
    rewardXP: 250,
    rewardPoints: 50,
  ),
  Achievement(
    id: 'streak_100',
    name: 'Legende',
    description: 'Halte einen Streak von 100 Tagen',
    icon: 'crown',
    tier: AchievementTier.platinum,
    category: AchievementCategory.streak,
    condition: 'streak_days',
    targetValue: 100,
    rewardXP: 500,
    rewardPoints: 100,
  ),

  // ============================================
  // QUEST ACHIEVEMENTS (4)
  // ============================================
  Achievement(
    id: 'quests_1',
    name: 'Erster Schritt',
    description: 'Schließe deine erste Quest ab',
    icon: 'star',
    tier: AchievementTier.bronze,
    category: AchievementCategory.quests,
    condition: 'quests_completed',
    targetValue: 1,
    rewardXP: 25,
    rewardPoints: 5,
  ),
  Achievement(
    id: 'quests_50',
    name: 'Fleißige Biene',
    description: 'Schließe 50 Quests ab',
    icon: 'bee',
    tier: AchievementTier.silver,
    category: AchievementCategory.quests,
    condition: 'quests_completed',
    targetValue: 50,
    rewardXP: 150,
    rewardPoints: 30,
  ),
  Achievement(
    id: 'quests_100',
    name: 'Quest-Meister',
    description: 'Schließe 100 Quests ab',
    icon: 'trophy',
    tier: AchievementTier.gold,
    category: AchievementCategory.quests,
    condition: 'quests_completed',
    targetValue: 100,
    rewardXP: 300,
    rewardPoints: 75,
  ),
  Achievement(
    id: 'epic_quest_1',
    name: 'Held',
    description: 'Schließe eine epische Quest ab',
    icon: 'hero',
    tier: AchievementTier.gold,
    category: AchievementCategory.quests,
    condition: 'epic_quests_completed',
    targetValue: 1,
    rewardXP: 200,
    rewardPoints: 50,
  ),

  // ============================================
  // POINTS ACHIEVEMENTS (3)
  // ============================================
  Achievement(
    id: 'points_100',
    name: 'Sammler',
    description: 'Verdiene insgesamt 100 Mochi Points',
    icon: 'coins',
    tier: AchievementTier.bronze,
    category: AchievementCategory.points,
    condition: 'total_points_earned',
    targetValue: 100,
    rewardXP: 50,
    rewardPoints: 10,
  ),
  Achievement(
    id: 'points_500',
    name: 'Schatzjäger',
    description: 'Verdiene insgesamt 500 Mochi Points',
    icon: 'diamond',
    tier: AchievementTier.silver,
    category: AchievementCategory.points,
    condition: 'total_points_earned',
    targetValue: 500,
    rewardXP: 150,
    rewardPoints: 25,
  ),
  Achievement(
    id: 'points_1000',
    name: 'Goldgrube',
    description: 'Verdiene insgesamt 1000 Mochi Points',
    icon: 'medal',
    tier: AchievementTier.gold,
    category: AchievementCategory.points,
    condition: 'total_points_earned',
    targetValue: 1000,
    rewardXP: 300,
    rewardPoints: 50,
  ),

  // ============================================
  // SPECIAL ACHIEVEMENTS (4)
  // ============================================
  Achievement(
    id: 'first_purchase',
    name: 'Shopper',
    description: 'Kaufe deine erste Belohnung',
    icon: 'cart',
    tier: AchievementTier.bronze,
    category: AchievementCategory.special,
    condition: 'rewards_purchased',
    targetValue: 1,
    rewardXP: 25,
    rewardPoints: 5,
  ),
  Achievement(
    id: 'early_bird',
    name: 'Frühaufsteher',
    description: 'Schließe eine Quest vor 7 Uhr morgens ab',
    icon: 'sunrise',
    tier: AchievementTier.silver,
    category: AchievementCategory.special,
    condition: 'quest_before_7am',
    targetValue: 1,
    rewardXP: 100,
    rewardPoints: 20,
    isSecret: true,
  ),
  Achievement(
    id: 'night_owl',
    name: 'Nachtaktiv',
    description: 'Schließe eine Quest nach 22 Uhr ab',
    icon: 'owl',
    tier: AchievementTier.silver,
    category: AchievementCategory.special,
    condition: 'quest_after_10pm',
    targetValue: 1,
    rewardXP: 100,
    rewardPoints: 20,
    isSecret: true,
  ),
  Achievement(
    id: 'perfect_week',
    name: 'Perfekte Woche',
    description: 'Schließe 7 Tage lang alle täglichen Quests ab',
    icon: 'sparkle',
    tier: AchievementTier.gold,
    category: AchievementCategory.special,
    condition: 'perfect_daily_week',
    targetValue: 7,
    rewardXP: 250,
    rewardPoints: 50,
  ),
];

/// Get achievement by ID
Achievement? getAchievementById(String id) {
  try {
    return defaultAchievements.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
}

/// Get achievements by category
List<Achievement> getAchievementsByCategory(AchievementCategory category) {
  return defaultAchievements.where((a) => a.category == category).toList();
}

/// Get achievements by tier
List<Achievement> getAchievementsByTier(AchievementTier tier) {
  return defaultAchievements.where((a) => a.tier == tier).toList();
}

/// Get all non-secret achievements
List<Achievement> getVisibleAchievements() {
  return defaultAchievements.where((a) => !a.isSecret).toList();
}

/// Get all secret achievements
List<Achievement> getSecretAchievements() {
  return defaultAchievements.where((a) => a.isSecret).toList();
}
