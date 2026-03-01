# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Vision

**Mochi Points** is a gamified family rewards app where parents create challenges and rewards, and children earn Mochi Points by completing quests. The app transforms household chores into an engaging gaming experience with levels, streaks, achievements, and a customizable avatar system.

### Core Concept
- **Parents (Quest Masters)**: Create quests, set up rewards, approve completed quests
- **Children (Mochi Heroes)**: Accept quests, earn points, level up, buy rewards
- **Gamification**: XP, levels, streaks, achievements, avatar customization

See `/docs/MVP_CONCEPT.md` for the full product specification.

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run the app on Chrome
flutter run -d chrome

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code (linting)
flutter analyze

# Build for release
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

## Architecture Overview

### Tech Stack
- **Framework**: Flutter 3.41.2+ with Dart 3.11.0+
- **State Management**: Provider pattern with ChangeNotifier
- **Storage**: SharedPreferences (MVP), planned migration to Firebase/Supabase
- **UI Theme**: Dark gaming theme with Material 3

### Project Structure

```
lib/
├── main.dart                 # App entry point, provider setup
├── models/                   # Data models
│   ├── quest.dart           # Quest, QuestInstance
│   ├── hero.dart            # Hero, HeroAppearance
│   ├── reward.dart          # Reward, Purchase
│   ├── achievement.dart     # Achievement, AchievementProgress
│   └── transaction.dart     # Transaction, PointsAccount
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── hero_provider.dart
│   ├── quest_provider.dart
│   ├── points_provider.dart
│   └── reward_provider.dart
├── pages/                   # Full-screen views
│   ├── hero_home_page.dart  # Child dashboard
│   ├── quest_board_page.dart
│   ├── shop_page.dart
│   ├── parent_dashboard_page.dart
│   └── ...
├── widgets/                 # Reusable components
│   ├── hero_card.dart
│   ├── quest_card.dart
│   ├── progress_bar.dart
│   ├── achievement_badge.dart
│   └── ...
└── services/               # Business logic, API calls
    ├── storage_service.dart
    ├── streak_service.dart
    └── level_service.dart

docs/
├── MVP_CONCEPT.md          # Product specification
├── UI_DESIGN.md            # Design system & components
└── DATA_MODEL.md           # Data models & relationships
```

### State Management Pattern

All providers extend `ChangeNotifier` and are registered in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => HeroProvider()),
    ChangeNotifierProvider(create: (_) => QuestProvider()),
    ChangeNotifierProvider(create: (_) => PointsProvider()),
    ChangeNotifierProvider(create: (_) => RewardProvider()),
  ],
  child: MochiPointsApp(),
)
```

### Data Flow

```
Quest Created (Parent)
        ↓
Quest Available (Child sees it)
        ↓
Quest Accepted (Child starts)
        ↓
Quest Completed (Child marks done)
        ↓
Pending Approval (Parent notified)
        ↓
Quest Approved (Parent confirms)
        ↓
Points + XP Awarded → Level Check → Achievement Check → Streak Update
```

### Key Models

| Model | Purpose |
|-------|---------|
| `Quest` | Template for tasks with type, rarity, rewards |
| `QuestInstance` | Specific quest assigned to a child with progress |
| `Hero` | Child's avatar with level, XP, streak, items |
| `Reward` | Purchasable item/experience created by parents |
| `Achievement` | Unlockable badge with conditions |
| `Transaction` | Point earning/spending record |

See `/docs/DATA_MODEL.md` for complete model definitions.

### Theme & Colors (New Gaming Theme)

```dart
// Gaming Theme Colors
Primary Gradient: #FF6B6B → #FF8E53 (Coral to Orange)
Accent Gold:      #FFE66D (Mochi Points)
Success Teal:     #4ECDC4 (Quest Complete)
Background:       #1A1B2E → #2D2E4A (Dark gradient)
Surface:          #2A2B42 (Cards)

// Rarity Colors
Common:    #B8B8B8 (Gray)
Rare:      #4A9DFF (Blue)
Epic:      #A855F7 (Purple)
Legendary: #F59E0B (Gold)
```

See `/docs/UI_DESIGN.md` for complete design system.

## Development Guidelines

### Gamification Principles
1. **Instant Feedback**: Every action has visible/audible response
2. **Progress Everywhere**: Show XP bars, streaks, completion percentages
3. **Celebration Moments**: Confetti, sounds, animations for achievements
4. **Clear Progression**: Visible path from current level to next

### Animation Standards
```dart
const Duration fast = Duration(milliseconds: 150);
const Duration normal = Duration(milliseconds: 300);
const Duration slow = Duration(milliseconds: 500);

const Curve bounce = Curves.elasticOut;
const Curve smooth = Curves.easeInOut;
```

### Code Style
- Use `const` constructors where possible
- Prefer composition over inheritance
- Keep widgets small and focused
- Use meaningful variable names (German UI, English code)

## Current Status

**Phase**: MVP Development
**Current Features**: Basic quest/reward CRUD, navigation
**Next Steps**: User authentication, quest workflow, hero system

## Documentation

- `/docs/MVP_CONCEPT.md` - Full product specification with gamification features
- `/docs/UI_DESIGN.md` - Design system, components, animations
- `/docs/DATA_MODEL.md` - Data models, relationships, Dart code
