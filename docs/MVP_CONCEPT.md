# Mochi Points - MVP Konzept

## Vision

**Mochi Points** ist eine gamifizierte Familien-App, die Kinder spielerisch motiviert, Aufgaben zu erledigen und Verantwortung zu übernehmen. Eltern erstellen Challenges und Belohnungen, Kinder sammeln Mochi Points und erleben dabei ein echtes Gaming-Erlebnis.

---

## Core Concept

### Rollen

| Rolle | Beschreibung |
|-------|--------------|
| **Eltern (Quest Master)** | Erstellen Challenges, vergeben Belohnungen, bestätigen erledigte Quests |
| **Kind (Mochi Hero)** | Nimmt Quests an, sammelt Mochi Points, kauft Belohnungen |

### Kern-Loop

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   [Quest annehmen] → [Quest erfüllen] → [Punkte sammeln]   │
│          ↑                                      │          │
│          │                                      ↓          │
│   [Neue Quests]  ←  [Level Up!]  ←  [Belohnung kaufen]    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Gamification System

### 1. Mochi Hero (Avatar System)

Jedes Kind hat einen **Mochi Hero** - einen personalisierbaren Charakter, der mit dem Kind wächst.

```
┌──────────────────────────────────────────────────────┐
│                    MOCHI HERO                        │
├──────────────────────────────────────────────────────┤
│                                                      │
│           ╭─────╮      Level 7                       │
│          ( ^_^ )       "Fleißiger Held"              │
│           ╰───╯                                      │
│            /█\        ████████░░░░ 720/1000 XP       │
│            / \                                       │
│                       🔥 5 Tage Streak               │
│   [Outfit]  [Pets]  [Badges]                        │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**Evolution Stufen:**
- Level 1-10: **Mochi Novice** (Starter-Look)
- Level 11-25: **Mochi Apprentice** (neue Outfits freigeschaltet)
- Level 26-50: **Mochi Champion** (Spezialeffekte, Aura)
- Level 51+: **Mochi Legend** (Legendäre Customization)

### 2. Quest System

#### Quest-Typen

| Typ | Icon | Beschreibung | Beispiel |
|-----|------|--------------|----------|
| **Daily Quest** | ☀️ | Täglich wiederholbar | "Zähne putzen" |
| **Weekly Quest** | 📅 | Wöchentlich wiederholbar | "Zimmer aufräumen" |
| **Epic Quest** | ⚔️ | Einmalige große Aufgabe | "Fahrradprüfung bestehen" |
| **Series Quest** | 🔄 | Immer verfügbar, stackbar | "1km laufen = 1 MP" |
| **Boss Quest** | 🐉 | Schwere Familien-Challenge | "Familie: 100km zusammen laufen" |

#### Quest-Rarität & Belohnungen

```
┌────────────────────────────────────────────────────────┐
│  QUEST RARITÄT                                         │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ⬜ Common      1-5 MP    Alltägliche Aufgaben        │
│  🟦 Rare        5-15 MP   Besondere Aufgaben          │
│  🟪 Epic        15-30 MP  Große Herausforderungen     │
│  🟨 Legendary   30+ MP    Außergewöhnliche Leistungen │
│                                                        │
└────────────────────────────────────────────────────────┘
```

#### Quest-Annahme Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    VERFÜGBARE QUESTS                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🔄 SERIES QUEST                              +1 MP each   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🏃 1 Kilometer laufen                              │   │
│  │  ─────────────────────────────                      │   │
│  │  Heute: 🏃🏃🏃 (3x = 3 MP verdient)                 │   │
│  │                                                     │   │
│  │  [+ Quest annehmen]                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ☀️ DAILY QUEST                                    +2 MP   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🦷 Zähne putzen (morgens & abends)                 │   │
│  │  ─────────────────────────────────                  │   │
│  │  Progress: ██████████░░░░░░░░░░ 1/2                 │   │
│  │  🔥 Streak: 12 Tage                                 │   │
│  │                                                     │   │
│  │  [✓ Erledigt melden]                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ⚔️ EPIC QUEST                                    +25 MP   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  📚 Buchpräsentation in der Schule                  │   │
│  │  ─────────────────────────────────                  │   │
│  │  Deadline: 15. März 2026                            │   │
│  │  Status: 📋 Angenommen                              │   │
│  │                                                     │   │
│  │  [✓ Erledigt melden]  [Details]                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3. Streak & Bonus System

```
┌─────────────────────────────────────────────────────────────┐
│                      STREAK BONUS                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   🔥 AKTUELLE STREAK: 7 TAGE                               │
│                                                             │
│   Tag 1-6:   Basis MP                                       │
│   Tag 7:     +10% Bonus auf alle Quests heute! 🎉           │
│   Tag 14:    +15% Bonus + Mystery Box                       │
│   Tag 30:    +25% Bonus + Legendary Badge                   │
│   Tag 100:   +50% Bonus + Exclusive Avatar Item             │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  Mo  Di  Mi  Do  Fr  Sa  So                         │   │
│   │  🔥  🔥  🔥  🔥  🔥  🔥  🔥   ← PERFEKTE WOCHE!     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4. Achievement System (Badges)

