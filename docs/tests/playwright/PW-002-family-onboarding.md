# PW-002: Familie einrichten (Onboarding)

- **Prozess:** P2
- **Actor:** Parent (erster Elternteil)
- **Status:** draft

## Zielsetzung

Der erste Start der App ohne Familie muss einen komplett UI-gesteuerten
Onboarding-Flow erlauben: Familie benennen → ersten Elternteil anlegen →
optional weitere Mitglieder → Abschluss, danach befindet sich der User im
passenden Dashboard.

## Preconditions / Fixtures

- `freshApp` (leeres SharedPreferences, noch keine Familie)

## Testfälle

### TC-002.1 — Happy Path: Familie + Parent + Child
```
Given: freshApp
When:  Benutzer navigiert zur FamilySetup-Seite
And:   Familienname „Test-Familie" wird eingegeben
And:   Erster Parent „Mama" wird hinzugefügt (PIN 1234)
And:   Ein Child „Luca" wird hinzugefügt (ohne PIN)
And:   „Fertig" wird geklickt
Then:  Familie wird persistiert
And:   Parent „Mama" ist automatisch eingeloggt → Parent-Dashboard
```
**Assertions:**
- `await expect(page.getByRole('heading', { name: /hallo,\s*mama/i })).toBeVisible()`
- Reload der Page landet nicht mehr im Family-Setup
- `localStorage` enthält Keys `family` und `family_members`

### TC-002.2 — Pflichtfelder-Validierung
```
Given: freshApp, FamilySetup-Seite
When:  „Fertig" wird geklickt ohne Namen und Mitglieder
Then:  Eine Fehlermeldung / Validierungshinweis erscheint
And:   Keine Navigation zum Dashboard
```
**Assertions:**
- Fehlermeldung zur Pflichtangabe sichtbar
- URL-Route bleibt auf `family-setup`

### TC-002.3 — Erster Parent ist Pflicht
```
Given: freshApp
When:  Familienname eingegeben, aber kein „Erster Parent"
Then:  „Fertig" bleibt disabled oder triggert Validierungsfehler
```
**Assertions:**
- Button „Fertig" ist disabled **ODER** klickt zu einer sichtbaren Fehlermeldung
- (Die Spec akzeptiert beide UX-Varianten; der Test entscheidet sich beim
  Schreiben für die tatsächlich implementierte)

### TC-002.4 — Mitglied kann entfernt werden (vor Speichern)
```
Given: Familienname + Parent gesetzt, zusätzlich Child „Luca" hinzugefügt
When:  „Luca" wird aus der Mitgliederliste entfernt
Then:  „Luca" ist nicht mehr im Onboarding-Zustand sichtbar
```
**Assertions:**
- Mitgliederliste enthält „Luca" vor dem Remove
- Nach Remove: `await expect(page.getByText('Luca')).toHaveCount(0)`

## Out of Scope

- PIN-Login → PW-003
- Edit/Remove nach abgeschlossenem Onboarding → PW-004
- Bild-Upload / Avatar-Auswahl (sofern vorhanden)

## Offene Fragen

- Gibt es eine maximale Anzahl von Familienmitgliedern? Aktuell nicht begrenzt.
