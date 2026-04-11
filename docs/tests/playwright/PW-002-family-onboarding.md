# PW-002: Familie einrichten (Onboarding)

- **Prozess:** P2
- **Actor:** Parent (erster Elternteil)
- **Status:** draft

## Zielsetzung

Der erste Start der App ohne Familie muss einen komplett UI-gesteuerten
Onboarding-Flow erlauben: Familie benennen → ersten Elternteil anlegen →
optional weitere Mitglieder → Abschluss, danach befindet sich der User auf
der LoginPage.

## UI-Hinweise (empirisch verifiziert am 2026-04-11)

Die Page ist ein `Stepper` mit 3 Schritten:
1. **„1 Familienname"** — textbox „Familienname", Button „Weiter"
2. **„2 Elternteil erstellen"** — Button „Elternteil erstellen" öffnet eine
   Sub-Page (`AddMemberPage`) mit textbox „Name", textbox „PIN (optional)",
   Button „Speichern". Danach Button „Weiter".
3. **„3 Weitere Mitglieder"** — Button „Mitglied hinzufügen" + Button „Fertig".

Ein Klick auf „Fertig" speichert und navigiert zu `/login`.

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
And:   App routet auf die LoginPage — der Parent wird NICHT automatisch
       eingeloggt (verifiziert 2026-04-11 via playwright-cli)
```
**Assertions:**
- `await expect(page.getByRole('heading', { name: /wer bist du/i })).toBeVisible()`
- Avatar für „Mama" ist sichtbar und klickbar
- Reload der Page landet nicht mehr im Family-Setup
- `localStorage` enthält Keys `flutter.family` und `flutter.family_members`
  (doppelt-JSON-codierter Payload — siehe `e2e/tests/fixtures/seed.ts`)
- `localStorage['flutter.last_user_id']` ist **nicht** gesetzt

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