```
┌─────────────────────────────────────────────────────────────┐
│                      BADGE SAMMLUNG                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   FREIGESCHALTET (12/50)                                    │
│                                                             │
│   🌟 Erster Schritt      - Erste Quest abgeschlossen       │
│   🔥 Feuerstarter        - 7 Tage Streak                   │
│   💪 Fleißige Biene      - 50 Quests abgeschlossen         │
│   🏃 Marathon-Held       - 100km gelaufen (Series Quest)   │
│   📚 Bücherwurm          - 10 Bücher gelesen               │
│   🌙 Nachtputzer         - 30 Tage Zähne geputzt           │
│                                                             │
│   GESPERRT                                                  │
│   🔒 ???                  - Geheimes Achievement            │
│   🔒 Legende             - Erreiche Level 50               │
│   🔒 Familienmeister     - Boss Quest abschließen          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5. Belohnungs-Shop

```
┌─────────────────────────────────────────────────────────────┐
│           🏪 MOCHI SHOP              💰 127 MP              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   BELOHNUNGEN VON MAMA & PAPA                               │
│                                                             │
│   ┌───────────────────┐  ┌───────────────────┐              │
│   │    🍕             │  │    🎮             │              │
│   │                   │  │                   │              │
│   │  Pizza-Abend      │  │  1h extra Spielen │              │
│   │                   │  │                   │              │
│   │    💰 15 MP       │  │    💰 10 MP       │              │
│   │   [Kaufen]        │  │   [Kaufen]        │              │
│   └───────────────────┘  └───────────────────┘              │
│                                                             │
│   ┌───────────────────┐  ┌───────────────────┐              │
│   │    🍦             │  │    🎬             │              │
│   │                   │  │                   │              │
│   │  Eis essen gehen  │  │  Kino-Besuch      │              │
│   │                   │  │                   │              │
│   │    💰 20 MP       │  │    💰 50 MP       │              │
│   │   [Kaufen]        │  │   [Kaufen]        │              │
│   └───────────────────┘  └───────────────────┘              │
│                                                             │
│   AVATAR ITEMS (Kosmetisch)                                 │
│                                                             │
│   👒 Cooler Hut (5 MP)   🎭 Ninja Maske (8 MP)             │
│   🦸 Superhelden-Cape (15 MP)                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6. Familien-Features

#### Family Leaderboard
```
┌─────────────────────────────────────────────────────────────┐
│              👨‍👩‍👧‍👦 FAMILIEN-RANGLISTE                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Diese Woche:                                              │
│                                                             │
│   🥇 1. Emma        ████████████████████  89 MP            │
│   🥈 2. Max         ████████████████      72 MP            │
│   🥉 3. Lina        ████████████          58 MP            │
│                                                             │
│   Gesamt (All Time):                                        │
│                                                             │
│   👑 1. Max         Level 12    2,450 MP                   │
│      2. Emma        Level 10    1,890 MP                   │
│      3. Lina        Level 7     1,120 MP                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Boss Quest (Familien-Challenge)
```
┌─────────────────────────────────────────────────────────────┐
│              🐉 BOSS QUEST: FRÜHJAHRSPUTZ                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Die ganze Familie muss zusammenarbeiten!                  │
│                                                             │
│   Fortschritt: ████████████░░░░░░░░ 65%                    │
│                                                             │
│   Aufgaben:                                                 │
│   ✅ Emma: Kinderzimmer aufräumen                          │
│   ✅ Max: Garage sortieren                                 │
│   🔄 Lina: Garten harken (in Arbeit)                       │
│   ⬜ Alle: Keller entrümpeln                               │
│                                                             │
│   Belohnung für alle: 🎢 Freizeitpark-Besuch!              │
│                                                             │
│   ⏰ Deadline: Sonntag, 18:00 Uhr                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## MVP Features (Phase 1)

### Must Have

