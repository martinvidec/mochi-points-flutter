# Mochi Points MVP - Phasenplan

## Übersicht

Transformation der bestehenden App in eine gamifizierte Familien-Rewards-App mit:
- Parent/Child Rollen
- Quest-System (Daily, Weekly, Epic, Series)
- Hero mit Level, XP, Streaks
- Belohnungs-Shop
- Achievement-System

**Geschätzte Gesamtdauer**: 60-80 Stunden (10 Phasen, ~45 Tasks)

---

## Phase 1: Foundation (Models & Persistence)

**Ziel**: Alle Datenmodelle erstellen und Persistenz etablieren

### Issue 1.1: Core Enums erstellen
```
Erstelle lib/models/enums.dart mit allen Enumerationen:
- UserRole (parent, child)
- QuestType (daily, weekly, epic, series)
- QuestRarity (common, rare, epic, legendary)
- QuestStatus (available, inProgress, pendingApproval, completed, expired)
- RewardCategory (experience, item, privilege, custom)
- PurchaseStatus (purchased, redeemed, expired, cancelled)
- TransactionType (questComplete, purchase, bonus, adjustment, refund)
- AchievementTier (bronze, silver, gold, platinum)
- AchievementCategory (streak, quests, points, special)

Akzeptanzkriterien:
- Alle Enums kompilieren fehlerfrei
- Export aus einer Datei
```

### Issue 1.2: User & Family Models
```
Erstelle lib/models/user.dart und lib/models/family.dart

User Model:
- id, familyId, name, email, role (UserRole), avatarUrl, createdAt
- isParent/isChild Getter
- toJson(), fromJson(), copyWith()

Family Model:
- id, name, inviteCode (optional), createdAt
- toJson(), fromJson(), copyWith()

Akzeptanzkriterien:
- JSON Serialisierung funktioniert (Roundtrip-Test)
- User hat role Property
```

### Issue 1.3: Hero Model
```
Erstelle lib/models/hero.dart

Hero Model:
- id, userId, name, level, currentXP, xpToNextLevel
- currentStreak, longestStreak, lastActiveDate
- unlockedItems[], equippedItems[], badges[]
- xpProgress Getter (0-1)
- title Getter basierend auf Level
- addXP(int) Methode mit Level-Up Logik
- toJson(), fromJson(), copyWith()

HeroAppearance Model:
- baseAvatar, skinColor, hairStyle, hairColor, outfit
- accessory (optional), pet (optional)

Akzeptanzkriterien:
- addXP() handhabt Level-Up korrekt
- XP Berechnung: Level 2 = 100 XP, dann +50 pro Level
```

### Issue 1.4: Quest & QuestInstance Models
```
Erstelle lib/models/quest.dart

Quest Model:
- id, familyId, createdBy, name, description, icon
- type (QuestType), rarity (QuestRarity)
- rewardPoints, rewardXP
- assignedTo[] (User IDs, leer = alle Kinder)
- deadline (optional), isActive, createdAt
- targetCount (für Series), unit (km, Minuten, etc.)
- isSeries, hasDeadline, isExpired Getter
- rarityColor Getter
- toJson(), fromJson(), copyWith()

QuestInstance Model:
- id, questId, childId, status (QuestStatus)
- progress, target, currentStreak
- startedAt, completedAt, approvedAt, approvedBy
- progressPercent, isComplete, isPending Getter

Akzeptanzkriterien:
- Series Quests unterstützen unlimited completion
- Deadline Support für Epic Quests
```

### Issue 1.5: Reward & Purchase Models
```
Erstelle lib/models/reward.dart und lib/models/purchase.dart

Reward Model:
- id, familyId, createdBy, name, description, icon
- price, category (RewardCategory)
- stock (optional, null = unlimited), isActive
- hasLimitedStock, isAvailable Getter

Purchase Model:
- id, rewardId, userId, quantity, totalPrice
- status (PurchaseStatus), purchasedAt
- redeemedAt, redeemedBy (optional)
- isRedeemed, canRedeem Getter

Akzeptanzkriterien:
- Stock-Management funktioniert
- Redemption-Status korrekt
```

### Issue 1.6: Transaction & PointsAccount Models
```
Erstelle lib/models/transaction.dart und lib/models/points_account.dart

Transaction Model:
- id, userId, type (TransactionType)
- amount (positiv = earned, negativ = spent)
- balanceAfter, referenceId, description, createdAt
- isEarned, isSpent Getter

PointsAccount Model:
- userId, balance, totalEarned, totalSpent, lastUpdated
- canAfford(price) Methode
- earn(amount), spend(amount) → neue Instanz

Akzeptanzkriterien:
- Immutable Pattern mit copyWith
- Transaction History vollständig
```

