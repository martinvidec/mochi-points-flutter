# PW-010: Reward-Einlösung (Child + Parent)

- **Prozess:** P6 (Teilprozess: Redemption)
- **Actor:** beide (Child löst ein, Parent bestätigt oder lehnt ab)
- **Status:** draft

## Zielsetzung

Nach dem Kauf kann das Kind eine Einlösung anfragen. Der Parent sieht die
Anfrage in „Einlösungen" und bestätigt oder lehnt ab. Bei Ablehnung werden
die Punkte zurückerstattet (refund-Transaktion).

## Preconditions / Fixtures

- `childWithApprovedQuest` + gekaufter Reward „30 min Tablet" (Status
  `purchased`)
- Child „Luca" eingeloggt zum Start

## Testfälle

### TC-010.1 — Einlösung anfragen
```
Given: My-Rewards-Page zeigt „30 min Tablet" (purchased)
When:  „Einlösen" wird geklickt
Then:  Purchase.status wechselt auf „pendingRedemption"
And:   UI-Label ändert sich auf „wartet auf Bestätigung"
```
**Assertions:**
- `localStorage['purchases']` enthält `status == "pendingRedemption"`

### TC-010.2 — Parent sieht pending Redemption
```
Given: Als Parent „Mama" einloggen
When:  Redemption-Page (Parent) geöffnet
Then:  „30 min Tablet" für Luca ist in der Pending-Liste
```
**Assertions:**
- Notification `rewardRedeemed` wurde für den Creator erzeugt
  (siehe IST-Analyse §P10 Tabelle)

### TC-010.3 — Parent bestätigt Einlösung
```
Given: Pending Redemption „30 min Tablet"
When:  Parent klickt „Bestätigen"
Then:  Purchase.status wechselt auf „redeemed"
And:   `redeemedAt` + `redeemedBy` sind gesetzt
And:   In „My Rewards" zeigt Luca den Eintrag als eingelöst
```

### TC-010.4 — Parent lehnt Einlösung ab (Refund)
```
Given: Zweiter Kauf „Eis" (20 MP) durch Luca, Status „pendingRedemption"
When:  Parent klickt „Ablehnen"
Then:  Purchase.status wechselt auf „cancelled"
And:   Luca bekommt 20 MP als Refund gutgeschrieben
And:   Transaction type=refund mit amount=20 existiert
```

### TC-010.5 — Kind bricht ausstehende Einlösung ab (sobald UI dafür existiert)
```
Given: Purchase mit status=pendingRedemption
When:  Luca klickt „Abbrechen"
Then:  Purchase.status wechselt zurück auf „purchased"
```
> **Hinweis:** Diese Möglichkeit existiert laut Issue #153 derzeit **nicht** im
> UI. Der Test MUSS beim Erstellen zunächst `test.skip('waiting for #153')`
> markiert werden und wird automatisch aktiviert, wenn das Issue geschlossen ist.

### TC-010.6 — Kind-Benachrichtigung bei Redemption-Entscheidung (GAP)
```
Given: Parent bestätigt / lehnt Redemption
Then:  Child sollte eine Notification erhalten
```
> **Hinweis:** Laut Issue #152 derzeit **nicht** implementiert. Der Test wird
> ebenfalls zunächst geskippt und aktiviert, sobald #152 geschlossen ist.

## Out of Scope

- Stock-Reduktion (→ PW-009 TC-009.3)
- Kauf-Flow (→ PW-009)

## Offene Fragen

- Welche Copy wird im UI benutzt — „Bestätigen/Ablehnen" oder andere Labels?
  Muss beim Test-Schreiben auf Basis eines `playwright-cli snapshot` verifiziert werden.