| Feature | Beschreibung | Priorität |
|---------|--------------|-----------|
| **User Rollen** | Parent/Child Login mit unterschiedlichen Views | P0 |
| **Quest erstellen** | Eltern erstellen Quests mit Typ, Rarität, MP | P0 |
| **Quest annehmen** | Kinder sehen und nehmen Quests an | P0 |
| **Quest bestätigen** | Eltern bestätigen erledigte Quests | P0 |
| **Mochi Points** | Punkte-Konto mit Transaktionshistorie | P0 |
| **Belohnungs-Shop** | Eltern erstellen Belohnungen, Kinder kaufen | P0 |
| **Series Quests** | Wiederholbare Quests (1km = 1MP) | P0 |
| **Basic Avatar** | Einfacher Character mit Level-Anzeige | P1 |
| **Streak System** | Tägliche Aktivität tracken | P1 |
| **Achievements** | Basis-Set von 10-15 Badges | P1 |

### Nice to Have (Phase 2)

| Feature | Beschreibung |
|---------|--------------|
| Boss Quests | Familien-Challenges |
| Avatar Customization | Outfits, Pets, Accessoires |
| Push Notifications | Quest-Erinnerungen, Streak-Warnung |
| Sound Effects | Audio-Feedback bei Aktionen |
| Animations | Konfetti, Level-Up Effekte |
| Family Leaderboard | Wöchentliche Rangliste |

---

## UI/UX Konzept

### Design Principles

1. **Playful & Colorful** - Lebendige Farben, verspielte Icons
2. **Instant Feedback** - Jede Aktion hat sichtbare Konsequenz
3. **Progress Everywhere** - Fortschrittsbalken, Zahlen, Levels
4. **Celebration Moments** - Feiern von Erfolgen mit Animationen

### Farbschema (Gaming-orientiert)

```
Primary:      #FF6B6B (Coral Red) - Energie, Action
Secondary:    #4ECDC4 (Teal) - Erfolg, Belohnung
Accent:       #FFE66D (Gold) - Mochi Points, Premium
Background:   #2C3E50 (Dark Blue) - Gaming-Atmosphäre
Surface:      #34495E (Slate) - Cards, Dialogs
Success:      #27AE60 (Green) - Quest Complete
Epic:         #9B59B6 (Purple) - Rare Items
Legendary:    #F39C12 (Orange) - Legendary Items
```

### Screen Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      APP NAVIGATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                     ┌──────────┐                            │
│                     │  Splash  │                            │
│                     │  Screen  │                            │
│                     └────┬─────┘                            │
│                          │                                  │
│                     ┌────▼─────┐                            │
│                     │  Login   │                            │
│                     │  Screen  │                            │
│                     └────┬─────┘                            │
│                          │                                  │
│           ┌──────────────┴──────────────┐                   │
│           │                             │                   │
│     ┌─────▼─────┐                 ┌─────▼─────┐             │
│     │  PARENT   │                 │   CHILD   │             │
│     │   VIEW    │                 │   VIEW    │             │
│     └─────┬─────┘                 └─────┬─────┘             │
│           │                             │                   │
│   ┌───────┴───────┐             ┌───────┴───────┐           │
│   │               │             │               │           │
│   ▼               ▼             ▼               ▼           │
│ [Quests]    [Rewards]      [Hero Home]    [Quest Board]     │
│ [Kids]      [Stats]        [Shop]         [Achievements]    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Haupt-Screens (Kind-Ansicht)

