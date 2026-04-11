# Playwright E2E Specs — Mochi Points (Flutter Web)

Dieser Ordner enthält **ausführbare Spezifikationen** für eine vollständige
End-to-End-Abdeckung der Mochi-Points-App via Playwright. Grundlage ist die
IST-Analyse (`docs/IST_ANALYSE.md`), die 11 Hauptprozesse (P1–P11) entlang der
Akteure *Eltern / Kind / System* beschreibt. Jede Spec hier deckt einen dieser
Prozesse (oder einen klar umrissenen Teil) ab und ist Grundlage für genau eine
Playwright-Test-Datei.

> **Vor dem Schreiben einer neuen PW-NNN-Spec**: lies
> [`FINDINGS.md`](FINDINGS.md). Dort sind alle Flutter-Web-spezifischen
> Stolpersteine, Helper-APIs, Seed-Konventionen und UI-Label-Eigenheiten
> gesammelt, die während der bisherigen Spec-Implementierungen aufgefallen
> sind. Das spart garantiert Zeit.

## Ziel

- **Eine Spec ⇔ eine Test-Datei ⇔ ein GitHub-Issue** (Label `playwright`).
- Jede Spec ist so formuliert, dass sie ohne die App-Sourcen lesbar ist
  und sich direkt in einen `*.spec.ts` übersetzen lässt.
- Assertions und Erwartungen sind konkret genug, um Regressionen zu finden,
  aber locker genug, um UI-Refactorings zu überleben (rollenbasierte Locators).

## Test-Stack (SOLL)

| Komponente | Entscheidung |
|---|---|
| Runner | `@playwright/test` (TypeScript) |
| Target | Flutter Web Build (`build/web`) via `python3 -m http.server 8765 --directory build/web` oder statischer Dev-Server |
| Build | `flutter build web --no-tree-shake-icons` (gemäß `CLAUDE.md`) |
| Locators | Rollenbasiert (`getByRole`, `getByLabel`, `getByText`) über die Flutter-Semantics-Tree |
| CI-Hook | `make e2e` / npm script, wird vor dem Merge auf `main` ausgeführt |

> **Flutter-Web-Hinweis:** Flutter rendert auf Canvas. Role-basierte Locators
> funktionieren nur, wenn die Semantics-Tree aktiv ist. Das wird beim ersten
> Fokus-/Klick-Event oder über einen unsichtbaren Semantic-Placeholder
> aktiviert. Die `build-integration-dart-flutter.md`-Reference der
> `oa-playwright-cli`-Skill erklärt die Details — **nicht** in jeder Spec
> wiederholen.

## Shared Fixtures (SOLL)

Viele Specs bauen auf identischen Vorzuständen auf. Die Implementierung soll
diese als Fixtures bereitstellen, damit sie nicht in jedem Test reproduziert
werden müssen:

| Fixture | Enthält |
|---|---|
| `freshApp` | Leeres SharedPreferences-Storage (Cold Start, keine Family) |
| `familyWithParent` | Family „Test-Familie" + Parent „Mama" (PIN 1234) |
| `familyWithChild` | zusätzlich Child „Luca" (ohne PIN), Hero Level 1 |
| `familyWithQuestAndReward` | zusätzlich 1 Quest (common, 10 MP, 50 XP) + 1 Reward (50 MP) |
| `childWithApprovedQuest` | `familyWithQuestAndReward` + Quest wurde akzeptiert, erledigt und approved → Hero hat 10 MP, 50 XP |

Das Setup erfolgt vorzugsweise über einen **Test-Seed-Hook** auf `window.localStorage`
vor dem ersten `page.goto()`, nicht über UI-Klick-Sequenzen. Ausnahme: Specs, die
explizit den Onboarding-/Registrierungs-Flow prüfen.

## Konventionen

- **IDs:** `PW-<NNN>`, fortlaufend.
- **Dateiname:** `PW-<NNN>-<kebab-case-title>.md`.
- **Mapping zu Prozessen:** jede Spec referenziert die passende `P*`-Sektion in
  `docs/IST_ANALYSE.md`.
- **Schnitt:** Eine Spec = ein zusammenhängender User-Flow. Atomare Einzelchecks
  sind **test cases** innerhalb der Spec, keine eigene Spec.
- **Sprache:** Specs auf Deutsch (Business/UX-Labels sind deutsch), Code-Snippets
  und Test-Namen auf Englisch.

## Spec-Template

Jede Spec MUSS diese Abschnitte enthalten:

```
# PW-<NNN>: <Titel>
- Prozess: P<N> …
- Actor: Parent | Child | beide
- Status: draft | ready

## Zielsetzung
…

## Preconditions / Fixtures
- Fixture: …

## Testfälle
### TC-<NNN>.1 — <Happy Path>
Given …
When …
Then …

Assertions:
- `await expect(page.getByRole('heading', { name: '…' })).toBeVisible()`

### TC-<NNN>.2 — <Negative Path> …

## Out of Scope
…

## Offene Fragen
…
```

## Spec-Index

| ID | Prozess | Titel | Actor |
|---|---|---|---|
| [PW-001](PW-001-bootstrap-routing.md) | P1 | App Bootstrap & Routing | System |
| [PW-002](PW-002-family-onboarding.md) | P2 | Familie einrichten (Onboarding) | Parent |
| [PW-003](PW-003-login-user-switching.md) | P3 | Login & Benutzerwechsel | beide |
| [PW-004](PW-004-family-management.md) | P4 | Familienmitglied hinzufügen | Parent |
| [PW-005](PW-005-parent-quest-crud.md) | P5 | Parent: Quest CRUD | Parent |
| [PW-006](PW-006-child-quest-lifecycle.md) | P5 | Child: Quest akzeptieren & erledigen | Child |
| [PW-007](PW-007-parent-quest-approval.md) | P5 | Parent: Quest Approval & Rejection | Parent |
| [PW-008](PW-008-parent-reward-crud.md) | P6 | Parent: Reward CRUD | Parent |
| [PW-009](PW-009-child-shop-purchase.md) | P6 | Child: Shop-Kauf | Child |
| [PW-010](PW-010-reward-redemption.md) | P6 | Reward-Einlösung (Child + Parent) | beide |
| [PW-011](PW-011-transaction-history.md) | P7 | Punktekonto & Transaktions-Historie | Child |
| [PW-012](PW-012-hero-progression.md) | P8 | Hero-Progression (XP, Level-Up) | Child |
| [PW-013](PW-013-hero-appearance.md) | P8 | Hero-Appearance-Customization | Child |
| [PW-014](PW-014-streak-bonus.md) | P9 | Streak-Anzeige & Bonus | Child |
| [PW-015](PW-015-notifications-inbox.md) | P10 | Benachrichtigungen (Inbox) | beide |
| [PW-016](PW-016-navigation-logout.md) | — | Bottom-Navigation & Logout | beide |

## Explizit NICHT abgedeckt

- **P11 Achievements** — laut IST-Analyse §5.1 nicht verdrahtet. Sobald der
  Flow (Seeding + `checkAchievements` + `onAchievementUnlocked`) implementiert
  ist, wird eine Spec `PW-017-achievements.md` ergänzt.
- **`NotificationType.rewardPurchased`** und weitere laut IST-Analyse §5.6
  deklarierte, aber nicht verdrahtete Notification-Typen.
- **Native Flutter Integration-Tests** (`integration_test/`) — gehören nicht
  in diesen Ordner; siehe Hinweis in der `oa-playwright-cli`-Skill.
