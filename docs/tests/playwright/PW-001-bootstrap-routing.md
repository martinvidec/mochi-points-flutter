# PW-001: App Bootstrap & Routing

- **Prozess:** P1 (siehe `docs/IST_ANALYSE.md` §3 / P1)
- **Actor:** System / beide Rollen
- **Status:** draft

## Zielsetzung

Beim App-Start entscheidet `SplashPage`, wohin navigiert wird:

1. **keine Familie** → `/family-setup`
2. **Familie + eingeloggter User** → `/parent-dashboard` oder `/hero-home`
   (abhängig von `UserRole`)
3. **Familie, kein User** → `/login`

Diese Spec prüft alle drei Routing-Pfade inklusive Splash-Rendering.

## Preconditions / Fixtures

- `freshApp` für TC-001.1
- `familyWithParent` (Parent eingeloggt) für TC-001.2a
- `familyWithChild` (Child eingeloggt) für TC-001.2b
- `familyWithChild` mit geleerter `last_user_id` für TC-001.3

## Testfälle

### TC-001.1 — Cold Start ohne Familie → Family-Setup
```
Given: SharedPreferences leer (freshApp)
When:  App wird geladen (page.goto('/'))
Then:  Splash-Screen wird kurz angezeigt
And:   Nach Auth-Init wird zur Family-Setup-Seite navigiert
```
**Assertions:**
- Initial: `await expect(page.getByRole('progressbar')).toBeVisible()`
- Ziel: `await expect(page.getByRole('heading', { name: /familie.*einrichten/i })).toBeVisible()`
- URL-Hash bzw. Route enthält `family-setup`

### TC-001.2a — Cold Start mit eingeloggtem Parent → Parent-Dashboard
```
Given: familyWithParent, lastUserId = parent.id
When:  App wird geladen
Then:  Parent-Dashboard wird angezeigt (Begrüßung mit Parent-Name)
```
**Assertions:**
- `await expect(page.getByRole('heading', { name: /hallo,\s*mama/i })).toBeVisible()`
- Bottom-Nav enthält Tabs: Home, Quests, Rewards, Genehmigungen, Profil

### TC-001.2b — Cold Start mit eingeloggtem Child → Hero-Home
```
Given: familyWithChild, lastUserId = child.id
When:  App wird geladen
Then:  Hero-Home wird angezeigt (mit Hero-Karte & XP-Bar)
```
**Assertions:**
- `await expect(page.getByTestId('hero-card')).toBeVisible()` *(falls TestID existiert)*
- Alternativ: `await expect(page.getByRole('progressbar', { name: /xp/i })).toBeVisible()`
- Bottom-Nav enthält Child-Tabs

### TC-001.3 — Cold Start mit Familie aber ohne User → Login
```
Given: familyWithChild, aber lastUserId gelöscht
When:  App wird geladen
Then:  Login-Seite (Avatar-Grid) erscheint
```
**Assertions:**
- `await expect(page.getByRole('heading', { name: /wer bist du/i })).toBeVisible()`
- Mindestens ein Avatar-Button ist sichtbar und klickbar

## Out of Scope

- Der eigentliche Login/Logout-Flow → PW-003
- Family-Setup-Formular → PW-002
- Pop-State-Handling / Browser-Back-Button

## Offene Fragen

- Splash-Screen hat aktuell keinen garantiert sichtbaren Text/Heading; ggf.
  muss vor Implementierung ein `Semantics(label: 'Loading')` ergänzt werden.
