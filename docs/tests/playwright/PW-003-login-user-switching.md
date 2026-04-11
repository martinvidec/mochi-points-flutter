# PW-003: Login & Benutzerwechsel

- **Prozess:** P3
- **Actor:** beide
- **Status:** draft

## Zielsetzung

Die Login-Seite ist ein Avatar-Grid. Ein Tap auf einen Avatar meldet den User
an, bei Usern mit PIN wird vorher ein Dialog gezeigt. Logout + erneuter Login
mit einem anderen User schalten die Rolle und damit das Dashboard um.

## Preconditions / Fixtures

- `familyWithChild` mit:
  - Parent „Mama" (PIN 1234)
  - Parent „Papa" (ohne PIN)
  - Child „Luca" (ohne PIN)
- Kein User eingeloggt (`last_user_id` leer)

## Testfälle

### TC-003.1 — Login ohne PIN (Child)
```
Given: LoginPage, Child-Avatar „Luca" sichtbar
When:  „Luca" wird angetippt
Then:  Hero-Home wird geöffnet, Hero-Karte sichtbar
And:   `last_user_id` enthält Lucas ID
```

### TC-003.2 — Login mit PIN (Parent)
```
Given: LoginPage, Parent-Avatar „Mama" sichtbar
When:  „Mama" wird angetippt
Then:  PIN-Dialog erscheint
When:  „1234" wird eingegeben und bestätigt
Then:  Parent-Dashboard wird geöffnet
```
**Assertions:**
- `await expect(page.getByRole('dialog', { name: /pin/i })).toBeVisible()`
- Nach korrekter PIN: `await expect(page.getByRole('heading', { name: /hallo,\s*mama/i })).toBeVisible()`

### TC-003.3 — Falscher PIN
```
Given: Login mit Avatar „Mama"
When:  PIN „0000" wird eingegeben
Then:  Fehler-Snackbar „Falscher PIN" erscheint
And:   User bleibt auf LoginPage
```
**Assertions:**
- `await expect(page.getByText(/falscher pin/i)).toBeVisible()`
- Kein Dashboard-Heading sichtbar

### TC-003.4 — Abbrechen im PIN-Dialog
```
Given: PIN-Dialog offen
When:  Dialog wird abgebrochen
Then:  Kein Login; Avatar ist wieder unselektiert
```

### TC-003.5 — Logout → erneuter Login mit anderer Rolle
```
Given: Parent „Mama" ist eingeloggt
When:  Logout im Parent-Profil-Tab
And:   Auf LoginPage Avatar „Luca" antippen
Then:  Hero-Home für Luca wird angezeigt
```
**Assertions:**
- Nach Logout sichtbar: `await expect(page.getByRole('heading', { name: /wer bist du/i })).toBeVisible()`
- Nach Re-Login mit Child: Bottom-Nav ist die Child-Variante (5 Tabs)

## Out of Scope

- Passwort-Reset (existiert nicht)
- PIN-Eingabe-Fehlversuch-Limits (existiert nicht)

## Offene Fragen

- Haben Buttons `aria-label`? Falls nicht, muss der Test `getByText`
  verwenden, was leicht brüchig ist.