### Issue 1.7: Achievement Models
```
Erstelle lib/models/achievement.dart

Achievement Model:
- id, name, description, icon
- tier (AchievementTier), category (AchievementCategory)
- condition (String), targetValue (optional)
- rewardXP, rewardPoints, rewardItem
- isSecret (bool)
- tierColor Getter

AchievementProgress Model:
- id, heroId, achievementId
- currentProgress, targetProgress
- isUnlocked, unlockedAt
- progressPercent Getter

Akzeptanzkriterien:
- Alle Felder serialisierbar
- Progress-Tracking funktioniert
```

### Issue 1.8: StorageService erweitern
```
Modifiziere lib/services/storage_service.dart

Neue Methoden:
- saveList<T>(key, list, toJson) - Liste speichern
- loadList<T>(key, fromJson) - Liste laden
- saveObject<T>(key, object, toJson) - Objekt speichern
- loadObject<T>(key, fromJson) - Objekt laden
- remove(key) - Löschen
- clear() - Alles löschen (für Tests)

Error Handling:
- Try-catch mit Fallback-Werten
- Logging bei Fehlern

Akzeptanzkriterien:
- Generische Methoden funktionieren mit allen Models
- Fehlerbehandlung robust
```

---

## Phase 2: Authentication & User Roles

**Ziel**: Lokale Benutzerauthentifizierung mit rollenbasierten Views
**Voraussetzung**: Phase 1 abgeschlossen

### Issue 2.1: AuthProvider erstellen
```
Erstelle lib/providers/auth_provider.dart

Properties:
- currentUser (User?)
- currentFamily (Family?)
- familyMembers (List<User>)

Getter:
- isLoggedIn, isParent, isChild
- children (nur Kind-User)
- parents (nur Eltern-User)

Methoden:
- initialize() - Lädt Family und letzten User
- login(userId, pin?) - Setzt currentUser
- logout() - Setzt currentUser = null
- switchUser(userId) - Wechselt User
- createFamily(name) - Erstellt neue Familie
- addMember(name, role, pin?) - Fügt Mitglied hinzu

Persistenz:
- Family in SharedPreferences
- Members in SharedPreferences
- LastUserId in SharedPreferences

Akzeptanzkriterien:
- Login/Logout funktioniert
- Letzter User wird beim Start geladen
```

### Issue 2.2: Login Page erstellen
```
Erstelle lib/pages/login_page.dart
Erstelle lib/widgets/user_avatar_button.dart

Login Page:
- Zeigt alle Familienmitglieder als Avatar-Buttons
- Tap auf Avatar → PIN Dialog (wenn PIN gesetzt)
- Nach Login → Route zu Dashboard

UserAvatarButton Widget:
- Zeigt Avatar/Initiale, Name, Rolle-Badge
- Ausgewählt-State mit Rahmen

Akzeptanzkriterien:
- Alle Familienmitglieder werden angezeigt
- PIN-Eingabe funktioniert (optional)
- Routing nach Login korrekt
```

### Issue 2.3: Family Setup Flow
```
Erstelle lib/pages/setup/family_setup_page.dart
Erstelle lib/pages/setup/add_member_page.dart

FamilySetupPage:
- Schritt 1: Familienname eingeben
- Schritt 2: Ersten Elternteil erstellen (required)
- Schritt 3: Weitere Mitglieder hinzufügen (optional)
- "Fertig" Button → Login Page

AddMemberPage:
- Name eingeben
- Rolle wählen (Parent/Child)
- Einfacher Avatar wählen (Farbe + Initiale)
- Optionale PIN setzen

Akzeptanzkriterien:
- Familie kann erstellt werden
- Mindestens ein Elternteil required
- Kinder können hinzugefügt werden
```

### Issue 2.4: App Routing mit Auth
```
Modifiziere lib/main.dart

Routing Logik:
1. App Start → Check ob Family existiert
2. Keine Family → FamilySetupPage
3. Family existiert → LoginPage
4. Nach Login:
   - Parent → ParentDashboardPage
   - Child → HeroHomePage

Provider Registration:
- AuthProvider hinzufügen
- Andere Provider anpassen für Multi-User

Akzeptanzkriterien:
- Routing funktioniert für alle Fälle
- Provider korrekt registriert
```

---

## Phase 3: Quest System

**Ziel**: Vollständiges Quest CRUD und Workflow
**Voraussetzung**: Phase 2 abgeschlossen

