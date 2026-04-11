# IST-Analyse: Mochi Points

**Stand:** 2026-04-11
**Branch:** `main`
**Phase (laut CLAUDE.md):** MVP Development

Dieses Dokument beschreibt den aktuell implementierten Zustand der Mochi-Points-App,
identifiziert die Hauptprozesse entlang der beteiligten Akteure und ordnet die Funktionen
als SwimLanes ein. Es ist bewusst technisch, aber strukturiert so, dass sich daraus ein
SOLL-Konzept und ein Backlog ableiten lassen.

---

## 1. Überblick

### 1.1 Technischer Stack (IST)
- **Framework:** Flutter (Dart), Material 3, Dark Gaming Theme
- **State Management:** `provider` mit `ChangeNotifier`, 8 Root-Provider in `lib/main.dart`
- **Persistenz:** `SharedPreferences` via `lib/services/storage_service.dart` (JSON-serialisierte Listen/Objekte)
- **Navigation:** Named Routes (`/login`, `/family-setup`, `/hero-home`, `/parent-dashboard`) und `IndexedStack` in den Dashboards
- **Kein Backend:** keine Cloud, keine Sync-Mechanismen aktiv
- **Bootstrap:** `main()` → `BackgroundService().init()` → `MultiProvider` → `ProviderConnector` → `SplashPage`

### 1.2 Akteure (SwimLanes)
| Rolle | Rolle im System | Einstiegspunkt |
|---|---|---|
| **Elternteil** (*Quest Master*) | verwaltet Familie, Quests, Rewards, Freigaben | `ParentDashboardPage` |
| **Kind** (*Mochi Hero*) | akzeptiert Quests, kauft & löst Rewards ein, pflegt Avatar | `ChildHeroHomePage` |
| **System / App** | Berechnungen (XP, Level, Streak, Bonus), Persistenz, Benachrichtigungen, Callbacks | `ProviderConnector`, Services, Provider-Callbacks |

### 1.3 Kern-Domänen-Modelle (`lib/models/`)
`User`, `Family`, `Quest`, `QuestInstance`, `Hero`, `HeroAppearance`, `Reward`, `Purchase`,
`PointsAccount`, `Transaction`, `Achievement`, `AchievementProgress`, `AppNotification`.
Legacy/ungenutzt: `Challenge`, `Eaty`, `MochiPoint`, `CartItem` (siehe §6).

---

## 2. Hauptprozesse

Die App lässt sich in **10 Hauptprozesse** gliedern. Jeder Prozess wird unten als SwimLane
mit dem Ablauf und dem aktuellen Implementierungsstand beschrieben.

| # | Prozess | Status | Verantwortliche Provider / Pages |
|---|---|---|---|
| P1 | App-Bootstrap & Routing | ✅ implementiert (mit Lade-Lücke, s. §5) | `main.dart`, `SplashPage`, `ProviderConnector` |
| P2 | Familie einrichten (Onboarding) | ✅ | `pages/setup/*`, `AuthProvider` |
| P3 | Benutzerwechsel / Login | ✅ | `LoginPage`, `AuthProvider`, `PinDialog` |
| P4 | Familienmitglied pflegen | ✅ | `FamilyManagementPage`, `AddMemberPage` |
| P5 | Quest-Lifecycle (erstellen → approven) | ✅ | `QuestProvider`, Parent- & Child-Quest-Pages |
| P6 | Belohnungs-Lifecycle (Shop → Einlösung) | ✅ | `RewardProvider`, `PointsProvider`, Shop-/Approval-Pages |
| P7 | Punktekonto & Transaktionen | ✅ | `PointsProvider`, `TransactionHistoryPage` |
| P8 | Hero-Progression (XP / Level / Avatar) | ✅ | `HeroProvider`, `LevelService`, Appearance-Pages |
| P9 | Streak & Streak-Bonus | ✅ | `HeroProvider`, `StreakService` |
| P10 | Benachrichtigungen (Inbox) | ✅ | `NotificationProvider`, Provider-Callbacks |
| P11 | Achievements | ⚠️ **nur UI, nicht verdrahtet** (siehe §5.1) | `AchievementProvider`, `AchievementsPage` |

---

## 3. SwimLane-Diagramme der Hauptprozesse