#### 1. Hero Home (Dashboard)
```
┌─────────────────────────────────────────────────────────────┐
│ ≡                    MOCHI HERO                    🔔  ⚙️  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│         ╭──────────────────────────────────────────╮        │
│         │                                          │        │
│         │         ╭─────╮                          │        │
│         │        ( ^◡^ )    Emma                   │        │
│         │         ╰───╯     Level 12               │        │
│         │          /█\                             │        │
│         │          / \      🔥 14 Tage Streak      │        │
│         │                                          │        │
│         │    ████████████████░░░░  1,450/2,000 XP  │        │
│         │                                          │        │
│         ╰──────────────────────────────────────────╯        │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  💰 MOCHI POINTS                                    │   │
│   │                                                     │   │
│   │              ✨ 127 ✨                              │   │
│   │                                                     │   │
│   │  +15 diese Woche                    [Shop →]        │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  ☀️ DAILY QUESTS                           3/5 ✓   │   │
│   │                                                     │   │
│   │  ✅ Zähne putzen (morgens)              +2 MP      │   │
│   │  ✅ Bett machen                          +1 MP      │   │
│   │  ✅ Hausaufgaben                         +3 MP      │   │
│   │  ⬜ Zähne putzen (abends)               +2 MP      │   │
│   │  ⬜ 30 Min lesen                         +2 MP      │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐           │
│   │ 🏠     │  │ ⚔️     │  │ 🏪     │  │ 🏆     │           │
│   │ Home   │  │ Quests │  │ Shop   │  │ Stats  │           │
│   └────────┘  └────────┘  └────────┘  └────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 2. Quest Board
```
┌─────────────────────────────────────────────────────────────┐
│ ←                    QUEST BOARD                       🔍   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   [Alle] [Daily] [Weekly] [Epic] [Series]                   │
│                                                             │
│   ─────────────────────────────────────────────────────     │
│                                                             │
│   ☀️ DAILY                                                  │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  🦷                                                 │   │
│   │  Zähne putzen                              +2 MP    │   │
│   │  ░░░░░░░░░░░░░░░░░░░░ 0/2 heute                    │   │
│   │  🔥 Streak: 14 Tage                                │   │
│   │                                      [Erledigt ✓]   │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   🔄 SERIES                                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  🏃                                                 │   │
│   │  1 Kilometer laufen                        +1 MP    │   │
│   │  Heute: 🏃🏃🏃 = 3 MP verdient                      │   │
│   │  Gesamt: 47 km gelaufen                            │   │
│   │                                      [+ Hinzufügen]  │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ⚔️ EPIC                                                   │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  📚                                        🟪 EPIC  │   │
│   │  Buch fertig lesen                        +20 MP    │   │
│   │  "Harry Potter Band 1"                             │   │
│   │  📄 182/309 Seiten                                 │   │
│   │  ⏰ Bis: 20. März                                   │   │
│   │                                        [Details →]   │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 3. Quest Completion Animation
```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│                    ✨ ✨ ✨ ✨ ✨                            │
│                                                             │
│                  QUEST COMPLETE!                            │
│                                                             │
│                      ⚔️                                     │
│                                                             │
│               "Zimmer aufräumen"                            │
│                                                             │
│                                                             │
│                    + 5 MP                                   │
│                    + 50 XP                                  │
│                                                             │
│              ████████████████████░░                         │
│                Level 12 → 13 bald!                          │
│                                                             │
│                 🔥 Streak: 15 Tage!                         │
│                                                             │
│                                                             │
│                    [Weiter →]                               │
│                                                             │
│                    ✨ ✨ ✨ ✨ ✨                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Haupt-Screens (Eltern-Ansicht)

#### 1. Parent Dashboard
```
┌─────────────────────────────────────────────────────────────┐
│ ≡                  QUEST MASTER                    🔔  ⚙️  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Guten Morgen! 👋                                          │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  ⚠️ AUSSTEHENDE BESTÄTIGUNGEN                   3   │   │
│   │                                                     │   │
│   │  Emma: "Zimmer aufräumen"              [✓] [✗]     │   │
│   │  Max: "1km laufen" (x2)                [✓] [✗]     │   │
│   │  Lina: "Hausaufgaben"                  [✓] [✗]     │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  👨‍👩‍👧‍👦 KINDER ÜBERSICHT                                │   │
│   │                                                     │   │
│   │  Emma     Lvl 12   127 MP   🔥14   [Details →]     │   │
│   │  Max      Lvl 10    89 MP   🔥 7   [Details →]     │   │
│   │  Lina     Lvl 7     45 MP   🔥 3   [Details →]     │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  📊 DIESE WOCHE                                     │   │
│   │                                                     │   │
│   │  Quests erstellt: 12                               │   │
│   │  Quests abgeschlossen: 28                          │   │
│   │  Punkte vergeben: 156 MP                           │   │
│   │  Belohnungen eingelöst: 2                          │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐           │
│   │ 🏠     │  │ ⚔️     │  │ 🎁     │  │ 📊     │           │
│   │ Home   │  │ Quests │  │Rewards │  │ Stats  │           │
│   └────────┘  └────────┘  └────────┘  └────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 2. Quest Creation
```
┌─────────────────────────────────────────────────────────────┐
│ ←              NEUE QUEST ERSTELLEN                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Quest Name                                                │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  Zimmer aufräumen                                   │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   Icon auswählen                                            │
│   🧹 🧺 📚 🦷 🏃 🎹 🎨 🌱 🐕 🍽️                           │
│                                                             │
│   Quest-Typ                                                 │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│   │ ☀️      │ │ 📅      │ │ ⚔️      │ │ 🔄      │          │
│   │ Daily   │ │ Weekly  │ │ Epic    │ │ Series  │          │
│   └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
│                                                             │
│   Rarität                                                   │
│   ⬜ Common  🟦 Rare  🟪 Epic  🟨 Legendary                 │
│                                                             │
│   Mochi Points Belohnung                                    │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  [-]              5 MP                          [+] │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   Zuweisen an                                               │
│   [✓] Emma  [✓] Max  [ ] Lina  [ ] Alle                    │
│                                                             │
│   Deadline (optional)                                       │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  Kein Datum                              📅         │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│            [Quest erstellen]                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Technische Architektur

### State Management

```
┌─────────────────────────────────────────────────────────────┐
│                    PROVIDER STRUKTUR                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   AuthProvider                                              │
│   └── currentUser, userRole, familyId                       │
│                                                             │
│   FamilyProvider                                            │
│   └── familyMembers[], parentIds[], childIds[]              │
│                                                             │
│   QuestProvider                                             │
│   └── quests[], activeQuests[], pendingApproval[]           │
│       └── Quest: id, name, type, rarity, reward, streak     │
│                                                             │
│   HeroProvider                                              │
│   └── hero, level, xp, streak, achievements[]               │
│       └── Hero: name, avatar, items[], badges[]             │
│                                                             │
│   PointsProvider                                            │
│   └── balance, transactions[], weeklyEarned                 │
│                                                             │
│   RewardProvider                                            │
│   └── rewards[], purchasedRewards[]                         │
│       └── Reward: id, name, price, category, icon           │
│                                                             │
│   AchievementProvider                                       │
│   └── achievements[], unlockedIds[], progress{}             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Datenmodelle

