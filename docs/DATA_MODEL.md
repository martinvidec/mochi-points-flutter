# Mochi Points - Datenmodell

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ENTITY RELATIONSHIPS                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                              ┌──────────────┐                               │
│                              │    Family    │                               │
│                              │──────────────│                               │
│                              │ id           │                               │
│                              │ name         │                               │
│                              │ createdAt    │                               │
│                              └──────┬───────┘                               │
│                                     │                                       │
│                                     │ 1:N                                   │
│                                     │                                       │
│                              ┌──────▼───────┐                               │
│                              │     User     │                               │
│                              │──────────────│                               │
│                              │ id           │                               │
│                              │ familyId     │───────────────────────┐       │
│                              │ name         │                       │       │
│                              │ email        │                       │       │
│                              │ role         │                       │       │
│                              │ avatarUrl    │                       │       │
│                              └──────┬───────┘                       │       │
│                                     │                               │       │
│               ┌─────────────────────┼─────────────────────┐         │       │
│               │                     │                     │         │       │
│               │ 1:1 (child only)    │ 1:N                 │ 1:N     │       │
│               │                     │                     │         │       │
│        ┌──────▼───────┐      ┌──────▼───────┐      ┌──────▼───────┐ │       │
│        │     Hero     │      │    Quest     │      │   Reward     │ │       │
│        │──────────────│      │──────────────│      │──────────────│ │       │
│        │ id           │      │ id           │      │ id           │ │       │
│        │ userId       │      │ familyId     │◄─────│ familyId     │─┘       │
│        │ level        │      │ createdBy    │      │ createdBy    │         │
│        │ currentXP    │      │ name         │      │ name         │         │
│        │ streak       │      │ type         │      │ description  │         │
│        │ items[]      │      │ rarity       │      │ price        │         │
│        │ badges[]     │      │ reward       │      │ icon         │         │
│        └──────┬───────┘      │ assignedTo[] │      │ category     │         │
│               │              │ status       │      │ stock        │         │
│               │              └──────┬───────┘      └──────┬───────┘         │
│               │                     │                     │                 │
│               │ 1:N                 │ 1:N                 │ 1:N             │
│               │                     │                     │                 │
│        ┌──────▼───────┐      ┌──────▼───────┐      ┌──────▼───────┐         │
│        │ Achievement  │      │QuestInstance │      │   Purchase   │         │
│        │   Unlock     │      │──────────────│      │──────────────│         │
│        │──────────────│      │ id           │      │ id           │         │
│        │ id           │      │ questId      │      │ rewardId     │         │
│        │ heroId       │      │ childId      │      │ userId       │         │
│        │ achievementId│      │ status       │      │ quantity     │         │
│        │ unlockedAt   │      │ progress     │      │ totalPrice   │         │
│        └──────────────┘      │ startedAt    │      │ status       │         │
│                              │ completedAt  │      │ purchasedAt  │         │
│                              │ approvedAt   │      │ redeemedAt   │         │
│                              └──────────────┘      └──────────────┘         │
│                                                                             │
│                              ┌──────────────┐                               │
│                              │  Transaction │                               │
│                              │──────────────│                               │
│                              │ id           │                               │
│                              │ userId       │                               │
│                              │ type         │  (quest_complete, purchase,   │
│                              │ amount       │   bonus, adjustment)          │
│                              │ balance      │                               │
│                              │ reference    │                               │
│                              │ createdAt    │                               │
│                              └──────────────┘                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Dart Models

### User & Authentication

```dart
enum UserRole { parent, child }

class Family {
  final String id;
  final String name;
  final String? inviteCode;
  final DateTime createdAt;

  Family({
    required this.id,
    required this.name,
    this.inviteCode,
    required this.createdAt,
  });
}

class User {
  final String id;
  final String familyId;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.familyId,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;
}
```

### Hero System

