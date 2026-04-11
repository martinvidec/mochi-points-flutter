# PW-005: Parent — Quest CRUD

- **Prozess:** P5 (Teilprozess: Quest-Template-Verwaltung)
- **Actor:** Parent
- **Status:** draft

## Zielsetzung

Der Parent kann Quests anlegen, bearbeiten, deaktivieren und löschen. Alle
Daten werden über `QuestProvider` + SharedPreferences persistiert. Die Liste
aktualisiert sich nach jeder Operation.

## Preconditions / Fixtures

- `familyWithChild` (Parent „Mama" eingeloggt, Child „Luca" vorhanden)
- Keine Quests vorhanden

## Testfälle

### TC-005.1 — Neue Daily-Quest anlegen (Happy Path)
```
Given: Parent-Dashboard → Quest-Management geöffnet
When:  „Neue Quest" gewählt
And:   Name „Zimmer aufräumen", Typ Daily, Rarity Common
And:   rewardPoints = 10, rewardXP = 50
And:   assignedTo = [Luca]
And:   Speichern
Then:  Quest erscheint in der Liste
And:   `localStorage['quests']` enthält einen Eintrag mit name „Zimmer aufräumen"
```

### TC-005.2 — Weekly-Epic-Quest mit Deadline
```
Given: QuestManagement
When:  Neue Quest mit Typ Weekly, Rarity Epic, Deadline (in 7 Tagen)
Then:  Quest erscheint mit Deadline-Badge und Epic-Rarity-Styling
```
**Assertions:**
- Rarity-Farbe sichtbar (stilistisch via Role-Badge)
- Deadline-Text enthält einen Datum-Substring

### TC-005.3 — Series-Quest mit targetCount
```
Given: QuestManagement
When:  Neue Quest Typ Series, targetCount 5, unit „Tage"
Then:  Quest ist gespeichert und zeigt „0 / 5" als Default-Progress auf Detailseite
```

### TC-005.4 — Quest bearbeiten
```
Given: Mindestens eine Quest existiert
When:  Quest wird geöffnet und rewardPoints von 10 auf 20 geändert
Then:  Liste zeigt 20 MP
And:   `quests[0].rewardPoints == 20` in SharedPreferences
```

### TC-005.5 — Quest deaktivieren
```
Given: Aktive Quest „Zimmer aufräumen"
When:  isActive=false setzen
Then:  Quest erscheint in Parent-Liste als inaktiv
And:   Child sieht die Quest nicht mehr im Quest-Board (Cross-Check aus PW-006)
```

### TC-005.6 — Quest löschen
```
Given: Quest existiert
When:  Löschen + Bestätigung
Then:  Quest verschwindet aus der Liste
And:   `localStorage['quests']` enthält keinen Eintrag mehr
```

### TC-005.7 — Validierung: leerer Name / negative Punkte
```
Given: Neue-Quest-Formular
When:  Name leer oder rewardPoints < 0
Then:  Speichern zeigt Validierungsfehler, keine Quest wird angelegt
```

## Out of Scope

- Child-seitiges Akzeptieren → PW-006
- Approval nach Completion → PW-007

## Offene Fragen

- Ist Bulk-Delete vorgesehen? Aktuell nicht; Spec prüft nur Einzel-Delete.