### Issue 3.1: QuestProvider erstellen
```
Erstelle lib/providers/quest_provider.dart

Properties:
- quests (List<Quest>)
- instances (Map<String, List<QuestInstance>>) - per childId

Getter:
- availableQuests(childId) - Quests die angenommen werden können
- activeQuests(childId) - In Bearbeitung
- pendingApproval - Warten auf Eltern-Bestätigung
- completedToday(childId) - Heute abgeschlossen

Methoden:
- loadQuests() - Aus Storage laden
- createQuest(Quest) - Neue Quest erstellen
- updateQuest(Quest) - Quest bearbeiten
- deleteQuest(questId) - Quest löschen
- acceptQuest(questId, childId) - QuestInstance erstellen
- completeQuest(instanceId) - Status → pendingApproval
- approveQuest(instanceId, parentId) - Status → completed, Points vergeben
- rejectQuest(instanceId, reason?) - Zurück zu inProgress
- incrementSeriesProgress(instanceId, amount) - Für Series Quests

Persistenz:
- Quests in SharedPreferences
- QuestInstances in SharedPreferences

Akzeptanzkriterien:
- Alle CRUD Operationen funktionieren
- Quest Workflow komplett
- Series Quests können mehrfach completed werden
```

### Issue 3.2: Quest Board Page (Child)
```
Erstelle lib/pages/child/quest_board_page.dart
Erstelle lib/widgets/quest_card.dart

QuestBoardPage:
- Tab-Filter: Alle, Daily, Weekly, Epic, Series
- Liste der verfügbaren Quests
- Aktive Quests Section oben
- Pull-to-refresh

QuestCard Widget:
- Icon + Name
- Rarity Badge (Farbe)
- Points + XP Anzeige
- Progress Bar (für Series/Daily mit Wiederholung)
- Status Badge (available, inProgress, pending)
- Streak Anzeige (wenn > 0)

Akzeptanzkriterien:
- Filter funktioniert
- Cards zeigen alle relevanten Infos
- Tap öffnet Detail Page
```

### Issue 3.3: Quest Detail Page
```
Erstelle lib/pages/quest_detail_page.dart

Inhalt:
- Großes Icon + Name
- Beschreibung
- Rarity + Typ Badge
- Points + XP Belohnung
- Deadline (wenn gesetzt)
- Aktuelle Streak
- Progress (für Series)

Actions (basierend auf Status):
- available: "Quest annehmen" Button
- inProgress: "Als erledigt markieren" Button
- inProgress (Series): "+1" Button für Fortschritt
- pendingApproval: "Warte auf Bestätigung" (disabled)
- completed: Checkmark

Akzeptanzkriterien:
- Alle Status korrekt dargestellt
- Actions funktionieren
```

### Issue 3.4: Quest Management (Parent)
```
Erstelle lib/pages/parent/quest_management_page.dart
Erstelle lib/pages/parent/quest_edit_page.dart

QuestManagementPage:
- Liste aller Quests
- Filter nach Typ
- Swipe to delete
- FAB für neue Quest

QuestEditPage:
- Name (TextField)
- Beschreibung (TextField, optional)
- Icon Picker (Grid mit Icons)
- Typ Auswahl (Chips: Daily, Weekly, Epic, Series)
- Rarity Auswahl (Chips mit Farben)
- Points Eingabe (Number)
- XP Eingabe (Number, default = points * 10)
- Zuweisen an (MultiSelect: Alle oder spezifische Kinder)
- Deadline (DatePicker, nur bei Epic)
- Für Series: Einheit (km, Minuten, Stück, etc.)

Akzeptanzkriterien:
- Quest erstellen funktioniert
- Quest bearbeiten funktioniert
- Validierung (Name required, Points > 0)
```

### Issue 3.5: Approval Queue (Parent)
```
Erstelle lib/pages/parent/approval_page.dart
Erstelle lib/widgets/approval_card.dart

ApprovalPage:
- Liste aller pendingApproval Quests
- Gruppiert nach Kind
- Leer-State wenn nichts zu tun

ApprovalCard:
- Kind Name + Avatar
- Quest Name + Icon
- Datum der Completion
- "Bestätigen" Button (grün)
- "Ablehnen" Button (rot, öffnet Dialog für Grund)

Nach Bestätigung:
- Points an Kind vergeben
- XP an Kind vergeben
- Quest Status → completed
- Snackbar mit Erfolg

Akzeptanzkriterien:
- Alle pending Quests sichtbar
- Approve vergibt Points + XP
- Reject mit optionalem Grund
```

---

## Phase 4: Points & Transactions

**Ziel**: Robustes Punkte-System mit Transaction History
**Voraussetzung**: Phase 3 abgeschlossen