```dart
class Hero {
  final String id;
  final String userId;
  final String name;
  final int level;
  final int currentXP;
  final int xpToNextLevel;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final HeroAppearance appearance;
  final List<String> unlockedItems;
  final List<String> equippedItems;
  final List<String> badges;

  Hero({
    required this.id,
    required this.userId,
    required this.name,
    this.level = 1,
    this.currentXP = 0,
    this.xpToNextLevel = 100,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    required this.appearance,
    this.unlockedItems = const [],
    this.equippedItems = const [],
    this.badges = const [],
  });

  double get xpProgress => currentXP / xpToNextLevel;

  String get title => _getTitleForLevel(level);

  static String _getTitleForLevel(int level) {
    if (level < 10) return 'Mochi Novice';
    if (level < 25) return 'Mochi Apprentice';
    if (level < 50) return 'Mochi Champion';
    return 'Mochi Legend';
  }

  Hero addXP(int xp) {
    int newXP = currentXP + xp;
    int newLevel = level;
    int newXPToNext = xpToNextLevel;

    while (newXP >= newXPToNext) {
      newXP -= newXPToNext;
      newLevel++;
      newXPToNext = _calculateXPForLevel(newLevel);
    }

    return copyWith(
      level: newLevel,
      currentXP: newXP,
      xpToNextLevel: newXPToNext,
    );
  }

  static int _calculateXPForLevel(int level) {
    return 100 + (level - 1) * 50; // 100, 150, 200, 250...
  }
}

class HeroAppearance {
  final String baseAvatar;
  final String skinColor;
  final String hairStyle;
  final String hairColor;
  final String outfit;
  final String? accessory;
  final String? pet;

  HeroAppearance({
    required this.baseAvatar,
    required this.skinColor,
    required this.hairStyle,
    required this.hairColor,
    required this.outfit,
    this.accessory,
    this.pet,
  });
}
```

### Quest System

```dart
enum QuestType { daily, weekly, epic, series }
enum QuestRarity { common, rare, epic, legendary }
enum QuestStatus { available, inProgress, pendingApproval, completed, expired }

class Quest {
  final String id;
  final String familyId;
  final String createdBy;
  final String name;
  final String? description;
  final String icon;
  final QuestType type;
  final QuestRarity rarity;
  final int rewardPoints;
  final int rewardXP;
  final List<String> assignedTo; // User IDs, empty = all children
  final DateTime? deadline;
  final bool isActive;
  final DateTime createdAt;

  // Series quest specific
  final int? targetCount; // null = unlimited
  final String? unit; // "km", "Minuten", "Seiten"

  Quest({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.name,
    this.description,
    required this.icon,
    required this.type,
    this.rarity = QuestRarity.common,
    required this.rewardPoints,
    this.rewardXP = 0,
    this.assignedTo = const [],
    this.deadline,
    this.isActive = true,
    required this.createdAt,
    this.targetCount,
    this.unit,
  });

  bool get isSeries => type == QuestType.series;
  bool get hasDeadline => deadline != null;
  bool get isExpired => deadline != null && DateTime.now().isAfter(deadline!);

  Color get rarityColor {
    switch (rarity) {
      case QuestRarity.common: return const Color(0xFFB8B8B8);
      case QuestRarity.rare: return const Color(0xFF4A9DFF);
      case QuestRarity.epic: return const Color(0xFFA855F7);
      case QuestRarity.legendary: return const Color(0xFFF59E0B);
    }
  }
}

class QuestInstance {
  final String id;
  final String questId;
  final String childId;
  final QuestStatus status;
  final int progress; // für Series: Anzahl, für andere: 0 oder 1
  final int target;   // für Series: Ziel, für andere: 1
  final int currentStreak;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime createdAt;

  QuestInstance({
    required this.id,
    required this.questId,
    required this.childId,
    this.status = QuestStatus.available,
    this.progress = 0,
    this.target = 1,
    this.currentStreak = 0,
    this.startedAt,
    this.completedAt,
    this.approvedAt,
    this.approvedBy,
    required this.createdAt,
  });

  double get progressPercent => target > 0 ? progress / target : 0;
  bool get isComplete => progress >= target;
  bool get isPending => status == QuestStatus.pendingApproval;
}
```

### Reward System

