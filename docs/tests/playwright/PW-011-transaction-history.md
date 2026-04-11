# PW-011: Punktekonto & Transaktions-Historie

- **Prozess:** P7
- **Actor:** Child
- **Status:** draft

## Zielsetzung

Das Kind kann seine Transaktions-Historie einsehen. Die Historie listet
Quest-Completions, Boni, Käufe, Refunds, Adjustments in chronologischer
Reihenfolge mit korrektem `balanceAfter`.

## Preconditions / Fixtures

- `childWithApprovedQuest` (Child hat eine abgeschlossene Quest mit 10 MP)
- Zusätzlich per Seed: 1 Kauf (−20 MP) + 1 Refund (+20 MP)

## Testfälle

### TC-011.1 — Liste zeigt alle Transaktionen chronologisch
```
Given: TransactionHistoryPage geöffnet
Then:  3 Einträge in der Reihenfolge: refund (+20), purchase (−20), questComplete (+10)
And:   `balanceAfter` stimmt pro Zeile mit dem fortschreitenden Saldo überein
```

### TC-011.2 — Filter nach Typ
```
Given: TransactionHistory mit allen 3 Transaktions-Typen
When:  Filter „Nur Käufe" aktiviert
Then:  Nur der Purchase-Eintrag ist sichtbar
```
> Falls kein Filter-UI existiert: Testfall entfällt, wird im Test-File als
> `test.skip('no filter UI yet')` markiert.

### TC-011.3 — Leere Historie
```
Given: Frisches Child ohne Transaktionen
When:  TransactionHistoryPage geöffnet
Then:  Empty-State „Noch keine Transaktionen" wird angezeigt
```

### TC-011.4 — Wochen-Summe
```
Given: Heute wurde eine Quest mit 10 MP approved
Then:  Hero-Home / Stats-Karte zeigt „diese Woche: 10 MP"
```

## Out of Scope

- Monats-/Jahres-Reports (nicht implementiert)
- Export (nicht implementiert)

## Offene Fragen

- Wird `balanceAfter` tatsächlich in der UI gerendert oder nur intern gespeichert?
  → Assertion ggf. nur gegen `localStorage` statt gegen die UI.