### Issue 4.1: PointsProvider erstellen
```
Erstelle lib/providers/points_provider.dart
Lösche lib/providers/mochi_point_account_provider.dart
Lösche lib/providers/mochi_point_provider.dart

Properties:
- accounts (Map<String, PointsAccount>) - per userId
- transactions (Map<String, List<Transaction>>) - per userId

Getter:
- balance(userId) - Aktueller Kontostand
- weeklyEarned(userId) - Diese Woche verdient
- recentTransactions(userId, limit) - Letzte N Transaktionen

Methoden:
- initialize(userId) - Account erstellen falls nicht existiert
- earn(userId, amount, type, referenceId?, description?)
- spend(userId, amount, referenceId, description)
- getTransactionHistory(userId, filter?)

Akzeptanzkriterien:
- Jeder User hat eigenen Account
- Alle Transaktionen werden geloggt
- Balance kann nicht negativ werden
```

### Issue 4.2: Points Display Widget
```
Erstelle lib/widgets/points_display.dart

Varianten:
- compact: Nur Zahl + Icon (für Header)
- large: Große Zahl mit Label (für Dashboard)
- animated: Count-up Animation bei Änderung

Props:
- points (int)
- variant (compact, large)
- showChange (bool) - "+10" Animation
- changeAmount (int)

Styling:
- Gold/Amber Farbe (#FFE66D)
- Mochi Icon oder ✨
- Schatten für Tiefe

Akzeptanzkriterien:
- Beide Varianten funktionieren
- Animation smooth
```

### Issue 4.3: Transaction History Page
```
Erstelle lib/pages/transaction_history_page.dart

Inhalt:
- Aktueller Balance oben
- Filter Chips: Alle, Verdient, Ausgegeben
- Chronologische Liste

Transaction Item:
- Icon basierend auf Type
- Description oder Reference Name
- Datum + Zeit
- Amount (+/- mit Farbe)
- Balance nach Transaction

Akzeptanzkriterien:
- Filter funktioniert
- Alle Transaktionen sichtbar
- Datum korrekt formatiert
```

---

## Phase 5: Reward Shop

**Ziel**: Belohnungs-Erstellung (Parent) und Kauf (Child)
**Voraussetzung**: Phase 4 abgeschlossen

### Issue 5.1: RewardProvider erstellen
```
Erstelle lib/providers/reward_provider.dart
Lösche lib/providers/eaty_provider.dart
Lösche lib/providers/cart_item_provider.dart

Properties:
- rewards (List<Reward>)
- purchases (Map<String, List<Purchase>>) - per userId

Getter:
- availableRewards - Aktive mit Stock > 0
- userPurchases(userId) - Käufe eines Users
- pendingRedemptions - Warten auf Einlösung
- purchaseHistory(userId) - Alle Käufe

Methoden:
- createReward(Reward)
- updateReward(Reward)
- deleteReward(rewardId)
- purchaseReward(rewardId, userId) - Erstellt Purchase, zieht Points ab
- requestRedemption(purchaseId) - Status → pending
- confirmRedemption(purchaseId, parentId) - Status → redeemed

Akzeptanzkriterien:
- Kauf zieht Points ab
- Stock wird reduziert
- Redemption Workflow funktioniert
```

### Issue 5.2: Shop Page (Child)
```
Erstelle lib/pages/child/shop_page.dart
Erstelle lib/widgets/reward_card.dart

ShopPage:
- Aktueller Balance oben
- Grid von Reward Cards
- Kategorie Filter (optional)

RewardCard:
- Icon + Name
- Preis in Points
- Stock Anzeige (wenn limited)
- "Kaufen" Button
- Locked Overlay wenn nicht genug Points

Kauf Flow:
1. Tap "Kaufen"
2. Confirmation Dialog
3. Bei Erfolg: Konfetti + Snackbar
4. Bei Fehler: Error Message

Akzeptanzkriterien:
- Alle Rewards sichtbar
- Locked State korrekt
- Kauf funktioniert
```

### Issue 5.3: My Rewards Page (Child)
```
Erstelle lib/pages/child/my_rewards_page.dart

Inhalt:
- Tabs: Aktiv, Eingelöst
- Liste der gekauften Rewards

Purchase Card:
- Reward Icon + Name
- Kaufdatum
- Status Badge
- "Einlösen" Button (wenn purchased)

Einlösen Flow:
1. Tap "Einlösen"
2. Confirmation: "Zeige dies einem Elternteil"
3. Status → pending
4. Eltern bestätigen separat

Akzeptanzkriterien:
- Alle Käufe sichtbar
- Status korrekt angezeigt
- Einlösen funktioniert
```