```dart
enum RewardCategory { experience, item, privilege, custom }
enum PurchaseStatus { purchased, redeemed, expired, cancelled }

class Reward {
  final String id;
  final String familyId;
  final String createdBy;
  final String name;
  final String? description;
  final String icon;
  final int price;
  final RewardCategory category;
  final int? stock; // null = unlimited
  final bool isActive;
  final DateTime createdAt;

  Reward({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.name,
    this.description,
    required this.icon,
    required this.price,
    this.category = RewardCategory.custom,
    this.stock,
    this.isActive = true,
    required this.createdAt,
  });

  bool get hasLimitedStock => stock != null;
  bool get isAvailable => isActive && (stock == null || stock! > 0);
}

class Purchase {
  final String id;
  final String rewardId;
  final String userId;
  final int quantity;
  final int totalPrice;
  final PurchaseStatus status;
  final DateTime purchasedAt;
  final DateTime? redeemedAt;
  final String? redeemedBy; // Parent who confirmed redemption

  Purchase({
    required this.id,
    required this.rewardId,
    required this.userId,
    this.quantity = 1,
    required this.totalPrice,
    this.status = PurchaseStatus.purchased,
    required this.purchasedAt,
    this.redeemedAt,
    this.redeemedBy,
  });

  bool get isRedeemed => status == PurchaseStatus.redeemed;
  bool get canRedeem => status == PurchaseStatus.purchased;
}
```

### Points & Transactions

```dart
enum TransactionType {
  questComplete,   // Earned from quest
  purchase,        // Spent on reward
  bonus,           // Streak bonus, achievement bonus
  adjustment,      // Manual adjustment by parent
  refund,          // Cancelled purchase
}

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount; // positive = earned, negative = spent
  final int balanceAfter;
  final String? referenceId; // questInstanceId, purchaseId, etc.
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  bool get isEarned => amount > 0;
  bool get isSpent => amount < 0;
}

class PointsAccount {
  final String userId;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final DateTime lastUpdated;

  PointsAccount({
    required this.userId,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    required this.lastUpdated,
  });

  bool canAfford(int price) => balance >= price;

  PointsAccount earn(int amount) => copyWith(
    balance: balance + amount,
    totalEarned: totalEarned + amount,
    lastUpdated: DateTime.now(),
  );

  PointsAccount spend(int amount) => copyWith(
    balance: balance - amount,
    totalSpent: totalSpent + amount,
    lastUpdated: DateTime.now(),
  );
}
```

### Achievement System

```dart
enum AchievementTier { bronze, silver, gold, platinum }
enum AchievementCategory { streak, quests, points, special }

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementTier tier;
  final AchievementCategory category;
  final String condition; // JSON encoded condition
  final int? targetValue;
  final int rewardXP;
  final int? rewardPoints;
  final String? rewardItem;
  final bool isSecret;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.category,
    required this.condition,
    this.targetValue,
    this.rewardXP = 0,
    this.rewardPoints,
    this.rewardItem,
    this.isSecret = false,
  });

  Color get tierColor {
    switch (tier) {
      case AchievementTier.bronze: return const Color(0xFFCD7F32);
      case AchievementTier.silver: return const Color(0xFFC0C0C0);
      case AchievementTier.gold: return const Color(0xFFFFD700);
      case AchievementTier.platinum: return const Color(0xFFE5E4E2);
    }
  }
}

class AchievementProgress {
  final String id;
  final String heroId;
  final String achievementId;
  final int currentProgress;
  final int targetProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AchievementProgress({
    required this.id,
    required this.heroId,
    required this.achievementId,
    this.currentProgress = 0,
    required this.targetProgress,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  double get progressPercent =>
    targetProgress > 0 ? currentProgress / targetProgress : 0;
}
```

---

## Predefined Achievements

