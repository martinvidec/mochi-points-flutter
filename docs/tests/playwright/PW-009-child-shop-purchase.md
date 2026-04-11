# PW-009: Child — Shop-Kauf

- **Prozess:** P6 (Teilprozess: Child-Kauf)
- **Actor:** Child
- **Status:** draft

## Zielsetzung

Ein Kind mit ausreichend Punkten kann einen Reward im Shop kaufen. Punkte
werden abgezogen, ein `Purchase`-Eintrag entsteht, bei limitiertem Stock
reduziert sich der verfügbare Bestand. Ohne ausreichende Punkte ist der Kauf
nicht möglich.

## Preconditions / Fixtures

- `childWithApprovedQuest` (Child hat ≥ 10 MP)
- Rewards:
  - „30 min Tablet" (50 MP, unbegrenzt)
  - „Eis" (20 MP, Stock=2)
  - „Premium-Item" (1000 MP) ← bewusst zu teuer
- Child „Luca" eingeloggt

## Testfälle

### TC-009.1 — Shop zeigt verfügbare Rewards inkl. Preis
```
Given: Hero-Home → Shop-Tab
Then:  Alle 3 Rewards sind sichtbar, jeweils mit Preis
And:   Balance-Anzeige oben rechts stimmt mit Child-Balance überein
```

### TC-009.2 — Reward kaufen (Happy Path)
```
Given: Luca hat mindestens 50 MP
When:  „30 min Tablet" wählen → „Kaufen"
Then:  Balance sinkt um 50 MP
And:   Purchase-Bestätigungs-Feedback sichtbar
And:   In „My Rewards" erscheint der Kauf mit Status „purchased"
And:   `localStorage['transactions']`: neuer Eintrag type=purchase amount=-50
```

### TC-009.3 — Limitierter Stock wird reduziert
```
Given: „Eis" hat Stock 2 und Luca hat ≥ 20 MP
When:  Luca kauft „Eis" einmal
Then:  Stock-Anzeige zeigt „1"
And:   `rewards[].stock` in Storage == 1
```

### TC-009.4 — Ausverkaufter Reward
```
Given: Stock = 0 auf „Eis"
When:  Shop geladen
Then:  „Eis" ist entweder ausgegraut oder nicht mehr käuflich
And:   Kauf-Versuch schlägt fehl (Button disabled oder Fehlermeldung)
```

### TC-009.5 — Zu wenig Punkte
```
Given: Luca hat 10 MP, „Premium-Item" kostet 1000 MP
When:  Luca versucht zu kaufen
Then:  Kauf schlägt fehl (Snackbar/Toast o. ä.)
And:   Balance bleibt unverändert
And:   Kein neuer Purchase wird persistiert
```

### TC-009.6 — Kategorie-Filter im Shop
```
Given: Rewards aus PW-008/TC-008.3 existieren (alle 4 Kategorien)
When:  Filter-Chip „Privilege" wird gewählt
Then:  Nur Privilege-Rewards sind sichtbar
```

## Out of Scope

- Einlösung → PW-010
- Bonuspreise, Rabatte, Coupons — nicht implementiert

## Offene Fragen

- Ist das Points-Display im Shop zwingend sichtbar? Aktuell ja — Spec
  nimmt das als Assertion auf.