### Issue 5.4: Reward Management (Parent)
```
Erstelle lib/pages/parent/reward_management_page.dart
Erstelle lib/pages/parent/reward_edit_page.dart

RewardManagementPage:
- Liste aller Rewards
- Aktiv/Inaktiv Toggle
- Swipe to delete
- FAB für neue Reward

RewardEditPage:
- Name (TextField)
- Beschreibung (TextField, optional)
- Icon Picker
- Preis (Number)
- Kategorie (Dropdown)
- Stock (Number, optional - leer = unlimited)
- Aktiv Toggle

Akzeptanzkriterien:
- CRUD funktioniert
- Validierung (Name + Preis required)
```

### Issue 5.5: Redemption Approval (Parent)
```
Erstelle lib/pages/parent/redemption_page.dart

Inhalt:
- Pending Redemptions Liste
- History Tab

Redemption Card:
- Kind Name + Avatar
- Reward Name + Icon
- Kaufdatum
- "Bestätigen" Button
- "Ablehnen" Button (refund)

Nach Bestätigung:
- Status → redeemed
- Datum speichern
- Snackbar

Bei Ablehnung:
- Points zurückerstatten
- Purchase löschen oder Status setzen

Akzeptanzkriterien:
- Alle pending Redemptions sichtbar
- Confirm/Reject funktioniert
```

---

## Phase 6: Hero & Progression

**Ziel**: Hero Avatar mit Level und XP System
**Voraussetzung**: Phase 4 abgeschlossen

### Issue 6.1: HeroProvider erstellen
```
Erstelle lib/providers/hero_provider.dart

Properties:
- heroes (Map<String, Hero>) - per userId

Getter:
- currentHero - Hero des eingeloggten Users
- heroForUser(userId)

Methoden:
- initialize(userId, name) - Hero erstellen
- addXP(userId, amount) - XP hinzufügen, Level-Up prüfen
- updateStreak(userId) - Streak aktualisieren
- equipItem(userId, itemId)
- unequipItem(userId, itemId)

Events:
- onLevelUp - Callback für Animation

Akzeptanzkriterien:
- Jedes Kind hat einen Hero
- XP führt zu Level-Up
- Persistenz funktioniert
```

### Issue 6.2: LevelService erstellen
```
Erstelle lib/services/level_service.dart

Statische Methoden:
- xpForLevel(level) - Kumulative XP für Level
- xpBetweenLevels(fromLevel) - XP zum nächsten Level
- levelForXP(totalXP) - Level basierend auf XP
- progressToNextLevel(totalXP) - 0.0 bis 1.0
- titleForLevel(level) - "Mochi Novice", etc.

XP Formel:
- Level 2: 100 XP
- Level 3: 250 XP (100 + 150)
- Level 4: 450 XP (250 + 200)
- Formel: 100 + (level-1) * 50 pro Level

Titles:
- 1-10: "Mochi Novice"
- 11-25: "Mochi Apprentice"
- 26-50: "Mochi Champion"
- 51+: "Mochi Legend"

Akzeptanzkriterien:
- Berechnungen korrekt
- Unit Tests bestehen
```

### Issue 6.3: Hero Card Widget
```
Erstelle lib/widgets/hero_card.dart

Inhalt:
- Avatar (Kreis mit Farbe + Initiale)
- Name
- Level + Title
- XP Progress Bar
- Streak Fire Icon mit Zahl

Styling:
- Gradient Background basierend auf Level-Tier
- Glow Effekt
- Animierte XP Bar

Props:
- hero (Hero)
- compact (bool) - Kleinere Version
- onTap (optional)

Akzeptanzkriterien:
- Alle Infos korrekt angezeigt
- Gradient ändert sich mit Level
```

### Issue 6.4: Hero Home Page (Child Dashboard)
```
Erstelle lib/pages/child/hero_home_page.dart

Layout:
1. Hero Card (groß, oben)
2. Points Display
3. "Heute's Quests" Section
   - Zeigt Daily Quests für heute
   - Progress Indikatoren
4. Quick Actions
   - "Alle Quests" Button
   - "Shop" Button

Navigation:
- Bottom Navigation Bar mit:
  - Home (Hero Home)
  - Quests (Quest Board)
  - Shop
  - Rewards (My Rewards)
  - Stats/Achievements

Akzeptanzkriterien:
- Dashboard zeigt alle wichtigen Infos
- Navigation funktioniert
```

### Issue 6.5: XP Integration in Quest Approval
```
Modifiziere lib/providers/quest_provider.dart

Bei approveQuest():
1. Points vergeben (via PointsProvider)
2. XP vergeben (via HeroProvider)
3. Streak aktualisieren (via HeroProvider)
4. Achievement Check triggern (später)

XP Menge:
- Aus Quest.rewardXP
- Default: rewardPoints * 10

Akzeptanzkriterien:
- XP wird bei Approval vergeben
- Level-Up wird erkannt
```

---