```dart
final List<Achievement> defaultAchievements = [
  // Streak Achievements
  Achievement(
    id: 'streak_7',
    name: 'Feuerstarter',
    description: '7 Tage Streak erreichen',
    icon: '🔥',
    tier: AchievementTier.bronze,
    category: AchievementCategory.streak,
    condition: 'streak >= 7',
    targetValue: 7,
    rewardXP: 50,
  ),
  Achievement(
    id: 'streak_14',
    name: 'Flammenmeister',
    description: '14 Tage Streak erreichen',
    icon: '🔥',
    tier: AchievementTier.silver,
    category: AchievementCategory.streak,
    condition: 'streak >= 14',
    targetValue: 14,
    rewardXP: 100,
    rewardPoints: 10,
  ),
  Achievement(
    id: 'streak_30',
    name: 'Unaufhaltsam',
    description: '30 Tage Streak erreichen',
    icon: '🔥',
    tier: AchievementTier.gold,
    category: AchievementCategory.streak,
    condition: 'streak >= 30',
    targetValue: 30,
    rewardXP: 250,
    rewardPoints: 25,
    rewardItem: 'flame_aura',
  ),
  Achievement(
    id: 'streak_100',
    name: 'Legende',
    description: '100 Tage Streak erreichen',
    icon: '👑',
    tier: AchievementTier.platinum,
    category: AchievementCategory.streak,
    condition: 'streak >= 100',
    targetValue: 100,
    rewardXP: 1000,
    rewardPoints: 100,
    rewardItem: 'legendary_crown',
  ),

  // Quest Achievements
  Achievement(
    id: 'quest_first',
    name: 'Erster Schritt',
    description: 'Erste Quest abschließen',
    icon: '🌟',
    tier: AchievementTier.bronze,
    category: AchievementCategory.quests,
    condition: 'quests_completed >= 1',
    targetValue: 1,
    rewardXP: 25,
  ),
  Achievement(
    id: 'quest_50',
    name: 'Fleißige Biene',
    description: '50 Quests abschließen',
    icon: '🐝',
    tier: AchievementTier.silver,
    category: AchievementCategory.quests,
    condition: 'quests_completed >= 50',
    targetValue: 50,
    rewardXP: 150,
    rewardPoints: 15,
  ),
  Achievement(
    id: 'quest_epic_first',
    name: 'Held',
    description: 'Erste Epic Quest abschließen',
    icon: '⚔️',
    tier: AchievementTier.gold,
    category: AchievementCategory.quests,
    condition: 'epic_quests_completed >= 1',
    targetValue: 1,
    rewardXP: 200,
    rewardPoints: 20,
  ),

  // Points Achievements
  Achievement(
    id: 'points_100',
    name: 'Sammler',
    description: '100 Mochi Points verdienen',
    icon: '💰',
    tier: AchievementTier.bronze,
    category: AchievementCategory.points,
    condition: 'total_points >= 100',
    targetValue: 100,
    rewardXP: 50,
  ),
  Achievement(
    id: 'points_1000',
    name: 'Schatzjäger',
    description: '1000 Mochi Points verdienen',
    icon: '💎',
    tier: AchievementTier.gold,
    category: AchievementCategory.points,
    condition: 'total_points >= 1000',
    targetValue: 1000,
    rewardXP: 300,
    rewardItem: 'golden_mochi',
  ),

  // Special/Secret Achievements
  Achievement(
    id: 'secret_midnight',
    name: 'Nachtaktiv',
    description: 'Quest nach Mitternacht abschließen',
    icon: '🌙',
    tier: AchievementTier.silver,
    category: AchievementCategory.special,
    condition: 'quest_completed_after_midnight',
    rewardXP: 75,
    isSecret: true,
  ),
  Achievement(
    id: 'secret_weekend',
    name: 'Wochenend-Krieger',
    description: '10 Quests an Wochenenden abschließen',
    icon: '🎉',
    tier: AchievementTier.silver,
    category: AchievementCategory.special,
    condition: 'weekend_quests >= 10',
    targetValue: 10,
    rewardXP: 100,
    isSecret: true,
  ),
];
```

---

## XP & Level Calculation

```dart
class LevelSystem {
  /// XP needed for each level (cumulative)
  /// Level 1: 0 XP
  /// Level 2: 100 XP
  /// Level 3: 250 XP (100 + 150)
  /// Level 4: 450 XP (250 + 200)
  /// etc.

  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return xpForLevel(level - 1) + xpBetweenLevels(level - 1);
  }

  static int xpBetweenLevels(int fromLevel) {
    // Base: 100, increases by 50 each level
    return 100 + (fromLevel - 1) * 50;
  }

  static int levelForXP(int totalXP) {
    int level = 1;
    int xpNeeded = 0;

    while (xpNeeded <= totalXP) {
      level++;
      xpNeeded = xpForLevel(level);
    }

    return level - 1;
  }

  static int xpProgressInCurrentLevel(int totalXP) {
    int currentLevel = levelForXP(totalXP);
    return totalXP - xpForLevel(currentLevel);
  }

  static double progressToNextLevel(int totalXP) {
    int currentLevel = levelForXP(totalXP);
    int progressInLevel = xpProgressInCurrentLevel(totalXP);
    int xpNeeded = xpBetweenLevels(currentLevel);
    return progressInLevel / xpNeeded;
  }
}
```

