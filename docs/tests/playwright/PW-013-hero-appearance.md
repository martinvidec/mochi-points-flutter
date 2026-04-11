# PW-013: Hero-Appearance-Customization

- **Prozess:** P8 (Teilprozess: Avatar)
- **Actor:** Child
- **Status:** draft

## Zielsetzung

Das Kind kann seinen Avatar (HeroAppearance) anpassen — Grund-Avatar,
Haut, Frisur, Haarfarbe, Outfit. Geänderte Eigenschaften bleiben nach
Reload erhalten.

## Preconditions / Fixtures

- `childWithApprovedQuest` (Hero existiert)
- Child „Luca" eingeloggt

## Testfälle

### TC-013.1 — Appearance-Seite öffnen
```
Given: Hero-Home → Profil-Tab → „Avatar anpassen"
Then:  HeroCustomizationPage wird angezeigt
And:   Aktueller Avatar wird in der Vorschau gerendert
```

### TC-013.2 — Frisur ändern
```
Given: Appearance-Seite
When:  Neue Frisur wählen (z. B. „long")
Then:  Vorschau aktualisiert sich live
```

### TC-013.3 — Änderungen speichern & persistent
```
Given: Frisur und Outfit geändert
When:  Speichern
Then:  Erfolgs-Snackbar
And:   Reload der Seite zeigt die neuen Werte
And:   `heroes[0].appearance` in SharedPreferences enthält die neuen Werte
```

### TC-013.4 — Gesperrte Items sind nicht auswählbar
```
Given: Hero hat das Item „goldenes Outfit" NICHT in `unlockedItems`
When:  Appearance-Seite geöffnet
Then:  „goldenes Outfit" ist ausgegraut oder markiert als gesperrt
And:   Klick hat keinen Effekt bzw. zeigt Hinweis
```

### TC-013.5 — Item equippen/unequippen
```
Given: Hero hat Item „Hut" in `unlockedItems`, aber nicht equipped
When:  „Hut" wird equippt
Then:  `equippedItems` enthält „Hut" (Persistenz-Check)
When:  „Hut" wird wieder entfernt
Then:  `equippedItems` enthält „Hut" nicht mehr
```

## Out of Scope

- XP / Level → PW-012
- Unlock-Mechanik über Level-Up (nicht verdrahtet)

## Offene Fragen

- Sind alle Item-Varianten im Dropdown als Rolle `radio` oder als `button`
  umgesetzt? Betrifft den Locator.