## Phase 7: Streak System

**Ziel**: Tägliche Aktivität tracken und Streak Boni
**Voraussetzung**: Phase 6 abgeschlossen

### Issue 7.1: StreakService erstellen
```
Erstelle lib/services/streak_service.dart

Statische Methoden:
- calculateStreak(activityDates) - Aktuelle Streak berechnen
- streakBonusMultiplier(streak) - Bonus Prozent
- checkStreakMilestone(oldStreak, newStreak) - Milestone erreicht?
- isStreakActive(lastActiveDate) - Streak noch aktiv?

Streak Logik:
- Aktivität heute ODER gestern = Streak aktiv
- Konsekutive Tage zählen rückwärts

Bonus Multiplikatoren:
- 0-6 Tage: 1.0x (kein Bonus)
- 7-13 Tage: 1.1x (+10%)
- 14-29 Tage: 1.15x (+15%)
- 30-99 Tage: 1.25x (+25%)
- 100+ Tage: 1.5x (+50%)

Milestones: 7, 14, 30, 60, 100, 365

Akzeptanzkriterien:
- Streak Berechnung korrekt
- Bonus korrekt
- Milestones erkannt
```

### Issue 7.2: Streak Tracking in HeroProvider
```
Modifiziere lib/providers/hero_provider.dart

Neue Properties in Hero:
- activityDates (List<DateTime>)

Neue Methoden:
- recordActivity(userId) - Heute zu activityDates hinzufügen
- checkStreak(userId) - Streak neu berechnen

Bei recordActivity():
1. Datum hinzufügen (wenn nicht bereits vorhanden)
2. Streak berechnen
3. longestStreak aktualisieren
4. Milestone Check
5. Speichern

Akzeptanzkriterien:
- Aktivität wird geloggt
- Streak wird berechnet
- Streak Loss wird erkannt
```

### Issue 7.3: Streak Widget
```
Erstelle lib/widgets/streak_widget.dart

Varianten:
- compact: Nur 🔥 + Zahl
- expanded: Wochenansicht mit Tagen

Expanded View:
- 7 Kreise für Mo-So
- Gefüllt = Aktivität
- Heute = Pulsierend
- Zukunft = Grau Outline

Animation:
- Feuer Animation bei Milestone
- Wackeln bei Streak Erhöhung

Props:
- streak (int)
- variant (compact, expanded)
- activityDates (für expanded)

Akzeptanzkriterien:
- Beide Varianten funktionieren
- Animation bei Änderung
```

### Issue 7.4: Streak Bonus auf Points
```
Modifiziere lib/providers/quest_provider.dart

Bei approveQuest():
1. Base Points aus Quest
2. Streak Bonus berechnen
3. Bonus Points = Base * (Multiplier - 1)
4. Total = Base + Bonus
5. Beide separat anzeigen

UI Anzeige:
- "5 MP + 0.5 Bonus (🔥 7)"

Akzeptanzkriterien:
- Bonus wird berechnet
- Bonus wird in Transaction geloggt
- UI zeigt Bonus separat
```

---

## Phase 8: Achievements

**Ziel**: Achievement System mit 15 Badges
**Voraussetzung**: Phase 7 abgeschlossen

### Issue 8.1: AchievementProvider erstellen
```
Erstelle lib/providers/achievement_provider.dart

Properties:
- achievements (List<Achievement>) - Alle definierten
- progress (Map<String, List<AchievementProgress>>) - per heroId

Methoden:
- initialize() - Default Achievements laden
- checkAchievements(heroId, context) - Alle Conditions prüfen
- unlockAchievement(heroId, achievementId) - Freischalten
- getProgress(heroId, achievementId) - Einzelner Progress

Context für Checks:
- questsCompleted
- epicQuestsCompleted
- currentStreak
- longestStreak
- totalPointsEarned
- rewardsPurchased

Akzeptanzkriterien:
- Achievements werden geprüft
- Unlock funktioniert
- Progress wird getrackt
```

### Issue 8.2: Default Achievements definieren
```
Erstelle lib/data/default_achievements.dart

15 Achievements:

Streak (4):
1. "Feuerstarter" - 7 Tage Streak (Bronze)
2. "Flammenmeister" - 14 Tage Streak (Silver)
3. "Unaufhaltsam" - 30 Tage Streak (Gold)
4. "Legende" - 100 Tage Streak (Platinum)

Quests (4):
5. "Erster Schritt" - 1 Quest (Bronze)
6. "Fleißige Biene" - 50 Quests (Silver)
7. "Quest-Meister" - 100 Quests (Gold)
8. "Held" - 1 Epic Quest (Gold)

Points (3):
9. "Sammler" - 100 Points verdient (Bronze)
10. "Schatzjäger" - 500 Points verdient (Silver)
11. "Goldgrube" - 1000 Points verdient (Gold)

Special (4):
12. "Shopper" - Erste Belohnung gekauft (Bronze)
13. "Frühaufsteher" - Quest vor 7 Uhr (Silver, Secret)
14. "Nachtaktiv" - Quest nach 22 Uhr (Silver, Secret)
15. "Perfekte Woche" - 7 Tage alle Dailies (Gold)

Akzeptanzkriterien:
- Alle 15 definiert
- Mix aus Tiers
- 2 Secret Achievements
```

