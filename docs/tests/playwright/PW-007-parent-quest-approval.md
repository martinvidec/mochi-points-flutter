# PW-007: Parent — Quest Approval & Rejection

- **Prozess:** P5 (Teilprozess: Abschluss + Belohnung)
- **Actor:** Parent
- **Status:** draft

## Zielsetzung

Wenn das Kind eine Quest als erledigt markiert, erscheint sie beim Parent unter
„Genehmigungen". Der Parent kann approven (→ Punkte, XP, ggf. Streak-Bonus,
ggf. Level-Up, Notification für Child) oder rejecten (→ zurück auf inProgress,
Notification für Child).

## Preconditions / Fixtures

- `familyWithQuestAndReward`
- Child hat die Quest „Zimmer aufräumen" bereits erledigt (Status
  `pendingApproval`, siehe PW-006)
- Parent „Mama" ist eingeloggt

## Testfälle

### TC-007.1 — Approval-Liste zeigt Pending
```
Given: Parent-Dashboard → Genehmigungen-Tab
Then:  „Zimmer aufräumen" erscheint in der Liste
And:   Badge-Zähler in Bottom-Nav zeigt mindestens 1
```

### TC-007.2 — Quest genehmigen, Punkte & XP vergeben
```
Given: Pending Quest wird geöffnet
When:  „Genehmigen" wird geklickt
Then:  Success-Snackbar „Quest bestätigt! 10 Punkte + 50 XP vergeben"
And:   Quest verschwindet aus der Pending-Liste
And:   Child-Balance steigt um 10 MP (+ ggf. Streak-Bonus)
And:   Hero-XP steigt um 50
```
**Assertions:**
- `localStorage['points_accounts']` enthält einen Eintrag mit balance ≥ 10 für Luca
- Snackbar mit Text `/bestätigt/i` sichtbar
- Transaktionen in `localStorage['transactions']`: mindestens ein Eintrag
  `type=questComplete` mit amount=10

### TC-007.3 — Notification für das Kind
```
Given: TC-007.2 abgeschlossen
When:  Als Child „Luca" einloggen
Then:  Notification „Quest genehmigt!" existiert
And:   Badge an der Notification-Glocke zeigt ≥ 1
```

### TC-007.4 — Streak-Bonus wird auf Points angewendet (nicht auf XP)
```
Given: childWithApprovedQuest (→ Child hat bereits eine 7-Tage-Streak durch Test-Seed)
And:   Eine weitere Pending Quest mit 10 MP / 50 XP
When:  Parent approved die Quest
Then:  Balance steigt um mehr als 10 MP (wegen Bonus)
And:   Hero-XP steigt genau um 50
And:   Zwei Transaktionen entstehen: questComplete (10) + bonus (>0)
```
**Assertions:**
- Transactions: `type=bonus` mit amount > 0 referenzierend dieselbe questId
- XP-Delta == 50 (XP bekommt **keinen** Streak-Bonus)

### TC-007.5 — Quest ablehnen (mit Grund)
```
Given: Pending Quest
When:  „Ablehnen" wird geklickt und ein Grund eingegeben (sofern UI erlaubt)
Then:  Quest-Instance wechselt zurück auf inProgress, progress=0
And:   Notification „Quest abgelehnt" mit Grund für Child
And:   Es werden KEINE Punkte vergeben
```

### TC-007.6 — Level-Up wird getriggert
```
Given: Child auf XP-Stand dicht unter Level-Up-Schwelle (Seed anpassen)
When:  Parent approved eine Quest, deren XP das Level sprengen würde
Then:  Hero-Level erhöht sich
And:   Notification „Level Up!" existiert für Child
```
**Assertions:**
- Hero.level in `localStorage['heroes']` nach Approval = altes Level + 1
- Notification mit type=levelUp vorhanden

## Out of Scope

- Level-Up-**Animation** visuell prüfen → PW-012
- Achievements (laut IST-Analyse §5.1 nicht verdrahtet)

## Offene Fragen

- Wird der Ablehnungs-Grund im UI abgefragt? Falls nicht, TC-007.5 entfällt
  der `Grund:`-Assertion-Teil.