---

## Streak Calculation

```dart
class StreakSystem {
  /// Calculate streak based on activity history
  static int calculateStreak(List<DateTime> activityDates) {
    if (activityDates.isEmpty) return 0;

    final sortedDates = activityDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    // Must have activity today or yesterday to have active streak
    if (sortedDates.first != todayDate && sortedDates.first != yesterday) {
      return 0;
    }

    int streak = 1;
    DateTime currentDate = sortedDates.first;

    for (int i = 1; i < sortedDates.length; i++) {
      final expectedPrevious = currentDate.subtract(const Duration(days: 1));
      if (sortedDates[i] == expectedPrevious) {
        streak++;
        currentDate = sortedDates[i];
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate streak bonus multiplier
  static double streakBonusMultiplier(int streak) {
    if (streak < 7) return 1.0;
    if (streak < 14) return 1.1;  // +10%
    if (streak < 30) return 1.15; // +15%
    if (streak < 100) return 1.25; // +25%
    return 1.5; // +50%
  }

  /// Check if streak milestone reached
  static int? streakMilestone(int oldStreak, int newStreak) {
    const milestones = [7, 14, 30, 60, 100, 365];
    for (final milestone in milestones) {
      if (oldStreak < milestone && newStreak >= milestone) {
        return milestone;
      }
    }
    return null;
  }
}
```

---

## Provider Structure

```dart
// lib/providers/

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  Family? _currentFamily;

  User? get currentUser => _currentUser;
  Family? get currentFamily => _currentFamily;
  bool get isLoggedIn => _currentUser != null;
  bool get isParent => _currentUser?.isParent ?? false;
  bool get isChild => _currentUser?.isChild ?? false;
}

class HeroProvider extends ChangeNotifier {
  Hero? _hero;
  List<AchievementProgress> _achievements = [];

  Hero? get hero => _hero;
  int get level => _hero?.level ?? 1;
  int get streak => _hero?.currentStreak ?? 0;
  List<AchievementProgress> get achievements => _achievements;

  Future<void> addXP(int xp);
  Future<void> updateStreak();
  Future<void> checkAchievements();
}

class QuestProvider extends ChangeNotifier {
  List<Quest> _quests = [];
  List<QuestInstance> _instances = [];

  List<Quest> get availableQuests;
  List<QuestInstance> get activeQuests;
  List<QuestInstance> get pendingApproval;

  Future<void> createQuest(Quest quest);
  Future<void> acceptQuest(String questId);
  Future<void> completeQuest(String instanceId);
  Future<void> approveQuest(String instanceId);
}

class PointsProvider extends ChangeNotifier {
  PointsAccount? _account;
  List<Transaction> _transactions = [];

  int get balance => _account?.balance ?? 0;
  List<Transaction> get transactions => _transactions;

  Future<void> earn(int amount, TransactionType type, String? referenceId);
  Future<void> spend(int amount, String referenceId);
}

class RewardProvider extends ChangeNotifier {
  List<Reward> _rewards = [];
  List<Purchase> _purchases = [];

  List<Reward> get availableRewards;
  List<Purchase> get myPurchases;
  List<Purchase> get pendingRedemptions;

  Future<void> createReward(Reward reward);
  Future<void> purchaseReward(String rewardId);
  Future<void> redeemPurchase(String purchaseId);
}
```

---

## Summary

Dieses Datenmodell unterstützt:

- **Multi-User Familien** mit Parent/Child Rollen
- **Flexibles Quest-System** mit 4 Typen und 4 Raritäten
- **Hero-Progression** mit Levels, XP und Customization
- **Streak-Tracking** mit Bonus-Multiplikatoren
- **Achievement-System** mit Tiers und Rewards
- **Vollständige Transaktionshistorie** für Punkte
- **Reward-Shop** mit Käufen und Einlösungen