### Issue 8.3: Achievement Badge Widget
```
Erstelle lib/widgets/achievement_badge.dart

States:
- Locked: Grau, Fragezeichen (oder Icon wenn nicht secret)
- InProgress: Farbig mit Progress Bar
- Unlocked: Voll farbig mit Glanz

Inhalt:
- Icon (groß)
- Name
- Tier Rahmen (Bronze/Silver/Gold/Platinum Farbe)
- Progress (X/Y)

Animation:
- Glanz-Sweep bei Unlocked
- Partikel bei frischem Unlock

Props:
- achievement (Achievement)
- progress (AchievementProgress)
- size (small, medium, large)

Akzeptanzkriterien:
- Alle States korrekt
- Tier Farben korrekt
```

### Issue 8.4: Achievements Page
```
Erstelle lib/pages/achievements_page.dart

Layout:
- Header mit Statistik (X/15 freigeschaltet)
- Kategorie Tabs: Alle, Streak, Quests, Points, Special
- Grid von Achievement Badges

Badge Tap:
- Dialog mit Details
- Beschreibung
- Belohnungen
- Progress (wenn nicht unlocked)

Akzeptanzkriterien:
- Alle Achievements sichtbar
- Filter funktioniert
- Details abrufbar
```

### Issue 8.5: Achievement Unlock Dialog
```
Erstelle lib/widgets/achievement_unlock_dialog.dart

Wird angezeigt wenn Achievement freigeschaltet

Inhalt:
- "Achievement Freigeschaltet!"
- Großes Badge Icon
- Name + Beschreibung
- Belohnungen (XP, Points, Items)
- "Toll!" Button

Animation:
- Fade In
- Badge Zoom
- Konfetti
- Belohnungen einsammeln Animation

Akzeptanzkriterien:
- Dialog erscheint bei Unlock
- Animation smooth
- Konfetti funktioniert
```

---

## Phase 9: UI Overhaul (Gaming Theme)

**Ziel**: Dark Gaming Theme mit Animationen
**Voraussetzung**: Phase 1-8 funktional

### Issue 9.1: Theme erstellen
```
Erstelle lib/theme/app_theme.dart
Erstelle lib/theme/app_colors.dart

AppColors:
- primaryGradient: [#FF6B6B, #FF8E53]
- background: [#1A1B2E, #2D2E4A]
- surface: #2A2B42
- surfaceElevated: #3A3B52
- gold: #FFE66D
- teal: #4ECDC4
- text: #FFFFFF
- textSecondary: #B8B8C8
- rarityCommon: #B8B8B8
- rarityRare: #4A9DFF
- rarityEpic: #A855F7
- rarityLegendary: #F59E0B

AppTheme:
- darkTheme() - Vollständiges ThemeData
- Typography mit Google Fonts (Nunito)

Akzeptanzkriterien:
- Theme kompiliert
- Alle Farben definiert
```

### Issue 9.2: Theme in App anwenden
```
Modifiziere lib/main.dart

Änderungen:
- Import AppTheme
- MaterialApp theme: AppTheme.darkTheme()
- Altes Theme entfernen

Akzeptanzkriterien:
- App verwendet neues Theme
- Keine harten Farbwerte mehr in Widgets
```

### Issue 9.3: Navigation überarbeiten
```
Modifiziere lib/widgets/bottom_navigation.dart

Neue Navigation:
- 5 Tabs (Parent oder Child spezifisch)
- Neue Icons passend zum Gaming Theme
- Badge Counts für Pending Items
- Selected State mit Glow
- Gradient Background

Child Tabs:
- Home (🏠)
- Quests (⚔️)
- Shop (🏪)
- Rewards (🎁)
- Profile (👤)

Parent Tabs:
- Home (🏠)
- Quests (⚔️)
- Rewards (🎁)
- Approve (✓) mit Badge
- Settings (⚙️)

Akzeptanzkriterien:
- Navigation rollenbasiert
- Badges zeigen Counts
- Styling passt zum Theme
```

