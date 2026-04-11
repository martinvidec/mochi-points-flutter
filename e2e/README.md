# Mochi Points — E2E Test Suite (Playwright)

End-to-End-Tests für das Flutter-Web-Target der Mochi-Points-App, basierend
auf den Specs in [`../docs/tests/playwright/`](../docs/tests/playwright/)
und der zugehörigen [IST-Analyse](../docs/IST_ANALYSE.md).

## Ordnerstruktur

```
e2e/
├── package.json          # isolierte Test-Dependencies
├── playwright.config.ts  # Runner-Konfiguration + webServer für local dev
├── README.md             # diese Datei
└── tests/
    ├── fixtures/
    │   ├── flutter.ts    # Flutter-Boot + Semantics-Tree aktivieren
    │   ├── seed.ts       # localStorage-Seeds (SharedPreferences)
    │   └── index.ts      # kombiniertes test-fixture
    └── specs/
        ├── smoke.spec.ts # verifiziert, dass Boot + Semantics funktionieren
        └── PW-*.spec.ts  # eine Datei pro Playwright-Spec (folgt in eigenen PRs)
```

## Voraussetzungen

- Node.js ≥ 18
- Flutter 3.41.2+ (siehe `../CLAUDE.md`)
- Chromium-Browser für Playwright (wird per `npx playwright install` bezogen)

## Lokale Ausführung

### Schneller Weg — `make e2e` vom Repo-Root

```bash
make e2e
```

Der Makefile-Target installiert Dependencies (`npm install`), lädt Chromium
für Playwright (`npx playwright install chromium`) und startet den Runner.
Der Runner startet dank `webServer`-Konfiguration automatisch
`flutter run -d web-server` auf Port 8080, falls noch nichts läuft.

### Manueller Weg

```bash
cd e2e
npm install
npx playwright install chromium
npm test
```

### Headed / Debug

```bash
cd e2e
npm run test:headed   # mit sichtbarem Browser
npm run test:debug    # Playwright Inspector (PWDEBUG=1)
```

### Nur einen einzelnen Test

```bash
cd e2e
npx playwright test tests/specs/smoke.spec.ts
```

### Report anzeigen

```bash
cd e2e
npm run show-report
```

## Warum Flutter Web eine Sonderrolle spielt

Flutter Web rendert in einen einzelnen `<canvas>`. DOM-basierte Locators
finden erst dann Treffer, wenn die **Flutter-Semantics-Tree** aktiv ist.
Flutter deaktiviert sie per Default und aktiviert sie nur, wenn es
eine Screenreader-Absicht erkennt oder der versteckte
`<flt-semantics-placeholder>` geklickt wird.

`tests/fixtures/flutter.ts::openFlutterApp` übernimmt das:

1. `page.goto(path)`
2. auf `<flt-semantics-placeholder>` warten (Boot-Signal)
3. diesen Placeholder klicken → Semantics-Tree wird gebaut
4. auf erstes `<flt-semantics>`-Element warten

Jedes Test-Fixture (`flutterPage`, `seededPage`) ruft das automatisch auf.

> **Wenn ein Test kein Role-Locator-Target findet**, liegt das meist daran,
> dass das Flutter-Widget nicht in ein `Semantics(...)` eingepackt ist. Der
> Fix gehört dann in den Dart-Code der App, **nicht** in den Test.

## Seed-Daten / Fixtures

`tests/fixtures/seed.ts` stellt Builder für die in
[`../docs/tests/playwright/README.md`](../docs/tests/playwright/README.md)
definierten Shared-Fixtures bereit:

| Fixture-Builder | Beschreibung |
|---|---|
| `seedFreshApp()` | leerer Zustand, erster App-Start |
| `seedFamilyWithParent()` | Familie + Parent „Mama" (PIN 1234), eingeloggt |
| `seedFamilyWithChild()` | + Child „Luca", Hero Level 1 |
| `seedFamilyWithQuestAndReward()` | + 1 Daily-Quest (10 MP, 50 XP) + 3 Rewards |
| `seedChildWithApprovedQuest()` | + 1 bereits genehmigte Quest → Luca hat 10 MP, 50 XP, Streak 1 |

Die Seeds werden über `page.addInitScript` in `localStorage` geschrieben,
bevor Flutter bootet. Die Keys folgen dem `flutter.<key>`-Schema, das
`shared_preferences_web` in Flutter Web verwendet.

Verwendung in einem Test:

```typescript
import { test, expect } from '../fixtures';
import { seedFamilyWithChild } from '../fixtures/seed';

test('parent sees dashboard', async ({ seededPage }) => {
  const page = await seededPage(seedFamilyWithChild());
  await expect(
    page.getByRole('heading', { name: /hallo,\s*mama/i })
  ).toBeVisible();
});
```

## CI-Integration

`.github/workflows/e2e-web.yml` führt die Suite bei jedem Push / PR gegen
`main` aus. Die Workflow baut `flutter build web --release --no-tree-shake-icons`,
serviert den Output statisch über `npx serve` auf Port 8080 und startet die
Playwright-Suite mit `E2E_BASE_URL=http://127.0.0.1:8080`.

Bei einem fehlgeschlagenen Run wird der `playwright-report` als Artifact
hochgeladen. Traces landen dort auf dem ersten Retry.

## Nächste Schritte

- PR #164 → gemerged: IST-Analyse + 16 Playwright-Specs unter `docs/tests/playwright/`
- **dieser PR (Bootstrap)**: Scaffold, Smoke-Test, CI-Workflow, Makefile-Target
- Folgend: eine PR pro Playwright-Spec (PW-001..PW-016), siehe
  [`../docs/tests/playwright/README.md`](../docs/tests/playwright/README.md) §Spec-Index
