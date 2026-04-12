# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Start Instructions

**At the start of each session:**
1. Check for open GitHub issues (oldest first): `gh issue list --limit 50 --state open --json number,title,labels,createdAt --jq 'sort_by(.createdAt) | .[] | "#\(.number)\t\(.title)"'`
2. Ask the user which issue to work on
3. Create a feature branch for the selected issue

## Git Workflow (GitHub Flow)

We use **GitHub Flow** (https://githubflow.github.io/):

1. **`main` is always deployable** - never commit broken code to main
2. **Create feature branches** - descriptive names like `feature/quest-system` or `fix/streak-calculation`
3. **Open Pull Requests** - for code review before merging
4. **Merge after review** - then deploy immediately

### Branch Naming Convention
- `feature/<issue-number>-<short-description>` - new features
- `fix/<issue-number>-<short-description>` - bug fixes
- `docs/<description>` - documentation only

### Workflow Commands
```bash
# Start working on an issue
gh issue list                              # Check open issues
git checkout -b feature/123-quest-system   # Create feature branch

# During development
git add <files>
git commit -m "Add quest type selection"

# Ready for review
git push -u origin feature/123-quest-system
gh pr create --fill                        # Create PR

# After approval
gh pr merge                                # Merge to main
git checkout main && git pull
```

### Pull Request Workflow
**IMPORTANT**: After creating a PR, always ask the user if it should be merged.

1. Create PR with `gh pr create`
2. **Ask user: "Soll ich PR #X mergen?"**
3. Only merge after explicit confirmation
4. After merge, switch to main and pull: `git checkout main && git pull`

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
flutter build web --no-tree-shake-icons   # Web (IMPORTANT: always use --no-tree-shake-icons!)
```

### Web Build - Wichtig
**NIEMALS `flutter build web` ohne `--no-tree-shake-icons` ausführen!**
Flutter's Tree-Shaking entfernt aggressiv Icons aus der Font-Datei (99%+ Reduktion).
Da die App Icons teilweise dynamisch lädt, werden diese nicht erkannt und entfernt.
- Debug-Modus (`flutter run -d chrome`) ist davon nicht betroffen
- Für lokales Testen des Web-Builds: `python3 -m http.server 8765 --directory build/web`

### Neue Hintergrundbilder hinzufügen
Bilddatei (`.png` / `.jpg` / `.jpeg` / `.webp`) einfach in
`assets/backgrounds/` ablegen — kein Eintrag in `pubspec.yaml` oder Dart-Code
nötig. `BackgroundService` entdeckt die Datei beim nächsten App-Start automatisch
via `AssetManifest` und zeigt sie im Picker (*Erscheinungsbild → Hintergrund*).

Hot-Reload reicht **nicht**: neue Assets werden erst bei einem Full-Restart
(`R` im `flutter run`-Terminal) oder bei einem Neu-Build gebundelt. Details:
`docs/BACKGROUND_AUTO_DISCOVERY.md`.

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

### E2E Tests (Playwright)

The Flutter Web target is covered by a Playwright suite under `e2e/`.
Specs live in `docs/tests/playwright/PW-*.md` and are translated 1:1
into `e2e/tests/specs/PW-*.spec.ts` files, one PR per issue.

**Before you touch any Playwright-labelled issue:**

1. **Read `docs/tests/playwright/FINDINGS.md` first.** It catalogs every
   non-obvious Flutter-Web-quirk, Semantics-Tree label, seed-format
   detail, dependency trap and workflow tip that has surfaced so far.
   Ignoring it costs hours of trial-and-error; reading it is ~10 minutes.
2. Follow the explore-before-write workflow documented there (W-1):
   run the app, drive it interactively with
   `npx --yes -p @playwright/cli playwright-cli`, snapshot the real
   semantics tree, then crystallize the findings into the spec file.
3. Use the shared helpers (`flutterFill`, `flutterText`,
   `clickUnlabeledButton`, `openFlutterApp`) and seed builders
   (`seedFamilyWithChild` et al.) from `e2e/tests/fixtures/`. Do not
   re-implement any of them per spec.

**When you uncover a new non-obvious finding — update `FINDINGS.md` in
the same PR.** This is part of the Definition of Done for every
Playwright PR, not optional. The catalog is a force multiplier: PW-003
went green on the first try because everything PW-001/PW-002 had
discovered was already in the doc. If we stop maintaining it, that
advantage disappears and everyone re-learns the same quirks.

**Local run loop** (fastest): pre-build `flutter build web
--no-tree-shake-icons`, serve with `python3 -m http.server 8766
--directory build/web`, then run
`CI=true E2E_BASE_URL=http://127.0.0.1:8766 npx playwright test` from
`e2e/`. The Makefile target `make e2e` handles the full auto-start
path for one-shot runs; see `e2e/README.md` for hot-reload and
debugging modes.

## Current Status

**Phase**: MVP Development
**Current Features**: Basic quest/reward CRUD, navigation
**Next Steps**: User authentication, quest workflow, hero system

## Documentation

- `/docs/MVP_CONCEPT.md` - Full product specification with gamification features
- `/docs/UI_DESIGN.md` - Design system, components, animations
- `/docs/DATA_MODEL.md` - Data models, relationships, Dart code
- `/docs/IST_ANALYSE.md` - Process-oriented snapshot of the current app,
  swimlanes per main process, implementation gaps
- `/docs/tests/playwright/` - Playwright E2E specs (PW-001..PW-016)
  - `README.md` - Spec index, test-stack decisions, shared fixtures
  - `FINDINGS.md` - **Required reading before any Playwright PR**;
    catalog of Flutter-Web quirks, UI labels, seed conventions. Must be
    kept up-to-date whenever a new non-obvious finding surfaces.
