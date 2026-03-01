# Mochi Points - UI Design System

## Design Philosophy

### Von "App" zu "Spiel"

Die aktuelle App fühlt sich wie eine statische Verwaltungs-App an. Das neue Design verwandelt Mochi Points in ein **lebendes Spiel**, in dem jede Interaktion belohnt wird und sich der Charakter weiterentwickelt.

```
ALTE APP                           NEUE APP
─────────────────────────────────────────────────────────
❌ Statische Listen                ✅ Animierte Cards
❌ Flache Farben                   ✅ Gradienten & Glow
❌ Keine Feedback                  ✅ Konfetti & Sounds
❌ Langweiliges Layout             ✅ Gaming UI mit XP Bars
❌ Einfache Navigation             ✅ Tab-Bar mit Badges
```

---

## Farbpalette

### Primary Colors (Gaming Theme)

```
┌─────────────────────────────────────────────────────────────┐
│                     FARBPALETTE                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   PRIMARY GRADIENT                                          │
│   ┌────────────────────────────────────────────────────┐    │
│   │ #FF6B6B ─────────────────────────────────► #FF8E53 │    │
│   │ Coral Red                              Sunset Orange│    │
│   └────────────────────────────────────────────────────┘    │
│                                                             │
│   ACCENT COLORS                                             │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│   │ #FFE66D  │ │ #4ECDC4  │ │ #45B7D1  │ │ #96CEB4  │      │
│   │ Gold     │ │ Teal     │ │ Sky Blue │ │ Mint     │      │
│   │ (Points) │ │ (Success)│ │ (Info)   │ │ (Health) │      │
│   └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
│                                                             │
│   RARITY COLORS                                             │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│   │ #B8B8B8  │ │ #4A9DFF  │ │ #A855F7  │ │ #F59E0B  │      │
│   │ Common   │ │ Rare     │ │ Epic     │ │Legendary │      │
│   │ (Gray)   │ │ (Blue)   │ │ (Purple) │ │ (Orange) │      │
│   └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
│                                                             │
│   BACKGROUND                                                │
│   ┌────────────────────────────────────────────────────┐    │
│   │ #1A1B2E ─────────────────────────────────► #2D2E4A │    │
│   │ Deep Space                              Soft Purple │    │
│   └────────────────────────────────────────────────────┘    │
│                                                             │
│   SURFACE                                                   │
│   #2A2B42 (Cards)                                           │
│   #3A3B52 (Elevated)                                        │
│   #4A4B62 (Hover)                                           │
│                                                             │
│   TEXT                                                      │
│   #FFFFFF (Primary)                                         │
│   #B8B8C8 (Secondary)                                       │
│   #6B6B7B (Disabled)                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Light Mode Alternative

```
Background:   #F5F5FA (Light Gray-Blue)
Surface:      #FFFFFF (White)
Primary:      #FF6B6B (Same Coral)
Text:         #2D2E4A (Dark Purple)
```

---

## Typography

```
┌─────────────────────────────────────────────────────────────┐
│                      TYPOGRAPHY                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   DISPLAY (Level, Points)                                   │
│   Font: Fredoka One / Baloo 2                               │
│   Size: 48px - 72px                                         │
│   Weight: Bold                                              │
│                                                             │
│   HEADING                                                   │
│   Font: Nunito                                              │
│   Size: 24px - 32px                                         │
│   Weight: Bold (700)                                        │
│                                                             │
│   BODY                                                      │
│   Font: Nunito                                              │
│   Size: 14px - 16px                                         │
│   Weight: Regular (400) / Semi-Bold (600)                   │
│                                                             │
│   CAPTION                                                   │
│   Font: Nunito                                              │
│   Size: 12px                                                │
│   Weight: Regular                                           │
│   Color: Secondary Text                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Library

### 1. Hero Card (Avatar Display)