Legende für alle Diagramme:
```
Kind      │ — Aktionen des Kindes (UI-Interaktion)
Eltern    │ — Aktionen der Eltern (UI-Interaktion)
System    │ — Provider / Services / Callbacks / Persistenz
```

### P1 — App-Bootstrap & Routing
```
Kind / Eltern │ System
──────────────┼──────────────────────────────────────────────
              │ main() → BackgroundService.init()
              │        → runApp(MultiProvider)
              │        → ProviderConnector verdrahtet Callbacks
              │
App öffnen ──►│ SplashPage.initState()
              │   ├─ AuthProvider.initialize()      (Family + Members laden)
              │   └─ NotificationProvider.loadData()
              │
              │ Routing-Entscheidung:
              │   ├─ keine Family? ─► /family-setup   (P2)
              │   ├─ Family + User? ─►
              │   │     ├─ isParent ─► /parent-dashboard
              │   │     └─ isChild  ─► /hero-home
              │   └─ Family, kein User ─► /login     (P3)
```
**Datei-Anker:** `lib/main.dart:21-39`, `lib/pages/splash_page.dart:21-44`

---

### P2 — Familie einrichten (Onboarding)
```
Eltern                       │ System
─────────────────────────────┼────────────────────────────────
Familie anlegen (Name)       │
„Erster Elternteil" tippen ──► AddMemberPage (isFirstParent=true)
  Name, Avatar, PIN eingeben │
Weitere Mitglieder           │
  (Kind / Eltern) hinzufügen │
„Fertig" ────────────────────► AuthProvider.createFamily()
                             │ AuthProvider.addMember() je Mitglied
                             │ StorageService persistiert Family + Members
                             │ Routing auf passendes Dashboard
```
**Datei-Anker:** `lib/pages/setup/family_setup_page.dart`, `lib/providers/auth_provider.dart:100-149`

---

### P3 — Benutzerwechsel / Login
```
Benutzer                      │ System
──────────────────────────────┼───────────────────────────────
LoginPage öffnen              │ familyMembers als Avatar-Grid
Avatar antippen ──────────────► _handleUserTap(userId)
(hasPin?) PIN eingeben        │ PinDialog.show() → enteredPin
                              │ AuthProvider.login(id, pin)
                              │   ├─ PIN-Vergleich
                              │   ├─ currentUser setzen
                              │   └─ lastUserId persistieren
                              │ Routing:
                              │   ├─ isParent ─► /parent-dashboard
                              │   └─ isChild  ─► /hero-home
```
**Datei-Anker:** `lib/pages/login_page.dart:20-59`, `lib/providers/auth_provider.dart:62-94`

---

### P4 — Familienmitglied pflegen
Angebunden ist bisher das **Hinzufügen** neuer Mitglieder aus dem Parent-Dashboard
(`FamilyManagementPage` → `AddMemberPage`). Ein eigener Flow für **Bearbeiten / PIN ändern
/ Entfernen** existiert nicht (siehe §5.2).

---

### P5 — Quest-Lifecycle
Der zentrale Gamification-Loop. Statusübergänge gemäß `QuestStatus`:
`available → inProgress → pendingApproval → completed` (bzw. `expired`).

