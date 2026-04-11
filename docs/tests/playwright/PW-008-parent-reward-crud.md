# PW-008: Parent — Reward CRUD

- **Prozess:** P6 (Teilprozess: Reward-Katalog)
- **Actor:** Parent
- **Status:** draft

## Zielsetzung

Der Parent verwaltet den Reward-Katalog: Rewards anlegen, bearbeiten, Stock
setzen, löschen. Rewards erscheinen danach im Shop des Kindes.

## Preconditions / Fixtures

- `familyWithChild`, Parent „Mama" eingeloggt, keine Rewards vorhanden

## Testfälle

### TC-008.1 — Neuen Reward anlegen (Happy Path)
```
Given: Parent-Dashboard → Reward-Management
When:  Neuer Reward „30 min Tablet", Preis 50 MP, Kategorie „Privilege"
Then:  Reward erscheint in der Liste
And:   `localStorage['rewards']` enthält einen Eintrag
```

### TC-008.2 — Reward mit limitiertem Stock
```
Given: Reward-Edit
When:  Neuer Reward mit Stock=3
Then:  Stock-Anzeige „3" auf der Reward-Karte
```
**Assertions:**
- Reward-Stock in SharedPreferences == 3

### TC-008.3 — Reward-Kategorien
```
Given: Reward-Edit
When:  Reward der Kategorien „experience", „item", „privilege", „custom"
       werden jeweils angelegt
Then:  Alle 4 Rewards erscheinen; Filter-Chips im Shop-Test (PW-009) zeigen sie.
```

### TC-008.4 — Reward bearbeiten
```
Given: Reward existiert
When:  Preis von 50 auf 75 ändern
Then:  Liste + Shop zeigen 75 MP
```

### TC-008.5 — Reward löschen
```
Given: Reward existiert
When:  Löschen bestätigen
Then:  Reward verschwindet aus der Liste
```

### TC-008.6 — Validierung: Preis ≥ 0
```
Given: Reward-Edit
When:  Preis -5 wird eingegeben
Then:  Validierungsfehler, kein Save
```

## Out of Scope

- Kauf-Flow → PW-009
- Einlösung → PW-010

## Offene Fragen

- Besitzen Rewards ein Verfallsdatum? Spec prüft nur den aktuellen Modell-Stand.