```
┌─────────────────────────────────────────────────────────────┐
│                       HERO CARD                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ╔═══════════════════════════════════════════════════════╗ │
│   ║  ┌─────────────────────────────────────────────────┐  ║ │
│   ║  │           ✨                                    │  ║ │
│   ║  │         ╭─────╮                                 │  ║ │
│   ║  │        (  ^◡^  )     EMMA                       │  ║ │
│   ║  │         ╰─────╯      Level 12                   │  ║ │
│   ║  │           /█\        "Fleißige Heldin"          │  ║ │
│   ║  │           / \                                   │  ║ │
│   ║  │                      🔥 14 Tage                 │  ║ │
│   ║  │                                                 │  ║ │
│   ║  │  ████████████████████░░░░░░░░  1,450 / 2,000   │  ║ │
│   ║  │                                            XP   │  ║ │
│   ║  └─────────────────────────────────────────────────┘  ║ │
│   ║                                                       ║ │
│   ║   Gradient Background: Primary → Accent               ║ │
│   ║   Border: 2px solid with glow effect                  ║ │
│   ║   Shadow: 0 8px 32px rgba(255,107,107,0.3)           ║ │
│   ╚═══════════════════════════════════════════════════════╝ │
│                                                             │
│   STATES:                                                   │
│   - Idle: Subtle breathing animation                        │
│   - Level Up: Glow pulse + particles                        │
│   - Streak Milestone: Fire animation                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2. Quest Card

```
┌─────────────────────────────────────────────────────────────┐
│                      QUEST CARDS                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   COMMON QUEST                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ ┌────┐                                              │   │
│   │ │ 🧹 │  Zimmer aufräumen                    +3 MP   │   │
│   │ └────┘  Daily Quest                                │   │
│   │         ░░░░░░░░░░░░░░░░░░░░ 0/1                   │   │
│   │                                                     │   │
│   │  Border: 1px solid #B8B8B8 (Common Gray)           │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   RARE QUEST                                                │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ ┌────┐                                    🟦 RARE   │   │
│   │ │ 📚 │  10 Seiten lesen                    +8 MP   │   │
│   │ └────┘  Weekly Quest                               │   │
│   │         ████████░░░░░░░░░░░░ 4/10                  │   │
│   │         🔥 Streak: 3 Wochen                        │   │
│   │                                                     │   │
│   │  Border: 2px solid #4A9DFF (Rare Blue)             │   │
│   │  Subtle blue glow                                   │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   EPIC QUEST                                                │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ ┌────┐                                    🟪 EPIC   │   │
│   │ │ 🎹 │  Klavierstück lernen               +25 MP   │   │
│   │ └────┘  Epic Quest                                 │   │
│   │         "Für Elise"                                │   │
│   │         ⏰ Bis: 30. März                           │   │
│   │                                                     │   │
│   │  Border: 2px solid #A855F7 (Epic Purple)           │   │
│   │  Purple glow + subtle shimmer animation            │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   LEGENDARY QUEST                                           │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ ✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨  │   │
│   │ ┌────┐                              🟨 LEGENDARY   │   │
│   │ │ 🏆 │  Schuljahr mit 1er Schnitt          +100 MP │   │
│   │ └────┘  Legendary Quest                            │   │
│   │         Die ultimative Herausforderung!            │   │
│   │                                                     │   │
│   │  Border: 3px solid #F59E0B (Legendary Gold)        │   │
│   │  Animated gold particles + glow                    │   │
│   │ ✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨  │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3. Points Display

