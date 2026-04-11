# PW-012: Hero-Progression (XP, Level-Up)

- **Prozess:** P8
- **Actor:** Child
- **Status:** draft

## Zielsetzung

Das Hero-Home zeigt den aktuellen Hero mit Level, XP-Balken und Stats.
Beim Überschreiten der XP-Schwelle erfolgt ein Level-Up inklusive
Animation / Notification.

## Preconditions / Fixtures

- `childWithApprovedQuest` für die Base-Anzeige
- Ein zusätzlicher Seed-Zustand `childNearLevelUp`:
  - Hero auf Level 1, currentXP knapp unter der Schwelle für Level 2
  - Eine Pending Quest, deren XP das Level sprengt

## Testfälle

### TC-012.1 — Hero-Karte zeigt Level & XP
```
Given: Hero-Home (Child „Luca")
Then:  Hero-Karte zeigt Level 1, Name „Luca", Balken mit Füllstand ≈ 50/100
```
**Assertions:**
- Role-basierter Locator für XP-Balken (ProgressIndicator) ist sichtbar
- Level-Label `/level\s*1/i`

### TC-012.2 — XP steigt nach Quest-Approval
```
Given: Luca hat 0 XP, Parent approved eine Quest mit 50 XP
When:  Luca lädt Hero-Home neu
Then:  XP-Balken zeigt 50/100
```

### TC-012.3 — Level-Up ausgelöst
```
Given: childNearLevelUp
When:  Parent approved die Pending Quest
Then:  Hero-Level steigt auf 2
And:   Level-Up-Animation / Dialog erscheint (sofern getriggert)
And:   Notification type=levelUp existiert
```

### TC-012.4 — Level-Up-Overflow
```
Given: Hero mit currentXP knapp unter Schwelle
When:  Quest mit XP verteilt wird, die die Schwelle um 10 überschreitet
Then:  Hero.level steigt, currentXP == 10 (Rest korrekt übertragen)
```

## Out of Scope

- Avatar/Appearance → PW-013
- Achievements (nicht verdrahtet)

## Offene Fragen

- Wie lang läuft die Level-Up-Animation? Ein Sleep wäre brüchig — besser
  auf das Verschwinden des Dialogs warten (`toHaveCount(0)` nach Timeout).
