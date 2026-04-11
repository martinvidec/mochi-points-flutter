# PW-004: Familienmitglied hinzufügen

- **Prozess:** P4 (eingeschränkt — siehe IST-Analyse §5.4)
- **Actor:** Parent
- **Status:** draft

## Zielsetzung

Ein bereits eingeloggter Parent kann im Profil-Tab die Familienverwaltung
öffnen und weitere Mitglieder hinzufügen. Edit/Remove/PIN-Reset existieren
laut IST-Analyse aktuell nicht; diese Spec beschränkt sich deshalb auf den
implementierten Lesezugriff und das Hinzufügen.

## Preconditions / Fixtures

- `familyWithParent` (Parent „Mama" eingeloggt, noch kein Kind)

## Testfälle

### TC-004.1 — Liste vorhandener Mitglieder
```
Given: Parent eingeloggt, FamilyManagement-Seite geöffnet
Then:  „Mama" erscheint als Parent
And:   Keine weiteren Mitglieder sichtbar
```
**Assertions:**
- `await expect(page.getByText('Mama')).toBeVisible()`

### TC-004.2 — Kind hinzufügen
```
Given: FamilyManagement-Seite
When:  „Mitglied hinzufügen" wird gewählt
And:   Name „Luca", Rolle „Child", kein PIN
And:   Speichern
Then:  „Luca" erscheint in der Mitgliederliste mit Rolle „Kind"
And:   `localStorage['family_members']` enthält einen Child-Eintrag
```

### TC-004.3 — Zweiten Parent hinzufügen
```
Given: FamilyManagement-Seite
When:  Mitglied „Papa" mit Rolle „Parent" + PIN „5555" hinzufügen
Then:  „Papa" erscheint in der Mitgliederliste mit Rolle „Parent"
And:   Papa lässt sich auf der LoginPage mit PIN 5555 anmelden
        (separater Assertion-Flow, siehe PW-003)
```

### TC-004.4 — Abbrechen beim Hinzufügen
```
Given: FamilyManagement-Seite
When:  „Mitglied hinzufügen" → Dialog/Page öffnen → Abbrechen
Then:  Kein neues Mitglied wird persistiert
```

## Out of Scope

- **Edit / Remove / PIN-Reset** existieren laut IST-Analyse nicht → werden
  erst getestet, wenn sie implementiert sind. Bis dahin wird in dieser Spec
  ein Skip-Vermerk eingetragen (z. B. `test.skip('requires AuthProvider.updateMember')`).
- Family umbenennen

## Offene Fragen

- Ist der Flow „Mitglied hinzufügen" eine eigene Page oder ein Bottom-Sheet?
  Die Spec behandelt beide UX-Varianten.