```
┌─────────────────────────────────────────────────────────────┐
│                    POINTS DISPLAY                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   COMPACT (Header)                                          │
│   ┌────────────────────┐                                    │
│   │  ✨ 127 MP         │  Gold text with subtle glow        │
│   └────────────────────┘                                    │
│                                                             │
│   LARGE (Dashboard)                                         │
│   ┌────────────────────────────────────────────────────┐    │
│   │                                                    │    │
│   │          ╭─────────────────────╮                   │    │
│   │          │                     │                   │    │
│   │          │    ✨ 127 ✨        │                   │    │
│   │          │    MOCHI POINTS     │                   │    │
│   │          │                     │                   │    │
│   │          │   +15 diese Woche   │                   │    │
│   │          ╰─────────────────────╯                   │    │
│   │                                                    │    │
│   │   Background: Radial gradient gold                 │    │
│   │   Animation: Coins floating up                     │    │
│   └────────────────────────────────────────────────────┘    │
│                                                             │
│   ANIMATION: When points increase                           │
│   - Number counts up smoothly                               │
│   - "+X" floats up and fades                               │
│   - Sparkle particle effect                                 │
│   - Subtle "cha-ching" sound                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4. Progress Bars

```
┌─────────────────────────────────────────────────────────────┐
│                    PROGRESS BARS                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   XP BAR                                                    │
│   ┌────────────────────────────────────────────────────┐    │
│   │  Level 12                              1,450/2,000 │    │
│   │  ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │    │
│   └────────────────────────────────────────────────────┘    │
│   - Gradient fill: #4ECDC4 → #45B7D1                       │
│   - Glow effect on fill                                     │
│   - Animated shine sweep                                    │
│                                                             │
│   QUEST PROGRESS                                            │
│   ┌────────────────────────────────────────────────────┐    │
│   │  ████████████░░░░░░░░░░░░░░░░░░░░ 3/10             │    │
│   └────────────────────────────────────────────────────┘    │
│   - Color based on completion %:                           │
│     0-33%:   #FF6B6B (Red)                                 │
│     34-66%:  #FFE66D (Yellow)                              │
│     67-99%:  #4ECDC4 (Teal)                                │
│     100%:    #96CEB4 (Green) + checkmark                   │
│                                                             │
│   STREAK INDICATOR                                          │
│   ┌────────────────────────────────────────────────────┐    │
│   │  🔥 14                                              │    │
│   │  Mo Di Mi Do Fr Sa So                              │    │
│   │  🔥 🔥 🔥 🔥 🔥 🔥 🔥                              │    │
│   └────────────────────────────────────────────────────┘    │
│   - Fire animation on streak count                         │
│   - Past days: solid fire                                  │
│   - Today: pulsing fire                                    │
│   - Future: gray outline                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5. Buttons

```
┌─────────────────────────────────────────────────────────────┐
│                       BUTTONS                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   PRIMARY (Call to Action)                                  │
│   ┌────────────────────────────────────────────────────┐    │
│   │              Quest annehmen                        │    │
│   └────────────────────────────────────────────────────┘    │
│   - Background: Linear gradient #FF6B6B → #FF8E53          │
│   - Border-radius: 16px                                    │
│   - Shadow: 0 4px 16px rgba(255,107,107,0.4)              │
│   - Hover: Scale 1.02 + brighter                          │
│   - Active: Scale 0.98 + darker                           │
│                                                             │
│   SECONDARY                                                 │
│   ┌────────────────────────────────────────────────────┐    │
│   │              Abbrechen                             │    │
│   └────────────────────────────────────────────────────┘    │
│   - Background: Transparent                                │
│   - Border: 2px solid #4A4B62                             │
│   - Text: #B8B8C8                                         │
│                                                             │
│   SUCCESS (Quest Complete)                                  │
│   ┌────────────────────────────────────────────────────┐    │
│   │         ✓ Erledigt                                 │    │
│   └────────────────────────────────────────────────────┘    │
│   - Background: Linear gradient #4ECDC4 → #45B7D1          │
│   - Checkmark animation on tap                             │
│                                                             │
│   ICON BUTTON (FAB)                                         │
│         ╭─────╮                                             │
│         │  +  │   Gradient background                       │
│         ╰─────╯   Floating shadow                          │
│                   Pulse animation                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6. Achievement Badge

```
┌─────────────────────────────────────────────────────────────┐
│                   ACHIEVEMENT BADGES                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   UNLOCKED                                                  │
│      ╭───────────────╮                                      │
│      │    ╭─────╮    │                                      │
│      │    │ 🔥  │    │   "Feuerstarter"                     │
│      │    ╰─────╯    │   7 Tage Streak erreicht             │
│      │   ★ ★ ★ ☆ ☆   │   Gold Tier                          │
│      ╰───────────────╯                                      │
│                                                             │
│   - Metallic border based on tier                          │
│   - Subtle shine animation                                  │
│   - Particles on hover                                      │
│                                                             │
│   LOCKED                                                    │
│      ╭───────────────╮                                      │
│      │    ╭─────╮    │                                      │
│      │    │ 🔒  │    │   "???"                              │
│      │    ╰─────╯    │   Geheimes Achievement               │
│      │   ☆ ☆ ☆ ☆ ☆   │                                      │
│      ╰───────────────╯                                      │
│                                                             │
│   - Grayscale / desaturated                                │
│   - No animation                                           │
│   - "?" icon for secret achievements                       │
│                                                             │
│   TIERS:                                                    │
│   Bronze:   #CD7F32 border                                 │
│   Silver:   #C0C0C0 border                                 │
│   Gold:     #FFD700 border + glow                          │
│   Platinum: #E5E4E2 border + rainbow shimmer               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Navigation

