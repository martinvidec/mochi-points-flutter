# Playwright + Flutter Web: Findings

Stand: 2026-04-12
Quellen: PR #181 (Bootstrap), #182 (PW-001), #183 (PW-002), #185 (PW-003), #TBD (PW-004), #TBD (PW-005), #TBD (PW-006)

Dieses Dokument ist ein **lebender Katalog** aller nicht-offensichtlichen
Erkenntnisse, die bei der Arbeit an der E2E-Test-Suite unter `e2e/` aufgefallen
sind. Wenn du eine neue PW-NNN-Spec implementierst, lies dieses Dokument
**bevor** du Zeit mit Trial-and-Error verbrennst — mit großer Wahrscheinlichkeit
hat jemand das Problem schon einmal gelöst. Wenn du ein neues Finding machst,
hänge es unten an mit Datum + PR-Referenz.

> ### ⚠️ Maintenance-Pflicht
>
> Diese Datei muss bei **jedem** Playwright-PR gepflegt werden, in dem ein
> nicht-offensichtliches Detail auftaucht — egal ob es ein neuer App-Bug,
> ein Semantics-Quirk, ein Label-Pattern, eine Dep-Überraschung oder ein
> Workflow-Kniff ist. Aufnahme in `FINDINGS.md` ist Teil der Definition of
> Done für jede `feature/<N>-pw-NNN-*`-Branch, **nicht** optional.
>
> **Warum so hart?** PW-003 ist beim ersten Versuch grün geworden, weil die
> Findings aus #181/#182/#183 vollständig katalogisiert waren (W-1
> Explore-before-Write, F-11 „Approve" statt „Genehmigungen", F-13
> „Wer bist du?" ist kein heading, F-7 Double-JSON-Seed-Format …). Das
> spart real Zeit. Ohne Pflege verfällt der Katalog und alle müssen
> wieder Trial-and-Error machen.
>
> **Wie?** Ein neues Finding → neue Sub-Sektion mit ID (`F-17`, `B-5`,
> `W-6` usw., fortlaufend), Datum, PR-Referenz. Bei Änderungen an einem
> bestehenden Finding: die ursprüngliche ID behalten, Quelle um den PR
> ergänzen. Die **Quellen-Zeile oben** im Header immer mit dem neuen PR
> erweitern.
>
> Die CLAUDE.md-Session-Instructions verweisen ebenfalls auf diesen
> Workflow (§ „E2E Tests (Playwright)") — beides muss konsistent
> bleiben.

Gliederung:

1. [Flutter-Web-Test-Quirks](#flutter-web-test-quirks) — wie man Playwright an
   Flutters Canvas-Rendering überhaupt sinnvoll andockt
2. [Fixture-/Seed-Konventionen](#fixture--seed-konventionen) — wie die App
   via SharedPreferences für deterministische Startzustände gefüttert wird
3. [UI-Labels und Accessible Names](#ui-labels-und-accessible-names) —
   was die App in der Semantics-Tree tatsächlich ausspuckt
4. [App-Bugs gefunden während Testing](#app-bugs-gefunden-während-testing) —
   reale Mängel in der App, die eine Test-Spec zur Folge hatten
5. [Spec-Korrekturen](#spec-korrekturen) — Specs, die während der Implementierung
   korrigiert werden mussten
6. [Dependency-Stolpersteine](#dependency-stolpersteine) — warum die node_modules
   so aussehen wie sie aussehen
7. [Entwicklungs-Workflow](#entwicklungs-workflow) — wie man effizient neue
   PW-NNN-Specs schreibt

---

## Flutter-Web-Test-Quirks

### F-1 · Semantics-Tree muss erst aktiviert werden

Flutter Web rendert in ein `<canvas>`. DOM-basierte Locators (`getByRole`,
`getByText`, `getByLabel`) finden nur dann Treffer, wenn die **Semantics-Tree**
aktiv ist. Die ist per Default deaktiviert und wird erst durch einen Klick auf
das versteckte `<flt-semantics-placeholder>`-Element aktiviert.

**Fix** — `e2e/tests/fixtures/flutter.ts::openFlutterApp()`:

```typescript
await page.goto(path);
await page.waitForSelector('flt-semantics-placeholder', { state: 'attached' });
await page.locator('flt-semantics-placeholder').dispatchEvent('click');
await page.waitForSelector('flt-semantics', { state: 'attached' });
```

Wichtig: `click({force: true})` funktioniert **nicht**, weil der Placeholder bei
`(-1, -1)` außerhalb des Viewports liegt und Playwright auch mit `force` den
Click ablehnt. Der synthetische `dispatchEvent('click')` umgeht die
Actionability-Checks.

Alle Test-Fixtures (`flutterPage`, `seededPage`) rufen `openFlutterApp`
automatisch auf — in Specs direkt die Fixtures benutzen, nicht `page.goto`.

Quelle: Bootstrap PR #181.

### F-2 · `Locator.fill()` funktioniert nicht

Flutter rendert Textfelder als `<flt-semantics role="textbox">` + ein
**verstecktes** `<input>`-Element. Playwrights `fill()` setzt den DOM-Value
direkt, Flutters Canvas-Texteditor bekommt davon nichts mit, und das Feld
bleibt effektiv leer.

**Fix** — `flutterFill(field, value)` in `fixtures/flutter.ts`:

```typescript
await field.click();                                                 // 1
await field.evaluate(() => new Promise(r => setTimeout(r, 150)));    // 2
await field.pressSequentially(value, { delay: 30 });                 // 3
```

1. **Click** mountet das versteckte `<input>` und gibt ihm Fokus.
2. **150 ms Settle** — ohne das wird das erste Zeichen verschluckt, weil
   Flutter ein paar Frames braucht, bis der hidden input Keystrokes annimmt.
   Empirisch reproduzierbar, vor allem auf Sub-Pages (AddMemberPage etc.),
   die beim Mount noch laufende Fade-/Slide-Animationen haben.
3. **`pressSequentially` mit `delay: 30`** — echte Keystrokes, pro Key 30 ms
   Pause, damit Flutters Input-Handler jeden verarbeiten kann.

Quelle: PW-002 PR #183. Vorher: diverse Fehlschläge in TC-002.1 mit leerem
Name-Feld, fehlende "1" am Anfang der PIN etc.

### F-3 · Validation-Texte matchen doppelt (Strict-Mode-Violation)

Snackbars und Form-Validation-Fehler werden **doppelt** ins DOM gerendert:

1. Als sichtbares `<span>` im `<flt-semantics>`-Tree
2. Als `<flt-announcement-polite>` oder `<flt-announcement-assertive>`
   Live-Region-Sibling für Screenreader

`page.getByText(/.../ )` matched beide und Playwrights strict-mode wirft
„resolved to 2 elements". Die Tests sehen aus wie flaky, sind aber deterministisch
kaputt.

**Fix** — `flutterText(page, text)` in `fixtures/flutter.ts`:

```typescript
return page.locator('flt-semantics').getByText(text);
```

Scope auf `flt-semantics` schließt die Live-Regions aus, weil die als Siblings
zum Semantics-Tree rendern.

Benutze diesen Helper für **alle** Snackbar- und Validation-Assertions. Für
normalen statischen Text (z. B. „Wer bist du?" auf der LoginPage) ist
`page.getByText()` ausreichend.

Quelle: PW-002 PR #183.

### F-4 · `<flt-semantics role="button">` hat kein `aria-label`

Buttons in der Flutter-Semantics-Tree tragen **kein** `aria-label`-Attribut.
Der accessible name kommt stattdessen aus `textContent`. Ein IconButton ohne
`Semantics(label: ...)`-Wrapper erscheint als Button mit **leerem**
`textContent`.

Playwrights `getByRole('button', { name: '' })` funktioniert nicht zuverlässig
für diese Unlabeled-Buttons — der name-Filter interpretiert leere Strings als
„egal welcher name".

**Fix** — `clickUnlabeledButton(scope)` in `fixtures/flutter.ts`:

```typescript
const buttons = scope.getByRole('button');
const count = await buttons.count();
for (let i = 0; i < count; i++) {
  const btn = buttons.nth(i);
  const text = (await btn.textContent()) ?? '';
  if (text.trim() === '') {
    await btn.click();
    return;
  }
}
```

Immer zuerst einen Scope eingrenzen (`page.getByRole('group', { name: ... })`),
sonst kommt der falsche Unlabeled-Button.

**Wichtig**: der richtige Fix für so einen Fall liegt in Dart — den Button in
`Semantics(label: 'Mitglied entfernen: ...')` einpacken. Der Helper ist ein
Workaround, kein Endzustand. Jedes neue Auftreten dieses Patterns sollte ein
App-seitiges TODO in der Spec und idealerweise ein Issue erzeugen.

Quelle: PW-002 PR #183. App-TODO: AddMemberPage Remove-IconButton in
`lib/pages/setup/family_setup_page.dart:222`.

### F-5 · Live-Dev-Server ist NICHT test-ready

`flutter run -d web-server` antwortet mit 200 auf `/`, **bevor** das JS-Bundle
fertig kompiliert ist. Playwrights `webServer.url`-Probe unlockt die Tests, die
Worker feuern `goto()`, sehen halbfertige Seiten und timeouten beim
`waitForSelector('flt-semantics-placeholder')`.

**Fix** — `e2e/playwright.config.ts::webServer`:

```typescript
webServer: process.env.CI ? undefined : {
  command:
    'flutter build web --no-tree-shake-icons && npx --yes serve -s ../build/web -l 8080',
  url: BASE_URL,
  reuseExistingServer: true,
  timeout: 300_000,
};
```

- `flutter build web` produziert den kompletten Bundle auf Disk.
- `serve -s ../build/web` antwortet erst auf Requests, wenn Build-Artefakte
  da sind.
- `--no-tree-shake-icons` ist Pflicht (siehe `CLAUDE.md`).

Wenn du **Hot-Reload beim Test-Schreiben** willst: `flutter run -d web-server
--web-port 8081` manuell in einem zweiten Terminal starten und
`E2E_BASE_URL=http://127.0.0.1:8081 npm test` aufrufen.

Quelle: Bootstrap PR #181. Ursprünglich 2/6 Tests grün mit `flutter run`-Pfad,
6/6 grün nach Umstellung auf `flutter build + serve`.

### F-6 · Routing per Hash-Fragment

Die App nutzt Flutters Named-Routes mit Hash-Fragmenten. Navigation-Assertions
müssen auf den Fragment-Teil der URL matchen:

| Screen | URL-Fragment |
|---|---|
| Splash | `/` (kurz) |
| Family Setup | `#/family-setup` |
| Login | `#/login` |
| Parent Dashboard | `#/parent-dashboard` |
| Hero Home | `#/hero-home` |

Assertion-Pattern: `await expect(page).toHaveURL(/#\/login/)` oder
`expect(page.url()).toContain('#/login')`.

Quelle: PW-001 PR #182.

---

## Fixture-/Seed-Konventionen

### F-7 · Seed-Wire-Format ist doppelt-JSON-encoded

`shared_preferences_web@2.4.3` speichert Werte unter `localStorage['flutter.<key>']`
als **doppelt** JSON-codierten String. Unser `StorageService` schreibt Daten
bereits als `prefs.setString(key, jsonEncode(list))`, das Plugin wrappt das
dann nochmal mit `JSON.stringify` beim Schreiben in localStorage.

**Richtig seeden** — `e2e/tests/fixtures/seed.ts::applySeed`:

```typescript
// Objects/Arrays: doppeltes JSON
const innerJson = JSON.stringify(value);
localStorage.setItem('flutter.' + key, JSON.stringify(innerJson));

// Primitive Strings (z. B. last_user_id): einfaches JSON
localStorage.setItem('flutter.' + key, JSON.stringify(str));
```

**Falsch** (frühe Bootstrap-Version):

```typescript
// ⚠ `string:<json>` — ist KEIN echtes shared_preferences-Format
localStorage.setItem('flutter.' + key, 'string:' + json);
```

Verifiziert empirisch: erst die App via UI benutzt, dann `localStorage`-Dump
per `playwright-cli eval` abgegriffen, dann Format in `seed.ts` angepasst.

Quelle: Bootstrap PR #181 (erste Runde: falsch; Review-Runde: korrigiert).

### F-8 · Dart-Models haben Pflichtfelder, die nicht offensichtlich sind

Mehrere `Model.fromJson`-Factories lesen Felder strikt ohne Null-Default. Wenn
der Seed diese Felder auslässt, explodiert die App beim ersten `loadData()`
aufruf, nicht beim Seed-Schreiben. Debug ist unangenehm.

Empirisch gefundene Pflichtfelder, die leicht zu vergessen sind:

| Model | Pflichtfeld | Typ | Default im Seed |
|---|---|---|---|
| `Family` | `inviteCode` | `String?` | `null` |
| `User` | `avatarUrl` | `String?` | `null` |
| `QuestInstance` | `currentStreak` | `int` | `0` |
| `Hero` | `unlockedItems`, `equippedItems`, `badges` | `List<String>` | `[]` |
| `HeroAppearance` | `baseAvatar`, `skinColor`, `hairStyle`, `hairColor`, `outfit` | `String` | "default"/"light"/"short"/"brown"/"casual" |

**Nicht** im Model (obwohl man es aus Specs vielleicht vermuten würde):

- `Reward.expiresAt` — existiert nicht

Beim Schreiben eines neuen Seed-Builders immer erst den entsprechenden
`lib/models/<name>.dart` prüfen. Siehe auch `docs/IST_ANALYSE.md` für die
Model-Landkarte.

Quelle: Bootstrap PR #181.

### F-9 · `PointsProvider.loadData()` wird nicht gerufen

Laut `docs/IST_ANALYSE.md` §5.2 ruft weder der Splash noch das Parent-Dashboard
`PointsProvider.loadData()` auf. Das heißt: Punktestände aus dem Seed werden
beim Cold-Start **nicht** in den Provider geladen, bis irgendein `earn`/`spend`
das Konto lazy initialisiert.

**Auswirkung für Tests**: Assertions über Punkte-Anzeigen auf dem
Parent-Dashboard direkt nach Seed + Boot sind wertlos — die UI zeigt 0 MP
auch wenn der Seed 10 MP hat.

**Workaround in Tests**: Entweder direkt `localStorage.getItem('flutter.points_accounts')`
per `page.evaluate` prüfen (siehe `seed-verify.spec.ts::childWithApprovedQuest`),
oder einen UI-Pfad triggern, der `loadData` lazily aufruft.

**Echter Fix**: App-seitig in `SplashPage._initialize` o. ä. explizit alle
Provider `loadData()` aufrufen. Ist ein Backlog-Item aus der IST-Analyse.

Quelle: IST-Analyse, bestätigt in PR #181.

### F-10 · Seed-Fixtures-Katalog

Aktueller Stand der Fixture-Builder in `e2e/tests/fixtures/seed.ts`:

| Builder | Zustand |
|---|---|
| `seedFreshApp()` | leer, Cold-Start ohne Familie |
| `seedFamilyWithParent()` | Familie + Parent „Mama" (PIN 1234), eingeloggt |
| `seedFamilyWithChild()` | + Child „Luca", Hero Level 1, Mama eingeloggt |
| `seedFamilyWithQuestAndReward()` | + 1 Daily-Quest (10 MP / 50 XP), 3 Rewards |
| `seedChildWithApprovedQuest()` | + Luca hat 10 MP, 50 XP, Streak 1 |

Alle Builder können per Spread + Override individualisiert werden:

```typescript
const page = await seededPage({
  ...seedFamilyWithChild(),
  lastUserId: IDS.childLucaId,  // Luca statt Mama eingeloggt
});
```

Die stabilen IDs (`IDS.parentMamaId`, `IDS.childLucaId`, …) sind aus
`seed.ts` exportiert und sollten in Assertions verwendet werden, wenn
eine Test-Spec einen User gezielt adressieren muss.

Quelle: Bootstrap PR #181, erweitert in PW-001 PR #182.

---

## UI-Labels und Accessible Names

### F-11 · Parent-Dashboard-Bottom-Nav: „Approve", nicht „Genehmigungen"

Die Bottom-Navigation im Parent-Dashboard hat 5 Tabs:

- „Home"
- „Quests"
- „Rewards"
- **„Approve"** ← englisch, alle anderen deutsch
- „Profil"

Tests, die auf den Genehmigungen-Tab targeten, müssen `{name: /^approve$/i}`
benutzen. Wir dokumentieren das hier, weil es ein Translation-Miss ist und
irgendwann ein Dart-Fix kommt, der den Tab auf „Genehmigungen" umbenennt.

Weitere englische Labels, die aufgefallen sind:

- AppBar-Back-Button heißt „Back" statt „Zurück"

Quelle: empirische Exploration in PR #181 / PR #182.

### F-12 · Hero-Card-Button hat kombinierten Accessible Name

Die Hero-Karte auf `#/hero-home` rendert als Button mit einem kombinierten
accessible name:

```
"L Luca Level 1 Mochi Novice XP 0 / 100"
```

Pattern: `<Initial> <Name> Level <N> <Title> XP <current> / <nextLevelThreshold>`.

Assertion-Empfehlung: Regex auf die stabilen Teile (`name + level + title`),
nicht auf `XP …/…` — der XP-Teil ändert sich nach jedem Approval.

```typescript
await expect(
  page.getByRole('button', { name: /luca.*level\s*1.*mochi novice/i }),
).toBeVisible();
```

Quelle: PW-001 PR #182.

### F-13 · Login-Page: „Wer bist du?" ist KEIN heading

Auf `#/login` ist die Begrüßungsüberschrift „Wer bist du?" kein
`role="heading"`, sondern ein generischer Text-Knoten. Assertions müssen
`getByText` benutzen:

```typescript
await expect(page.getByText(/wer bist du\?/i)).toBeVisible();
```

Ebenso: die Familienname-Anzeige darüber („Test-Familie") ist auch nur
generischer Text, kein heading.

Die Avatar-Buttons dagegen haben einen klar definierten accessible name
im Pattern `"<Initial> <Name> <Rolle>"`:

- `"M Mama Eltern"`
- `"L Luca Kind"`

Quelle: PW-001 PR #182 (TC-001.3) + PW-002 PR #183 (TC-002.1 Assertion
nach Finish).

### F-14 · Stepper-Step-Titel haben Index-Prefix

Flutters `Stepper`-Widget rendert Step-Titel im Semantics-Tree mit einem
numerischen Index-Prefix:

- `"1 Familienname"` — Step 1 im collapsed state
- `"2 Elternteil erstellen"` — Step 2
- `"3 Weitere Mitglieder"` — Step 3

Wichtig: Im Step-2-Content gibt es ZUSÄTZLICH einen Button mit exakt
`"Elternteil erstellen"` (ohne Prefix) — das ist der Action-Button für
`_addFirstParent`. Um Kollision zu vermeiden, immer mit `exact: true`
arbeiten:

```typescript
await page
  .getByRole('button', { name: 'Elternteil erstellen', exact: true })
  .click();
```

Quelle: PW-002 PR #183.

### F-15 · Parent-Dashboard-Heading: „Hallo, <Name>!"

Das Parent-Dashboard begrüßt mit einem Level-2-Heading:

```
"Hallo, Mama!"
```

Stabiles Assertion-Pattern:

```typescript
await expect(
  page.getByRole('heading', { name: /hallo,\s*mama/i }),
).toBeVisible();
```

Der Comma+Space-Bereich zwischen „Hallo" und dem Namen ist per `\s*` flexibel
gematched — Flutter könnte ihn durch ein NBSP ersetzen.

Quelle: PW-001 PR #182.

### F-16 · Family-Overview-Card hat kombinierte ProgressBar-Label

Auf dem Parent-Dashboard zeigt die „Familie"-Karte pro Kind eine Zeile, die
als **ProgressBar** mit einem kombinierten accessible name erscheint:

```
role="progressbar" name="Familie Luca Lvl 1 0 MP 0"
```

Pattern: `Familie <ChildName> Lvl <N> <balance> MP <streak>`.

Quelle: PR #181 Seed-Verify + PW-001 PR #182.

### F-17 · PIN-Dialog ist ein Custom-Numeric-Keypad, kein Text-Input

Beim Tap auf einen Avatar mit PIN öffnet sich **kein** Text-Input-Dialog,
sondern ein selbst gebauter numerischer Keypad-Dialog. Strukturiert als:

```
generic: "PIN eingeben"      ← generic text node, nicht heading
button "1" … button "9"      ← ein Button pro Ziffer
button "0"
button                        ← unlabeled (Backspace/Delete)
button "Abbrechen"
```

Wichtige Konsequenzen für Tests:

- Ziffern via `getByRole('button', { name: '1', exact: true })` ansprechen.
  `exact: true` ist Pflicht, sonst matched „1" auch „10 MP", „100 XP" usw.
- **Kein OK-Button**: nach der vierten Ziffer submitet der Dialog automatisch.
  Nicht versuchen, einen Submit-Klick nachzuschieben.
- Bei **falscher PIN** schließt der Dialog ebenfalls, User landet zurück auf
  `/login`, eine Snackbar „Falscher PIN" wird eingeblendet. Die Snackbar ist
  — wie jede andere — doppelt gerendert (siehe F-3), also via
  `flutterText(page, /falscher pin/i)` matchen.
- **Abbrechen** schließt den Dialog ohne Snackbar und ohne Persistenz.
- „PIN eingeben" ist ein generischer Text-Knoten, nicht ein heading —
  Assertion via `flutterText(page, /pin eingeben/i)`.

Referenz-Helper (aktuell lokal in `PW-003-login-user-switching.spec.ts`,
wird nach `fixtures/flutter.ts` gezogen, sobald ein zweiter Test das braucht):

```typescript
async function enterPin(page: Page, pin: string): Promise<void> {
  for (const digit of pin) {
    await page.getByRole('button', { name: digit, exact: true }).click();
  }
}
```

Quelle: PW-003 PR #185.

### F-18 · Logout ist direkt — keine Bestätigungs-Modale

Sowohl im Parent- als auch im Child-Profil-Tab führt ein Klick auf
„Abmelden" **sofort** zur LoginPage. Kein Confirm-Dialog, kein Snackbar-
Undo, nichts dazwischen. Der Button hat in beiden Rollen denselben
accessible name:

```
role="button" name="Abmelden Aus dem Account ausloggen"
```

Match per Regex: `{ name: /abmelden.*ausloggen/i }`.

Der Profil-Tab enthält pro Rolle unterschiedliche **andere** Buttons
(Parent: „Familie verwalten", „Benachrichtigungen", „Erscheinungsbild",
„Hilfe & Support"; Child: „Profil bearbeiten", „Transaktionen",
„Erscheinungsbild", „Hilfe & Support") — aber Abmelden sieht überall gleich
aus.

Quelle: PW-003 PR #185.

### F-19 · DropdownButtonFormField rendert Items als `menuitem`, nicht `option`

Flutters `DropdownButtonFormField` erzeugt beim Öffnen ein Popup mit:

```
role="menu" name="Popup menu"
  └─ group
       └─ menuitem "Kind" [active]
       └─ menuitem "Elternteil"
```

Die Items haben die Rolle **`menuitem`**, NICHT `option` (wie man es bei
einem nativen `<select>` erwarten würde). Der Trigger-Button hat den
aktuellen Auswahltext als accessible name.

**Interaction-Pattern:**

```typescript
// Dropdown öffnen: Button mit dem aktuellen Wert klicken
await page.getByRole('button', { name: /kind/i }).click();
// Item auswählen: menuitem, nicht option
await page.getByRole('menuitem', { name: 'Elternteil' }).click();
```

Quelle: PW-004 PR #TBD.

### F-20 · FamilyManagementPage FAB ist ein Unlabeled Button

Der FloatingActionButton auf der FamilyManagementPage (`Icons.person_add`)
hat weder `tooltip` noch `Semantics(label: ...)`. Er erscheint als Button
mit leerem `textContent`, wie der Remove-Button in B-2.

**Workaround**: `clickUnlabeledButton(page.locator('body'))` — funktioniert,
weil der FAB der einzige unlabeled Button auf der Seite ist.

**Empfohlener App-Fix**: `tooltip: 'Mitglied hinzufügen'` auf dem FAB setzen.

Quelle: PW-004 PR #TBD.

### F-21 · ChoiceChips rendern als `checkbox`, nicht `button`

Flutters `ChoiceChip` und `FilterChip` werden in der Semantics-Tree als
`role="checkbox"` gerendert, nicht als `button`. Selected-State wird über
das `checked`-Attribut signalisiert.

```typescript
// Quest-Typ auswählen (ChoiceChip)
await page.getByRole('checkbox', { name: 'Epic' }).click();
await expect(
  page.getByRole('checkbox', { name: 'Epic' }),
).toBeChecked();

// Rarity (ChoiceChip)
await page.getByRole('checkbox', { name: 'Legendär' }).click();

// Kind-Zuweisung (FilterChip)
await page.getByRole('checkbox', { name: 'Luca' }).click();
```

Quelle: PW-005 PR #TBD.

### F-22 · Quest-Card hat kombinierten Accessible Name

Die Quest-Karte auf der QuestManagementPage rendert als Button mit einem
kombinierten accessible name:

```
role="button" name="Zimmer aufräumen Gewöhnlich Daily 10 Punkte • 100 XP"
```

Pattern: `<Name> <Rarity> <Type> <Points> Punkte • <XP> XP`.

Assertion-Empfehlung: Regex auf Name + Teilinfos, z. B.:

```typescript
await expect(
  page.getByRole('button', { name: /zimmer aufräumen.*20 punkte/i }),
).toBeVisible();
```

Quelle: PW-005 PR #TBD.

### F-23 · Unlabeled AppBar-Actions: CSS-Sibling-Selector statt `clickUnlabeledButton`

Die QuestEditPage hat einen Save-Button (Icons.check) in der AppBar ohne
Tooltip/Semantics-Label. Die naheliegenden Workarounds funktionieren
**nicht zuverlässig**:

- `heading.locator('..')` → flt-semantics-DOM-Nesting stimmt nicht mit
  dem Semantic-Tree überein, Parent-Scope enthält manchmal keine Buttons.
- `clickUnlabeledButton(body)` → icon picker buttons können in der DOM-
  Reihenfolge vor dem Save-Button kommen.
- `evaluate + dispatchEvent('click')` → der synthetische Click geht nicht
  durch Flutters Event-Pipeline, löst manchmal die falsche Aktion aus
  (z. B. öffnet Popup-Menu statt Save).

**Zuverlässiger Fix**: Das Heading rendert als `<h2>`, der Save-Button ist
das nächste `<flt-semantics role="button">`-Sibling. CSS adjacent-sibling
Selector + Playwrights `.click()`:

```typescript
await page.locator('h2 + flt-semantics[role="button"]').click();
```

**Empfohlener App-Fix**: `tooltip: 'Quest speichern'` auf dem IconButton.

Quelle: PW-005 PR #TBD.

### F-24 · `toHaveValue()` funktioniert nicht für pre-filled TextFormFields

Wenn ein `TextFormField` mit einem initialen Controller-Wert (z. B.
`TextEditingController(text: '10')`) erstellt wird, ist der Wert im
Canvas sichtbar, aber das versteckte `<input>`-Element hat `value=""`.
`expect(field).toHaveValue('10')` schlägt fehl.

**Workaround**: Nicht `toHaveValue()` für pre-filled Fields assertieren.
Stattdessen den Wert nach der Aktion via localStorage prüfen.

Verwandt mit F-2 (Flutter-Input-Quirk).

Quelle: PW-005 PR #TBD.

### F-25 · Dismissible-Swipe funktioniert mit Mouse-Drag

Flutters `Dismissible` Widget (Swipe-to-Delete) funktioniert in
Playwright via Mouse-Move-Sequenz:

```typescript
const box = await element.boundingBox();
await page.mouse.move(box.x + box.width - 20, box.y + box.height / 2);
await page.mouse.down();
await page.mouse.move(box.x - 100, box.y + box.height / 2, { steps: 10 });
await page.mouse.up();
```

- `steps: 10` ist wichtig, damit Flutter die Drag-Geste erkennt.
- Drag-Richtung: rechts → links (`endToStart`).
- Nach dem Swipe erscheint der Bestätigungs-Dialog.

Quelle: PW-005 PR #TBD.

### F-26 · Child-Nav „Quests" kollidiert mit „Alle Quests"-Button

Im Child-View (Hero-Home) gibt es auf der Home-Seite einen Button
`"Alle Quests"` **und** den Bottom-Nav-Button `"Quests"`. Ein
`getByRole('button', { name: 'Quests' })` matched beide (F-3-ähnlich).

**Fix**: `{ name: 'Quests', exact: true }` für den Bottom-Nav-Button:

```typescript
await page.getByRole('button', { name: 'Quests', exact: true }).click();
```

Quelle: PW-006 PR #TBD.

### F-27 · Child-Quest-Card enthält Status-Label

Die Quest-Karte im Child-View enthält einen Status-Text im accessible name:

| Status | Label |
|--------|-------|
| Nicht angenommen | `"Verfügbar"` |
| In Arbeit | `"In Bearbeitung"` |
| Erledigt / Pending | Karte verschwindet |

Pattern: `<Name> <Rarity> <Status> <Description> <Points> Punkte <XP> XP`

```typescript
// Verfügbar
page.getByRole('button', { name: /zimmer aufräumen.*verfügbar/i })
// In Bearbeitung
page.getByRole('button', { name: /zimmer aufräumen.*in bearbeitung/i })
```

Quelle: PW-006 PR #TBD.

### F-28 · Quest-Board-Filter-Tabs sind `role="tab"`

Im Child-Quest-Board werden die Filter-Tabs als echte ARIA-Tabs gerendert
(nicht als Buttons oder Checkboxes):

```
tablist:
  tab "Alle" [selected]
  tab "Daily"
  tab "Weekly"
  tab "Epic"
  tab "Series"
```

Selected-State über `aria-selected="true"`.

```typescript
await page.getByRole('tab', { name: 'Daily' }).click();
await expect(page.getByRole('tab', { name: 'Alle' }))
  .toHaveAttribute('aria-selected', 'true');
```

Quelle: PW-006 PR #TBD.

---

## App-Bugs gefunden während Testing

Diese Punkte sind **echte Mängel in der App** (nicht Spec-Fehler). Sie haben
Auswirkungen auf Tests, sollten idealerweise App-seitig gefixt werden.

### B-1 · Parent-Dashboard Bottom-Nav „Approve" statt „Genehmigungen"

Siehe F-11. Translation-Miss in
`lib/pages/parent_dashboard_page.dart` (Bottom-Nav-Tab-Labels).

### B-2 · Member-Remove-IconButton hat kein Semantics-Label

In `FamilySetupPage` Step 3 (Member-Liste) hat der Remove-IconButton
(`lib/pages/setup/family_setup_page.dart:222`) keinen `Semantics(label: ...)`-
Wrapper. Tests müssen mit `clickUnlabeledButton` (siehe F-4) arbeiten.

**Empfohlener Fix**:

```dart
trailing: IconButton(
  icon: const Icon(Icons.delete),
  onPressed: () => _removeMember(index),
  tooltip: 'Mitglied entfernen: ${member.name}',  // oder Semantics-Wrapper
),
```

### B-3 · `PointsProvider.loadData()` wird nicht beim Bootstrap gerufen


Siehe F-9. Ausführlich in `docs/IST_ANALYSE.md` §5.2.

### B-4 · `FamilySetup._finishSetup` loggt den ersten Parent nicht auto-ein

Nach Familien-Setup wird zu `/login` navigiert, nicht zum Dashboard. Siehe
die Spec-Korrektur S-1 unten. Das ist möglicherweise **gewollt** (User soll
einmal aktiv den PIN bestätigen), gehört aber dokumentiert.

### B-5 · FamilyManagementPage FAB hat kein Tooltip / Semantics-Label

Der FloatingActionButton in `lib/pages/family_management_page.dart:20-24`
(`Icons.person_add`) hat weder `tooltip` noch `Semantics(label: ...)`-Wrapper.
Tests müssen mit `clickUnlabeledButton` arbeiten (siehe F-20).

**Empfohlener Fix**:

```dart
FloatingActionButton(
  heroTag: 'family_add_fab',
  tooltip: 'Mitglied hinzufügen',  // ← hinzufügen
  onPressed: () => _showAddMemberDialog(context),
  child: const Icon(Icons.person_add),
),
```

Quelle: PW-004.

### B-6 · QuestEditPage Save-Button hat kein Tooltip / Semantics-Label

Der IconButton (Icons.check) in `lib/pages/parent/quest_edit_page.dart:144`
hat weder `tooltip` noch `Semantics(label: ...)`. Tests müssen den
CSS-Sibling-Selector `h2 + flt-semantics[role="button"]` verwenden
(siehe F-23).

**Empfohlener Fix**:

```dart
IconButton(
  icon: const Icon(Icons.check),
  tooltip: 'Quest speichern',  // ← hinzufügen
  onPressed: _save,
),
```

Quelle: PW-005.

---

## Spec-Korrekturen

Spec-Korrekturen sind **Fehler in den Markdown-Specs** unter
`docs/tests/playwright/PW-*.md`, die während der Implementierung aufgefallen
sind. Sie sind inzwischen behoben, aber die Root Causes sind erhaltenswert.

### S-1 · PW-002 TC-002.1 dachte, der erste Parent wird auto-eingeloggt

Die Spec sagte:

> After „Fertig" the parent is automatically logged in → Parent-Dashboard

Tatsächlich navigiert `FamilySetupPage._finishSetup()` hart zu `/login`. Der
Parent muss manuell den PIN-Login durchlaufen. Korrigiert in PR #181 Review-Runde.

### S-2 · Sämtliche Specs haben initial „Genehmigungen"-Labels

Mehrere Specs (PW-003, PW-007, PW-016) nehmen Bottom-Nav-Labels wie
`"Genehmigungen"` an, obwohl der echte Label-String `"Approve"` ist (siehe F-11).
Ist kein Spec-Bug im strikten Sinne — die Specs beschreiben das Soll. Tests
werden `"Genehmigungen"` **als Assertion nehmen**, und deshalb fehlschlagen,
bis die App translated wird. Das ist bewusst so und dokumentiert — der Test
fängt den Bug.

Alternative Strategie: Tests beschreiben Ist-Verhalten mit einem `test.fail()`
oder Kommentar-Marker bis der App-Fix kommt. Für PW-003 wird das beim
Implementieren entschieden.

### S-3 · PW-005 Spec-Abweichungen

Drei Testfälle in der PW-005-Spec stimmten nicht mit dem App-Verhalten
überein und wurden im Test angepasst:

1. **TC-005.2** sagt „Typ Weekly, Rarity Epic, Deadline (in 7 Tagen)".
   Deadline-Feld erscheint aber nur für **Typ Epic**. Test verwendet
   Typ=Epic statt Weekly.

2. **TC-005.3** erwartet `targetCount 5` im Formular. Das Feld existiert
   im Model (`Quest.targetCount`), wird aber **nicht in der UI** exponiert.
   Nur das Unit-Feld ist für Series-Quests verfügbar. Test prüft nur Unit.

3. **TC-005.5** (Deaktivieren) ist **nicht implementiert** — es gibt keinen
   isActive-Toggle in der QuestEditPage (im Gegensatz zur RewardEditPage,
   die einen SwitchListTile „Aktiv" hat). Test ist `test.skip()`.

Quelle: PW-005 PR #TBD.

---

## Dependency-Stolpersteine

### D-1 · `@playwright/cli` darf NICHT als devDependency

`@playwright/cli@0.1.6` (Microsofts LLM-optimierter Explorations-CLI mit
`snapshot`, `click`, `fill`, `eval`) bringt als Transitive-Dep ein
top-level `playwright@1.60.0-alpha-*`. Diese Alpha-Version **enthält einen
eigenen Test-Runner**. Wenn gleichzeitig `@playwright/test@1.59.x` dev-installed
ist, sehen Testfiles zwei verschiedene Runner-Kopien und bekommen den Fehler

```
Error: Playwright Test did not expect test.describe() to be called here.
[…] You have two different versions of @playwright/test.
```

**Fix** — `e2e/package.json`:

```json
"devDependencies": {
  "@playwright/test": "^1.59.1"   // nur das, NICHT @playwright/cli
}
```

CLI-Nutzung für Exploration läuft über `npx`:

```bash
npx --yes -p @playwright/cli playwright-cli open http://127.0.0.1:8766 --persistent
npx --yes -p @playwright/cli playwright-cli snapshot
```

oder via npm-Script `"cli": "npx --yes -p @playwright/cli playwright-cli"` und
dann `npm run cli -- snapshot`.

Quelle: Bootstrap PR #181 Review-Runde.

### D-2 · Preflight-Script der `oa-playwright-cli`-Skill hat falsche Versionen

Das Preflight-Script sagt `npm install -g @playwright/cli@latest` — latest ist
aber `0.1.6`, während der Skill von `1.49.x` ausgeht. Nicht schlimm, aber
irritierend. Die korrekte Install-Zeile ist einfach `@playwright/cli`, den
Rest macht npm.

Quelle: Bootstrap PR #181.

---

## Entwicklungs-Workflow

### W-1 · Immer erst explorieren, dann schreiben

Der mit Abstand produktivste Ablauf für eine neue PW-NNN-Spec ist:

1. **Server starten**: `python3 -m http.server 8766 --directory build/web`
   (oder `flutter build web` wenn stale)
2. **CLI öffnen**: `npx --yes -p @playwright/cli playwright-cli -s=pwXXX open http://127.0.0.1:8766 --persistent`
3. **Semantics aktivieren**:
   ```bash
   playwright-cli eval "(() => { document.querySelector('flt-semantics-placeholder').dispatchEvent(new MouseEvent('click', { bubbles: true })); return 'ok'; })()"
   ```
4. **Seed ggf. manuell injizieren** über `playwright-cli eval` (siehe
   `/tmp/seed_script.js`-Muster in den PR-Kommentaren).
5. **Snapshot**: `playwright-cli snapshot` → zeigt alle role+name-Tupel.
6. **Interagieren**: `fill`, `click`, `snapshot` bis man den Flow kennt.
7. **Ergebnisse in `PW-NNN.spec.ts` crystallisieren** — erst JETZT Code schreiben.

Ohne Schritte 1-6 schreibt man 90% der Test-Asserts falsch und verbrennt
Feedback-Zyklen mit fehlerhaften Locator-Annahmen.

### W-2 · Test gegen pre-built `build/web` ist der schnellste Loop

Tests laufen **lokal** am schnellsten gegen einen statischen Python-Server
auf `build/web`:

```bash
# Terminal 1
python3 -m http.server 8766 --directory build/web

# Terminal 2
cd e2e
CI=true E2E_BASE_URL=http://127.0.0.1:8766 npx playwright test <datei> --reporter=list
```

- `CI=true` disabled den `webServer`-Block aus der Config und nutzt die
  eigene Server-Instanz.
- `E2E_BASE_URL` zeigt auf den laufenden Server.
- Alle 14 Tests gehen in ~17 s durch (Stand 2026-04-12).

Gegen `make e2e` braucht ein Lauf ~35 s wegen Flutter-Build. Für CI und für
Smoke-Tests sinnvoll, für iterative Entwicklung zu langsam.

### W-3 · Bei Flakiness **nicht** retryen — Root Cause finden

Playwrights Retry-Mechanik maskiert determinische Bugs. Wenn ein Test
„flaky" scheint (grün auf Retry), geh davon aus, dass er in Wahrheit kaputt
ist und einer von:

- Strict-mode-Violation durch doppelte Matches (→ F-3)
- Racing gegen Flutter-Boot oder Semantics-Aktivierung (→ F-1)
- Fill-Race wegen fehlender Settle-Time (→ F-2)
- Async-UI-Update, auf das man nicht wartet

Alle drei Fälle schon getroffen. Kein einziger echter Flakiness-Fall in
PW-001 / PW-002 bisher — jede Instabilität war eine der o. g. Ursachen.

### W-4 · PR-Review-Check: erst Lokal, dann CI

Jeder Test-PR folgt dem Flow:

1. Lokal: `CI=true E2E_BASE_URL=… npx playwright test` grün (alle Tests, nicht
   nur die neuen)
2. Committen + pushen
3. `gh pr create` mit Spec-Link, Test-Plan und offenen Fragen
4. CI beobachten: `gh run list --branch … --limit 3`
5. Auf user-Feedback warten — NICHT selbst mergen
6. Nach Merge: `git checkout main && git pull` → nächste PW-NNN starten

### W-5 · Seed-Fixture-Overrides statt neue Fixtures

Wenn eine neue Test-Variante einen minimal abweichenden Seed-Zustand braucht,
**nicht** gleich einen neuen Fixture-Builder schreiben. Stattdessen:

```typescript
const page = await seededPage({
  ...seedFamilyWithChild(),
  lastUserId: null,              // Override: kein User eingeloggt
});
```

Nur wenn dieselbe Variante in mehreren Specs auftaucht, lohnt sich ein eigener
Builder in `seed.ts`.

### W-6 · Diese Datei ist ein Force-Multiplier — pflegen, pflegen, pflegen

PW-001 und PW-002 haben zusammen ca. 6 Iterationen gebraucht, bis die
Helpers (`flutterFill`, `flutterText`, `clickUnlabeledButton`), das
Seed-Format und die Locator-Entscheidungen stimmten. **PW-003 lief beim
ersten Versuch grün.** Der einzige Unterschied: alle relevanten Findings
waren bis dahin katalogisiert und PW-003 konnte sie direkt wiederverwenden.

Die Datei hat einen messbaren ROI — aber nur, wenn jeder neue Finding
auch sofort reingeschrieben wird. Wenn du einen Quirk findest und ihn
„später" dokumentieren willst, vergisst du es. Schreib ihn **im selben
PR** rein, in dem du ihn entdeckt hast. Die Maintenance-Regel im Header
oben ist absichtlich strikt.

Quelle: Retro-Beobachtung nach PW-003 PR #185.

---

## Offene Punkte / nächste Updates

Nächste Kandidaten für neue Findings (werden beim Implementieren der
jeweiligen Spec erwartet):

- **PW-014 Streak** — Time/Clock-Simulation via `page.addInitScript` oder
  `page.clock.install`. Noch nicht erprobt.
- **PW-015 Notifications** — Badge-Zähler an der Glocke, Read-State-Assertion,
  User-Isolation der Inbox.
- **PW-011/12 Transactions + Progression** — hier greift die IST-Analyse-§5.2-
  Lücke (PointsProvider.loadData nicht beim Bootstrap gerufen), die Tests
  müssen vermutlich raw localStorage prüfen, wie `seed-verify.spec.ts` es
  für childWithApprovedQuest schon vormacht.
- **PW-007 Approval + Level-Up** — die Level-Up-Animation muss ohne hard sleep
  abgehandelt werden. Vermutlich via `waitForSelector` auf einen Dialog +
  dessen Verschwinden.

Wenn du ein neues Finding machst, hänge es oben in der passenden Sektion
an, aktualisiere die Quellen-Zeile ganz oben im Header und — falls sich
am Workflow etwas ändert — die entsprechende W-*-Sektion.