```
Eltern                  │ Kind                    │ System
────────────────────────┼─────────────────────────┼────────────────────────────────
Quest erstellen ───────►│                         │ QuestProvider.createQuest()
(Name, Typ, Rarity,     │                         │   └─ persist(_questsKey)
 rewardPoints, rewardXP,│                         │
 assignedTo)            │                         │
                        │ Quest-Board öffnen ────►│ availableQuests(childId):
                        │                         │   filtert aktive, nicht zugewiesene,
                        │                         │   nicht aktiv laufende Quests aus
                        │                         │
                        │ "Akzeptieren" ─────────►│ QuestProvider.acceptQuest()
                        │                         │   └─ QuestInstance.inProgress anlegen
                        │                         │
                        │ "Erledigt" ────────────►│ QuestProvider.completeQuest()
                        │                         │   ├─ Status → pendingApproval
                        │                         │   ├─ completedAt setzen
                        │                         │   └─ NotificationProvider.create()
                        │                         │         → Parent (questCompleted, ⏳)
                        │                         │
Approval-Seite öffnen ──┤                         │ pendingApproval-Liste
                        │                         │
"Genehmigen" ──────────►│                         │ QuestProvider.approveQuest()
                        │                         │   ├─ Status → completed
                        │                         │   ├─ approvedAt / approvedBy
                        │                         │   └─ onQuestApproved-Callback →
                        │                         │       HeroProvider.recordActivity() (P9)
                        │                         │       PointsProvider.earn(baseMP)
                        │                         │       PointsProvider.earn(streakBonusMP, bonus)
                        │                         │       HeroProvider.addXP(xp) → evtl. Level-Up (P8)
                        │                         │       NotificationProvider.create()
                        │                         │         → Child (questApproved, ✅)
                        │                         │
"Ablehnen" (optional     │                         │ QuestProvider.rejectQuest()
 mit Grund) ────────────►│                         │   ├─ Status → inProgress, progress=0
                        │                         │   └─ NotificationProvider.create()
                        │                         │         → Child (questRejected, ❌)
```
**Datei-Anker:** `lib/providers/quest_provider.dart:118-331`, `lib/main.dart:107-161`,
`lib/pages/parent/approval_page.dart`, `lib/pages/child/quest_board_page.dart`

**Nebenbemerkungen:**
- XP-Fallback, wenn `quest.rewardXP == 0`: `rewardPoints * 10`
  (`lib/providers/quest_provider.dart:269`).
- Streak-Bonus wirkt **nur auf Points**, nicht auf XP (`lib/main.dart:147-148`).
- `incrementSeriesProgress` ist implementiert, wird aber in der UI nur punktuell genutzt.

---

### P6 — Belohnungs-Lifecycle (Shop / Einlösung)
```
Eltern                  │ Kind                    │ System
────────────────────────┼─────────────────────────┼────────────────────────────────
Reward erstellen ──────►│                         │ RewardProvider.createReward()
(Name, Preis, Stock,    │                         │
 Kategorie)             │                         │
                        │ Shop öffnen ───────────►│ availableRewards (isActive & !expired)
                        │                         │
                        │ "Kaufen" ──────────────►│ RewardProvider.purchaseReward()
                        │                         │   ├─ PointsProvider.spend(price)
                        │                         │   ├─ Stock −1 (falls limitiert)
                        │                         │   └─ Purchase(status=purchased)
                        │                         │
                        │ "My Rewards" öffnen     │ purchaseHistory(userId)
                        │ "Einlösen" ────────────►│ RewardProvider.requestRedemption()
                        │                         │   ├─ Purchase.status → pendingRedemption
                        │                         │   └─ NotificationProvider.create()
                        │                         │         → Parent (rewardRedeemed, 🎁)
                        │                         │
RedemptionPage öffnen   │                         │ pendingRedemptions-Liste
"Bestätigen" ──────────►│                         │ RewardProvider.confirmRedemption()
                        │                         │   └─ Purchase.status → redeemed
"Ablehnen" ────────────►│                         │ RewardProvider.rejectRedemption()
                        │                         │   ├─ PointsProvider.earn(refund)
                        │                         │   └─ Purchase.status → cancelled
"Zurück an Kind"        │ "Abbrechen"             │ RewardProvider.cancelRedemption()
                        │ (eigener Rücknahme)     │   └─ Purchase.status → purchased
```
**Datei-Anker:** `lib/providers/reward_provider.dart:96-310`,
`lib/pages/child/shop_page.dart`, `lib/pages/child/my_rewards_page.dart`,
`lib/pages/parent/redemption_page.dart`

---

### P7 — Punktekonto & Transaktionen
```
Auslöser                   │ System
───────────────────────────┼────────────────────────────────
Quest approved (P5)        │ PointsProvider.earn(points, questComplete)
Streak-Bonus (P5)          │ PointsProvider.earn(bonus, bonus)
Reward-Kauf (P6)           │ PointsProvider.spend(price, purchase)
Redemption abgelehnt (P6)  │ PointsProvider.earn(refund, refund)
Verlauf anzeigen           │ PointsProvider.getTransactionHistory()
                           │   sortiert desc, optional nach Typ gefiltert
                           │ TransactionHistoryPage rendert
```
Das Konto ist pro `userId` gekapselt (`PointsAccount`), Transaktionen tragen
`balanceAfter` für Revisionen. Eine Account-Initialisierung erfolgt **lazy** beim
ersten `earn`/`spend`-Aufruf (`lib/providers/points_provider.dart:73-88`).