```dart
// Quest Model
class Quest {
  String id;
  String name;
  String icon;
  QuestType type;        // daily, weekly, epic, series
  QuestRarity rarity;    // common, rare, epic, legendary
  int rewardPoints;
  int rewardXP;
  List<String> assignedTo;
  DateTime? deadline;
  int currentStreak;
  int completionCount;   // für Series Quests
  QuestStatus status;
}

// Hero Model
class Hero {
  String id;
  String name;
  String avatarBase;
  int level;
  int currentXP;
  int xpToNextLevel;
  int currentStreak;
  List<String> unlockedItems;
  List<String> equippedItems;
  List<String> badges;
  DateTime lastActiveDate;
}

// Achievement Model
class Achievement {
  String id;
  String name;
  String description;
  String icon;
  AchievementTier tier;  // bronze, silver, gold, platinum
  String condition;       // z.B. "streak >= 7"
  int progress;
  int target;
  bool isSecret;
}
```

---

## Roadmap

### Phase 1: MVP Core (4-6 Wochen)
- [ ] User Authentication (Parent/Child)
- [ ] Quest CRUD (alle Typen)
- [ ] Quest Workflow (annehmen → erledigen → bestätigen)
- [ ] Mochi Points System
- [ ] Basic Reward Shop
- [ ] Simple Hero Display (Level + XP)
- [ ] Streak Tracking

### Phase 2: Gamification (4 Wochen)
- [ ] Achievement System
- [ ] Avatar Customization
- [ ] Animations & Sound Effects
- [ ] Push Notifications
- [ ] Family Leaderboard

### Phase 3: Social & Advanced (4 Wochen)
- [ ] Boss Quests
- [ ] Avatar Items Shop
- [ ] Statistics & Reports
- [ ] Multiple Families Support
- [ ] Dark Mode

---

## Erfolgskriterien

| Metrik | Ziel |
|--------|------|
| Daily Active Users | Kind loggt sich täglich ein |
| Quest Completion Rate | > 70% der angenommenen Quests |
| Streak Retention | > 50% haben 7+ Tage Streak |
| Reward Redemption | Mindestens 1 Belohnung/Woche/Kind |
| Parent Engagement | Tägliche Quest-Bestätigung |

---

## Zusammenfassung

Mochi Points transformiert Haushaltsaufgaben in ein spannendes Gaming-Erlebnis. Durch Level, Streaks, Achievements und einen personalisierbaren Avatar wird intrinsische Motivation geschaffen. Der Belohnungs-Loop (Quest → Points → Reward) hält Kinder langfristig engagiert, während Eltern ein einfaches Tool zur Motivation und Erziehung erhalten.

**Key Differentiators:**
1. Echter Gaming-Feel statt langweiliger To-Do Liste
2. Sichtbarer Fortschritt durch Level und Avatar
3. Streak-System für tägliche Gewohnheitsbildung
4. Familien-Challenges für gemeinsame Aktivitäten
5. Flexible Quest-Typen für alle Situationen