### Bottom Navigation Bar

```
┌─────────────────────────────────────────────────────────────┐
│                   BOTTOM NAVIGATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                                                     │   │
│   │   ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐     │   │
│   │   │ 🏠  │  │ ⚔️  │  │     │  │ 🏪  │  │ 🏆  │     │   │
│   │   │Home │  │Quest│  │     │  │Shop │  │Stats│     │   │
│   │   └─────┘  └──┬──┘  │     │  └─────┘  └─────┘     │   │
│   │               │     │  +  │                        │   │
│   │             [3]     │     │  ← FAB for quick add   │   │
│   │        Badge für    └─────┘                        │   │
│   │        pending                                     │   │
│   │        quests                                      │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   SELECTED STATE:                                           │
│   - Icon filled + primary color                            │
│   - Label visible                                          │
│   - Subtle glow under icon                                 │
│                                                             │
│   BADGE:                                                    │
│   - Red circle with count                                  │
│   - Pulse animation for new items                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Animations & Micro-interactions

### 1. Quest Complete Celebration

```
┌─────────────────────────────────────────────────────────────┐
│               QUEST COMPLETE ANIMATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   SEQUENCE:                                                 │
│                                                             │
│   1. Screen dims slightly (overlay)                         │
│                                                             │
│   2. Quest card flies to center + scales up                │
│      Duration: 300ms                                        │
│      Easing: cubic-bezier(0.34, 1.56, 0.64, 1)             │
│                                                             │
│   3. Checkmark draws in                                     │
│      ╭───────╮                                              │
│      │   ✓   │  SVG path animation                         │
│      ╰───────╯  Duration: 400ms                            │
│                                                             │
│   4. Confetti explosion                                     │
│      🎉 🎊 ✨ 🌟                                            │
│      Particle count: 50-100                                │
│      Duration: 2s                                          │
│                                                             │
│   5. Points count up                                        │
│      "+5 MP" → Number increment animation                  │
│      Sound: coin_collect.mp3                               │
│                                                             │
│   6. XP bar fills                                          │
│      Animated progress fill                                │
│      If level up: special Level Up sequence                │
│                                                             │
│   7. Card shrinks + returns to list                        │
│      Or "Continue" button appears                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2. Level Up Animation