---

### P8 — Hero-Progression (XP / Level / Avatar)
```
Auslöser                   │ System
───────────────────────────┼────────────────────────────────
Quest approved (P5)        │ HeroProvider.addXP(userId, xp)
                           │   ├─ Hero.addXP() (Overflow ins nächste Level)
                           │   └─ Level-Up? → onLevelUp-Callback
                           │                  NotificationProvider (levelUp, 🎉)
Avatar bearbeiten          │ HeroProvider.updateAppearance()
                           │ HeroProvider.equipItem() / unequipItem()
Hero erstmalig aufrufen    │ HeroProvider.initialize(userId, name)
                           │   (lazy in ChildHeroHomePage)
```
**XP-Kurve:** `Hero.calculateXPForLevel()`; Service: `lib/services/level_service.dart`.

---

### P9 — Streak & Streak-Bonus
```
Auslöser                   │ System
───────────────────────────┼────────────────────────────────
Quest approved (P5)        │ HeroProvider.recordActivity(userId)
                           │   ├─ StreakService.hasActivityToday?
                           │   ├─ StreakService.calculateStreak()
                           │   ├─ longestStreak ggf. hochsetzen
                           │   ├─ Meilenstein erreicht?
                           │   │   → onStreakMilestone → Notification (streakMilestone, 🔥)
                           │   └─ Streak verloren?
                           │       → onStreakLost → Notification (streakLost, 💔)
Cold Start (optional)      │ HeroProvider.checkStreak(userId)
                           │   (zurzeit **nicht** automatisch beim App-Start aufgerufen)
Bonus-Anwendung (P5)       │ HeroProvider.getStreakBonus(userId)  → Multiplier
                           │ HeroProvider.getStreakBonusPercent() → Anzeige
```
**Anker:** `lib/providers/hero_provider.dart:108-188`, `lib/services/streak_service.dart`

---

### P10 — Benachrichtigungen
`NotificationProvider` ist Inbox-artig (pro `userId`, `isRead`, Typ-getaggt).
Erzeugt werden Notifications **aus Provider-Callbacks heraus**, nicht direkt aus der UI:

| Trigger (Prozess) | Empfänger | Typ | Quelle |
|---|---|---|---|
| Quest abgeschlossen (P5) | Parent (creator) | `questCompleted` | `QuestProvider.completeQuest` |
| Quest genehmigt (P5) | Kind | `questApproved` | `main.dart` onQuestApproved |
| Quest abgelehnt (P5) | Kind | `questRejected` | `QuestProvider.rejectQuest` |
| Einlösung angefragt (P6) | Parent (reward-creator) | `rewardRedeemed` | `RewardProvider.requestRedemption` |
| Level-Up (P8) | Kind | `levelUp` | `main.dart` onLevelUp |
| Streak-Meilenstein (P9) | Kind | `streakMilestone` | `main.dart` onStreakMilestone |
| Streak verloren (P9) | Kind | `streakLost` | `main.dart` onStreakLost |

Nicht verdrahtete Typen: `rewardPurchased`, `achievementUnlocked`
(siehe §5.1).

**Anzeige:** `NotificationsPage`, Glocke im Parent-Dashboard.

---

### P11 — Achievements (⚠️ nicht verdrahtet)
Struktur vorhanden, Flow fehlt:
- **Definition:** `lib/data/default_achievements.dart` mit statischer Liste (`defaultAchievements`).
- **Provider:** `AchievementProvider` kann `initialize`, `checkAchievements`, `unlockAchievement`.
- **UI:** `AchievementsPage` (Tabs nach Kategorie) rendert `getAchievementsWithProgress`.

**Lücken (siehe §5.1):**
1. `AchievementProvider.initialize(defaultAchievements)` wird **nirgends** aufgerufen
   → die Liste `_achievements` bleibt leer.
2. `checkAchievements` wird **nirgends** nach Quest-Approval / Points-Update getriggert
   → keine Freischaltungen möglich.
