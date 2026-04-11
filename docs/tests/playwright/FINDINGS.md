# Playwright + Flutter Web: Findings

Stand: 2026-04-12
Quellen: PR #181 (Bootstrap), #182 (PW-001), #183 (PW-002)

Dieses Dokument ist ein **lebender Katalog** aller nicht-offensichtlichen
Erkenntnisse, die bei der Arbeit an der E2E-Test-Suite unter `e2e/` aufgefallen
sind. Wenn du eine neue PW-NNN-Spec implementierst, lies dieses Dokument
**bevor** du Zeit mit Trial-and-Error verbrennst — mit großer Wahrscheinlichkeit
hat jemand das Problem schon einmal gelöst. Wenn du ein neues Finding machst,
hänge es unten an mit Datum + PR-Referenz.

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

---

## Offene Punkte / nächste Updates

- **PW-003 (Login & Benutzerwechsel, #167)** — noch nicht implementiert. Hot
  candidate für neue Findings: PIN-Dialog-Locator, Snackbar für „Falscher PIN",
  Abbrechen-Verhalten im PIN-Dialog.
- **Streak-/Time-Simulation** — PW-014 braucht Clock-Injection über
  `page.addInitScript`. Noch nicht erprobt, wird beim Implementieren ergänzt.
- **Notifications-Glocke** — wie badget die Zahl, welche Rolle? PW-015.

Wenn du ein neues Finding machst, hänge es oben in der passenden Sektion
an und aktualisiere die Zusammenfassung oben (Datum + Quelle).