```
┌─────────────────────────────────────────────────────────────┐
│                  LEVEL UP ANIMATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│            ✨  ✨  ✨  ✨  ✨  ✨  ✨                        │
│                                                             │
│                   LEVEL UP!                                 │
│                                                             │
│                   ╭─────╮                                   │
│                  (  ^◡^  )                                  │
│                   ╰─────╯                                   │
│                     /█\         Glow pulse                  │
│                     / \         Particles rise              │
│                                                             │
│                  12 → 13                                    │
│                                                             │
│              "Mochi Champion"                               │
│                                                             │
│          🎁 Neues Item freigeschaltet!                     │
│                                                             │
│                  [Ansehen]                                  │
│                                                             │
│            ✨  ✨  ✨  ✨  ✨  ✨  ✨                        │
│                                                             │
│                                                             │
│   Sound: level_up_fanfare.mp3                              │
│   Haptic: Heavy impact                                     │
│   Duration: 3s                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3. Streak Animation

```
┌─────────────────────────────────────────────────────────────┐
│                  STREAK ANIMATIONS                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   DAILY STREAK MAINTAINED:                                  │
│                                                             │
│         🔥 → 🔥                                             │
│         14    15                                            │
│                                                             │
│   - Fire grows briefly                                     │
│   - Number increments with bounce                          │
│   - Small particle burst                                   │
│                                                             │
│   ─────────────────────────────────────────────────────     │
│                                                             │
│   STREAK MILESTONE (7, 14, 30, 100 days):                  │
│                                                             │
│         🔥🔥🔥                                              │
│        STREAK!                                              │
│         30 TAGE                                             │
│                                                             │
│   - Full screen takeover                                   │
│   - Multiple fire animations                               │
│   - Badge unlock if applicable                             │
│   - Bonus points notification                              │
│                                                             │
│   ─────────────────────────────────────────────────────     │
│                                                             │
│   STREAK LOST:                                              │
│                                                             │
│         🔥 → 💨                                             │
│         14 → 0                                              │
│                                                             │
│   - Fire extinguishes (smoke effect)                       │
│   - Sad sound effect                                       │
│   - Encouraging message                                    │
│   - "Morgen wieder! 💪"                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Screen Layouts

### Hero Home (Child Dashboard)

```
┌─────────────────────────────────────────────────────────────┐
│                      HERO HOME                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ≡                                          🔔 ⚙️   │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │                                                     │    │
│  │  ╭─────────────────────────────────────────────╮    │    │
│  │  │              HERO CARD                      │    │    │
│  │  │          (Full width, 200px height)        │    │    │
│  │  │                                            │    │    │
│  │  │   Avatar    Name + Level                   │    │    │
│  │  │             XP Bar                         │    │    │
│  │  │             Streak                         │    │    │
│  │  ╰─────────────────────────────────────────────╯    │    │
│  │                                                     │    │
│  │  ╭─────────────────────────────────────────────╮    │    │
│  │  │         MOCHI POINTS DISPLAY                │    │    │
│  │  │              ✨ 127 ✨                       │    │    │
│  │  │          +15 diese Woche                    │    │    │
│  │  ╰─────────────────────────────────────────────╯    │    │
│  │                                                     │    │
│  │  Heutige Quests                         Alle →     │    │
│  │  ╭─────────────────────────────────────────────╮    │    │
│  │  │  Daily Quest Card 1                         │    │    │
│  │  ╰─────────────────────────────────────────────╯    │    │
│  │  ╭─────────────────────────────────────────────╮    │    │
│  │  │  Daily Quest Card 2                         │    │    │
│  │  ╰─────────────────────────────────────────────╯    │    │
│  │  ╭─────────────────────────────────────────────╮    │    │
│  │  │  Series Quest Card                          │    │    │
│  │  ╰─────────────────────────────────────────────╯    │    │
│  │                                                     │    │
│  │                                                     │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │  🏠      ⚔️      [+]      🏪      🏆              │    │
│  │  Home   Quests          Shop    Stats            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Shop Screen

```
┌─────────────────────────────────────────────────────────────┐
│                        SHOP                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ←              MOCHI SHOP              ✨ 127 MP    │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │                                                     │    │
│  │  [Belohnungen]  [Avatar Items]  [Mystery Box]       │    │
│  │                                                     │    │
│  │  ─────────────────────────────────────────────────  │    │
│  │                                                     │    │
│  │  Belohnungen von Mama & Papa                        │    │
│  │                                                     │    │
│  │  ┌─────────────┐  ┌─────────────┐                   │    │
│  │  │     🍕      │  │     🎮      │                   │    │
│  │  │             │  │             │                   │    │
│  │  │ Pizza-Abend │  │ 1h Gaming   │                   │    │
│  │  │             │  │             │                   │    │
│  │  │   15 MP     │  │   10 MP     │                   │    │
│  │  │  [Kaufen]   │  │  [Kaufen]   │                   │    │
│  │  └─────────────┘  └─────────────┘                   │    │
│  │                                                     │    │
│  │  ┌─────────────┐  ┌─────────────┐                   │    │
│  │  │     🍦      │  │     🎬      │                   │    │
│  │  │             │  │             │                   │    │
│  │  │  Eis essen  │  │ Kino-Besuch │                   │    │
│  │  │             │  │             │                   │    │
│  │  │   20 MP     │  │   50 MP     │                   │    │
│  │  │  [Kaufen]   │  │ 🔒 23 mehr  │                   │    │
│  │  └─────────────┘  └─────────────┘                   │    │
│  │                                                     │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │  🏠      ⚔️      [+]      🏪      🏆              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Sound Design

