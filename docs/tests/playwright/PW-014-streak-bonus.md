# PW-014: Streak-Anzeige & Bonus

- **Prozess:** P9
- **Actor:** Child
- **Status:** draft

## Zielsetzung

Der Streak wird beim Quest-Approval automatisch aktualisiert
(`HeroProvider.recordActivity`). Abhängig von der Streak-Länge entsteht ein
Streak-Bonus auf Punkte (siehe IST-Analyse §P9). Die Anzeige auf dem Hero-Home
spiegelt den aktuellen Streak wider.

> **Zeit-Simulation:** Streaks hängen vom Kalender ab. Tests müssen
> `Date.now` in JavaScript überschreiben (z. B. via
> `await page.addInitScript({ content: '...' })` oder
> `await page.clock.install({ time: ... })`), **bevor** Flutter bootet.

## Preconditions / Fixtures

- `familyWithQuestAndReward`
- Hero für „Luca" mit `activityDates = []`, `currentStreak = 0`

## Testfälle

### TC-014.1 — Erste Aktivität setzt Streak=1
```
Given: Clock auf 2026-04-11
And:   currentStreak = 0
When:  Parent approved eine Quest für Luca
Then:  Hero.currentStreak == 1
And:   Hero-Home zeigt „Streak: 1"
```

### TC-014.2 — Streak wächst an Folgetagen
```
Given: Clock auf 2026-04-11, Streak=0
When:  Approval am 2026-04-11
And:   Clock auf 2026-04-12, Approval einer weiteren Quest
Then:  currentStreak == 2
And:   longestStreak == 2
```

### TC-014.3 — Streak-Bonus wirkt auf Points
```
Given: Seed: currentStreak = 7 (ausreichend für Bonus-Stufe laut StreakService)
When:  Parent approved eine Quest mit 10 MP / 50 XP
Then:  Points-Balance steigt um mehr als 10 MP
And:   XP-Balance steigt genau um 50
And:   Eine Bonus-Transaktion `type=bonus` mit positivem Amount existiert
```
**Assertions:**
- Transaction-Liste enthält zwei Einträge für dieselbe `referenceId` (questComplete + bonus)

### TC-014.4 — Streak-Milestone-Notification
```
Given: Streak-Milestone wird erreicht (z. B. 7, 14, 30 Tage)
Then:  Notification type=streakMilestone existiert für Luca
```

### TC-014.5 — Streak-Verlust
```
Given: currentStreak = 5, letzter activityDate 2026-04-09
And:   Clock auf 2026-04-12 (2 Tage Pause → Streak verloren)
When:  App wird geöffnet (Hero-Home lädt und `checkStreak` läuft)
Then:  currentStreak == 0
And:   Notification type=streakLost existiert
```
> **Hinweis:** Laut IST-Analyse §5.3 wird `checkStreak` **aktuell nicht**
> beim App-Start gerufen. TC-014.5 muss deshalb initial mit
> `test.skip('awaiting bootstrap wiring')` markiert werden.

## Out of Scope

- XP-Bonus (gibt es nicht)
- Achievements (nicht verdrahtet)

## Offene Fragen

- Welche Streak-Schwellen greifen für den Bonus? Siehe `StreakService` —
  muss beim Schreiben des Tests konkret verankert werden.
