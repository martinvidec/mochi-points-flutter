# PW-006: Child — Quest akzeptieren & erledigen

- **Prozess:** P5 (Teilprozess: Child-Pfad)
- **Actor:** Child
- **Status:** draft

## Zielsetzung

Ein Kind sieht verfügbare Quests, kann eine annehmen, den Status „in Arbeit"
prüfen und sie als erledigt markieren. Nach „Erledigt" wechselt der Status
auf `pendingApproval`. Die Quest verschwindet aus dem Board (keine Doppel-Annahme).

## Preconditions / Fixtures

- `familyWithQuestAndReward`, Child „Luca" eingeloggt
- Quest „Zimmer aufräumen" (daily, common, 10 MP, 50 XP, assignedTo = [Luca])

## Testfälle

### TC-006.1 — Quest-Board zeigt verfügbare Quest
```
Given: Hero-Home → Quests-Tab
Then:  „Zimmer aufräumen" ist in der Liste sichtbar
And:   Keine aktive Instance für diese Quest
```

### TC-006.2 — Quest annehmen
```
Given: Quest-Detail geöffnet
When:  „Annehmen" wird geklickt
Then:  QuestInstance (inProgress) wird angelegt
And:   Quest verschwindet aus der „Verfügbar"-Liste
And:   Taucht in „Aktiv"-Liste auf
```
**Assertions:**
- `localStorage['quest_instances']` enthält genau 1 Eintrag mit status=inProgress
- Hero-Home zeigt „Aktive Quests: 1" (falls das Widget existiert)

### TC-006.3 — Quest als erledigt markieren
```
Given: Quest ist „inProgress"
When:  „Erledigt" wird geklickt
Then:  Status wechselt auf „pendingApproval"
And:   Completion-Animation läuft (nicht inhaltlich geprüft, nur kein Fehler)
```
**Assertions:**
- QuestInstance in SharedPreferences: `status == "pendingApproval"`
- Auf dem Hero-Home steht „wartet auf Bestätigung" (o. ä.)

### TC-006.4 — Parent-Benachrichtigung entsteht
```
Given: TC-006.3 abgeschlossen
When:  Als Parent „Mama" einloggen (über PW-003-Fixture)
Then:  Eine Notification „Quest wartet auf Genehmigung" existiert für Mama
```
**Assertions:**
- Badge-Zähler an der Notification-Glocke zeigt ≥ 1
- `localStorage['notifications']` enthält einen Eintrag mit type=questCompleted

### TC-006.5 — Keine Doppel-Annahme möglich
```
Given: Quest läuft bereits (inProgress)
When:  Zurück zum Quest-Board
Then:  Quest ist nicht mehr in „Verfügbar" gelistet
```

### TC-006.6 — Filter-Tabs im Quest-Board
```
Given: Quest-Board zeigt mehrere Quests unterschiedlichen Typs
When:  Tabs „Daily" / „Weekly" / „Epic" / „Series" werden durchgeschaltet
Then:  Nur Quests des gewählten Typs werden angezeigt
```

## Out of Scope

- Approval/Rejection → PW-007
- Series-Progress-Increment (`incrementSeriesProgress`) — laut IST-Analyse
  §5.5 UI-seitig lückenhaft; wird erst getestet, wenn End-to-End verdrahtet.

## Offene Fragen

- Zeigt das Hero-Home eine eigene „Aktiv"-Sektion? Falls nein, wird
  TC-006.2 die Verifikation rein per Quest-Board durchführen.