3. Der `onAchievementUnlocked`-Callback wird in `main.dart` **nicht** an die
   `NotificationProvider` angeschlossen → selbst bei manueller Freischaltung
   würde keine Notification entstehen.

---

## 4. Provider-Landkarte (Cross-Provider-Verdrahtung)

```
                    ┌─────────────────────┐
                    │   AuthProvider      │  Family + Members + currentUser
                    └────────┬────────────┘
                             │ (UserId, isParent)
          ┌──────────────────┼──────────────────────────┐
          ▼                  ▼                          ▼
┌──────────────────┐  ┌──────────────────┐   ┌──────────────────┐
│  QuestProvider   │─▶│ NotificationProv │◀──│  RewardProvider  │
│  onQuestApproved │  │ (Inbox)          │   │ (setPointsProv)  │
└──────┬───────────┘  └──────────────────┘   └────────┬─────────┘
       │ callback (main.dart)                          │ spend/earn
       ▼                                               ▼
┌──────────────────┐                         ┌──────────────────┐
│  HeroProvider    │────── addXP / bonus ───▶│  PointsProvider  │
│  recordActivity  │                         │  Accounts + Txn  │
│  onLevelUp       │                         └──────────────────┘
│  onStreakMilest. │
│  onStreakLost    │
└──────┬───────────┘
       │ (zukünftig)
       ▼
┌──────────────────┐
│ AchievementProv. │   ⚠️ nicht verdrahtet
└──────────────────┘
```
**Quelle:** `lib/main.dart:61-162` (`_connectProviders`)

---

## 5. Identifizierte Lücken (Gap-Liste)

### 5.1 Achievements nicht aktiv (hohe Priorität)
- Kein Seeding: `AchievementProvider.initialize(defaultAchievements)` wird nie aufgerufen.
- Kein Trigger: `checkAchievements(heroId, context)` wird nie aufgerufen; der
  gesamte Freischalt-Pfad ist tot. `AchievementsPage` zeigt deshalb im
  besten Fall leere Listen.
- Callback nicht verdrahtet: `onAchievementUnlocked` hängt nicht an
  `NotificationProvider` / `Hero.addBadge`.

### 5.2 Persistente Stores werden nicht initial geladen
- `PointsProvider.loadData()`, `RewardProvider.loadData()`,
  `AchievementProvider.loadData()` sind definiert, werden aber **nirgends** im
  Bootstrap aufgerufen.
- Nur `AuthProvider.initialize()`, `NotificationProvider.loadData()` sowie
  `HeroProvider.loadData()` (lazy in `ChildHeroHomePage`) und
  `QuestProvider.loadQuests()` (lazy in mehreren Pages) werden getriggert.
- Folge: Rewards und Transaktionen beim Cold-Start sichtbar nur in den Seiten,
  die eine eigene Ladelogik anstoßen. Im Shop fehlt z. B. ein explizites
  `RewardProvider.loadData()` — Rewards sind erst nach Erstellung in der
  Session sichtbar.

### 5.3 Streak-Check beim App-Start
`HeroProvider.checkStreak(userId)` würde einen während der Abwesenheit verlorenen
Streak erkennen — wird jedoch beim Login/Splash nicht gerufen.

### 5.4 Familienmitglied Bearbeitung / Löschen / PIN-Reset
`AuthProvider` bietet nur `createFamily`, `addMember`, `login`, `logout`,
`switchUser`. Es fehlen `updateMember`, `removeMember`, `setPin`.
`FamilyManagementPage` ist demzufolge lesender und hinzufügender Natur.

### 5.5 Series-Quests
`incrementSeriesProgress` existiert und `QuestInstance.progress` wird gepflegt,
jedoch gibt es in der Child-UI keinen durchgängigen „+1"-Flow; Ablauf in der
`QuestDetailPage` nutzt die Funktion nur punktuell.

### 5.6 Reward-Käufe erzeugen keine Notification
`NotificationType.rewardPurchased` ist deklariert, aber nicht verdrahtet.

