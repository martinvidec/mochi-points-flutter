# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code (linting)
flutter analyze

# Build for release
flutter build apk        # Android
flutter build ios        # iOS
```

## Architecture Overview

This is a Flutter rewards/points tracking app ("Mochi Points") using the Provider pattern for state management. The UI is in German.

### State Management
- Uses `provider` package with `ChangeNotifier` pattern
- All providers are registered in `main.dart` via `MultiProvider`
- Four main providers:
  - `ChallengeProvider`: Manages challenges (tasks that earn points)
  - `MochiPointProvider`: Tracks earned points history
  - `MochiPointAccountProvider`: Manages point balance with persistence
  - `EatyProvider`: Manages food/reward items

### Data Flow
- Users complete **Challenges** to earn **MochiPoints**
- Points are tracked in **MochiPointAccountProvider** (persisted via SharedPreferences)
- Points can be spent on **Eaties** (rewards) through the cart system
- `StorageService` handles JSON serialization to SharedPreferences

### Key Models
- `Challenge`: Has id, name, icon, reward amount
- `MochiPoint`: Links a Challenge to points earned with timestamp
- `Eaty`: Reward item with name and price
- `CartItem`: Wraps Eaty with quantity for purchases

### Navigation
- `BottomNavigation` widget provides 5 tabs: Übersicht (Summary), Mochi Points, Eaties, Challenges, Warenkorb (Cart)
- `SummaryPage` is the home page showing account balance and statistics
- `MochiPointsPage` is the main content page with tab switching

### Theme
Uses Material 3 with custom colors: sakura pink primary (#FF7E7E), yuzu yellow secondary (#FFD23F), matcha green tertiary (#7EAE4E).