### Issue 9.4: XP Progress Bar Widget
```
Erstelle lib/widgets/xp_progress_bar.dart

Features:
- Gradient Fill (Teal)
- Animierter Progress
- Shine Sweep Animation
- Level Markers

Props:
- currentXP (int)
- maxXP (int)
- level (int)
- animated (bool)

Animation:
- Fill Animation bei XP Gain
- Shine Sweep kontinuierlich
- Pulse bei fast Level-Up

Akzeptanzkriterien:
- Animation smooth
- Gradient korrekt
```

### Issue 9.5: Packages hinzufügen
```
Modifiziere pubspec.yaml

Neue Dependencies:
- flutter_animate: ^4.3.0
- confetti: ^0.7.0
- google_fonts: ^6.1.0
- percent_indicator: ^4.2.3
- shimmer: ^3.0.0

Akzeptanzkriterien:
- flutter pub get erfolgreich
- Keine Konflikte
```

---

## Phase 10: Testing & Polish

**Ziel**: Stabilität und User Experience
**Voraussetzung**: Phase 9 abgeschlossen

### Issue 10.1: Model Unit Tests
```
Erstelle test/models/quest_test.dart
Erstelle test/models/hero_test.dart
Erstelle test/services/level_service_test.dart
Erstelle test/services/streak_service_test.dart

Tests:
- JSON Serialisierung Roundtrip
- Level Berechnung
- Streak Berechnung
- Quest Status Transitions

Akzeptanzkriterien:
- Alle Tests grün
- Edge Cases abgedeckt
```

### Issue 10.2: Provider Integration Tests
```
Erstelle test/providers/quest_provider_test.dart
Erstelle test/providers/points_provider_test.dart

Tests:
- Quest Workflow (create → accept → complete → approve)
- Points Earn/Spend
- Transaction History
- Achievement Unlock

Akzeptanzkriterien:
- Workflow Tests bestehen
- Mocking korrekt
```

### Issue 10.3: Widget Tests
```
Modifiziere test/widget_test.dart
Erstelle test/widgets/quest_card_test.dart

Tests:
- App lädt korrekt
- Quest Card rendert
- Hero Card zeigt Level
- Navigation funktioniert

Akzeptanzkriterien:
- Widget Tests bestehen
```

### Issue 10.4: Quest Complete Animation
```
Erstelle lib/widgets/quest_complete_animation.dart

Sequence:
1. Screen Overlay
2. Quest Card zentriert
3. Checkmark Animation
4. Konfetti
5. Points Count-Up
6. XP Bar Fill
7. "Weiter" Button

Akzeptanzkriterien:
- Animation vollständig
- Timing korrekt
- Skip-fähig
```

### Issue 10.5: Level Up Animation
```
Erstelle lib/widgets/level_up_animation.dart

Sequence:
1. Full-Screen Overlay
2. "LEVEL UP!" Text
3. Alte → Neue Level Transition
4. Neuer Title (wenn geändert)
5. Partikel Explosion
6. Rewards Preview
7. "Weiter" Button

Akzeptanzkriterien:
- Animation episch
- Sound (optional)
- Haptic Feedback
```

### Issue 10.6: Polish & Bug Fixes
```
Finale Überprüfung:

UI Polish:
- [ ] Alle Buttons haben Tap Feedback
- [ ] Loading States überall
- [ ] Error States mit Retry
- [ ] Empty States mit hilfreichen Messages
- [ ] Keine Console Warnings

Edge Cases:
- [ ] App Neustart behält Daten
- [ ] Offline Handling
- [ ] Große Datenmengen (100+ Quests)

Akzeptanzkriterien:
- Keine kritischen Bugs
- UX smooth
```

---

## Verifikation

Nach jeder Phase:
1. `flutter analyze` - Keine Errors
2. `flutter test` - Alle Tests grün
3. `flutter run -d chrome` - App startet
4. Manuelle Tests der neuen Features

Finale Verifikation:
1. Family Setup durchspielen
2. Als Parent: Quest erstellen, Reward erstellen
3. Als Kind: Quest annehmen, abschließen
4. Als Parent: Quest bestätigen
5. Als Kind: Points prüfen, Reward kaufen, einlösen
6. Als Parent: Redemption bestätigen
7. Streak über mehrere Tage testen (Datum manuell ändern)
8. Achievement Unlock prüfen

---

## Kritische Dateien

Diese Dateien sind zentral und sollten besonders sorgfältig implementiert werden:

1. `lib/models/quest.dart` - Basis für gesamtes Quest System
2. `lib/providers/auth_provider.dart` - Routing und Rollen
3. `lib/providers/quest_provider.dart` - Quest Workflow
4. `lib/services/storage_service.dart` - Persistenz
5. `lib/main.dart` - App Entry, Provider Setup