```
┌─────────────────────────────────────────────────────────────┐
│                     SOUND EFFECTS                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ACTION                    SOUND                           │
│   ─────────────────────────────────────────────────────     │
│   Quest annehmen            Whoosh + positive chime         │
│   Quest erledigt            Ta-da! + coin collect           │
│   Punkte erhalten           Cha-ching (coin sound)          │
│   Level Up                  Fanfare + sparkle               │
│   Achievement unlock        Badge unlock + celebration      │
│   Streak maintained         Fire crackle                    │
│   Streak lost               Sad trombone (gentle)           │
│   Button tap                Soft click                      │
│   Navigation                Subtle whoosh                   │
│   Error                     Gentle boop                     │
│   Shop purchase             Cash register + sparkle         │
│   Mystery box open          Dramatic reveal                 │
│                                                             │
│   SETTINGS:                                                 │
│   - Master volume slider                                    │
│   - Sound effects ON/OFF                                    │
│   - Music ON/OFF (ambient)                                  │
│   - Haptic feedback ON/OFF                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Responsive Considerations

```
┌─────────────────────────────────────────────────────────────┐
│                    RESPONSIVE DESIGN                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   MOBILE (Primary Target)                                   │
│   Width: 320px - 428px                                      │
│   - Single column layout                                    │
│   - Bottom navigation                                       │
│   - Full-width cards                                        │
│                                                             │
│   TABLET                                                    │
│   Width: 768px - 1024px                                     │
│   - 2-column grid for quests/rewards                       │
│   - Side navigation option                                  │
│   - Larger hero card                                        │
│                                                             │
│   FONT SCALING:                                             │
│   - Respect system font size settings                      │
│   - Test with large accessibility fonts                    │
│   - Minimum touch target: 44x44px                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Notes

### Flutter Packages empfohlen

```yaml
dependencies:
  # Animations
  rive: ^0.12.0              # Complex character animations
  lottie: ^2.7.0             # JSON animations (confetti, etc.)
  flutter_animate: ^4.3.0     # Simple widget animations

  # UI Components
  glassmorphism: ^3.0.0       # Glass effect cards
  shimmer: ^3.0.0             # Loading shimmer
  percent_indicator: ^4.2.3   # Progress bars

  # Effects
  confetti: ^0.7.0            # Celebration confetti
  audioplayers: ^5.2.1        # Sound effects
  vibration: ^1.8.4           # Haptic feedback

  # Fonts
  google_fonts: ^6.1.0        # Nunito, Fredoka One
```

### Animation Guidelines

```dart
// Standard durations
const Duration fast = Duration(milliseconds: 150);
const Duration normal = Duration(milliseconds: 300);
const Duration slow = Duration(milliseconds: 500);
const Duration celebration = Duration(milliseconds: 2000);

// Standard curves
const Curve bounce = Curves.elasticOut;
const Curve smooth = Curves.easeInOut;
const Curve energetic = Curves.easeOutBack;
```

---

## Summary

Das neue UI-Design transformiert Mochi Points von einer statischen Listen-App zu einem lebendigen Gaming-Erlebnis durch:

1. **Dunkles Gaming-Theme** mit lebendigen Akzentfarben
2. **Animierte Feedback-Loops** bei jeder Interaktion
3. **Rarity-System** für visuelle Hierarchie
4. **Progress-Visualisierung** überall sichtbar
5. **Celebration Moments** die Erfolge feiern
6. **Sound Design** für immersives Erlebnis
7. **Avatar-System** für persönliche Bindung

Das Ergebnis: Kinder WOLLEN die App öffnen, nicht weil sie müssen, sondern weil es Spaß macht.