### 5.7 Legacy-/ungenutzte Artefakte
Laut Grep nicht referenziert oder nicht mehr Teil der aktiven Navigation:
- `lib/pages/challenges_page.dart` + `lib/providers/challenge_provider.dart` + `lib/views/challenges_view.dart`
- `lib/views/eaties_view.dart`, `lib/models/eaty.dart`
- `lib/models/mochi_point.dart`, `lib/models/cart_item.dart`
`ChallengeProvider` wird zwar in `main.dart` registriert, aber von keiner
aktiven Seite konsumiert. Kandidaten für §6.

### 5.8 Fehlende Tests
`flutter test` ist lt. `CLAUDE.md` vorgesehen, aber dieser Analyse ist nicht
sichtbar geworden, dass Provider-/Service-Tests existieren.
(Pfad `test/` wurde hier nicht verifiziert — bitte im Zuge des SOLL-Konzepts prüfen.)

### 5.9 Doppelpfad für `HeroHomePage`
`lib/pages/hero_home_page.dart` ist ein Wrapper, der auf
`lib/pages/child/hero_home_page.dart` weiterleitet. Das ist kurzlebig und
sollte bereinigt werden, sobald alle Referenzen auf die Child-Variante zeigen.

---

## 6. Empfohlene Aufräumarbeiten
- **Legacy entfernen** (siehe §5.7): Challenge-/Eaty-Reste, `MochiPoint`, `CartItem`
  entfernen oder klar als Altlast markieren.
- **Routen konsolidieren:** Wrapper `hero_home_page.dart` auflösen.
- **Bootstrap zentralisieren:** Alle `loadData()`-Aufrufe in der `SplashPage` oder in
  einem dedizierten `AppBootstrap`-Service, damit jeder Provider einmal deterministisch
  lädt, bevor das erste Dashboard öffnet.
- **Achievement-Flow verdrahten** (siehe §5.1).

---

## 7. Zuordnung zum bestehenden Testplan

`docs/TESTPLAN_SWIMLANES.md` deckt heute drei Ober-SwimLanes ab
(Parent, Child, Navigation). Diese decken P2–P6 und P3/P10 teilweise. **Nicht**
abgedeckt sind bisher:

| Prozess | Abdeckung Testplan |
|---|---|
| P1 Bootstrap / Routing | fehlt |
| P7 Punktekonto & Transaktionen (History) | fehlt |
| P8 Level-Up / XP-Overflow | fehlt |
| P9 Streak (Milestone, Loss) | fehlt |
| P10 Notification-Inbox | fehlt (nur implizit) |
| P11 Achievements | fehlt (weil noch nicht wirksam) |

Empfehlung: Testplan beim Schließen von §5 um diese Fälle ergänzen.

---

## 8. Schnellreferenz — Datei-Anker

| Bereich | Pfad |
|---|---|
| App-Entry / Provider-Wiring | `lib/main.dart` |
| Auth & Family | `lib/providers/auth_provider.dart`, `lib/pages/login_page.dart`, `lib/pages/setup/*` |
| Quests | `lib/providers/quest_provider.dart`, `lib/pages/parent/quest_*`, `lib/pages/child/quest_board_page.dart`, `lib/pages/quest_detail_page.dart` |
| Rewards / Shop | `lib/providers/reward_provider.dart`, `lib/pages/child/shop_page.dart`, `lib/pages/child/my_rewards_page.dart`, `lib/pages/parent/reward_*`, `lib/pages/parent/redemption_page.dart` |
| Points | `lib/providers/points_provider.dart`, `lib/pages/transaction_history_page.dart` |
| Hero / XP / Avatar | `lib/providers/hero_provider.dart`, `lib/services/level_service.dart`, `lib/pages/appearance_settings_page.dart`, `lib/pages/child/hero_customization_page.dart` |
| Streak | `lib/services/streak_service.dart`, `lib/providers/hero_provider.dart` |
| Achievements | `lib/providers/achievement_provider.dart`, `lib/data/default_achievements.dart`, `lib/pages/achievements_page.dart` |
| Notifications | `lib/providers/notification_provider.dart`, `lib/pages/notifications_page.dart`, `lib/pages/notification_settings_page.dart` |
| Persistenz | `lib/services/storage_service.dart` (SharedPreferences) |
| UI-System | `lib/theme/*`, `lib/widgets/*` (Glass-Komponenten, App-Buttons) |
