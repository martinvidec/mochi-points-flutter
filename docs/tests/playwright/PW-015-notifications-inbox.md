# PW-015: Benachrichtigungen (Inbox)

- **Prozess:** P10
- **Actor:** beide
- **Status:** draft

## Zielsetzung

Die Inbox enthält alle für den jeweiligen User erzeugten Notifications,
sortiert nach Datum (neueste zuerst). Die Glocke im Dashboard zeigt einen
Badge mit ungelesener Anzahl. Markieren als gelesen (einzeln + alle) ist
möglich.

## Preconditions / Fixtures

- `familyWithQuestAndReward`
- Seed-Zustand: pro Notification-Typ (siehe IST-Analyse §P10 Tabelle) jeweils
  mindestens eine Notification pro betroffenem User

## Testfälle

### TC-015.1 — Badge-Zähler zeigt ungelesene
```
Given: Child „Luca" mit 3 ungelesenen Notifications
When:  Hero-Home geöffnet
Then:  Notification-Glocke trägt Badge „3"
```

### TC-015.2 — Inbox-Liste rendert alle Typen
```
Given: Luca hat Notifications: questApproved, questRejected, levelUp, streakMilestone
When:  Inbox geöffnet
Then:  Alle 4 Einträge sind sichtbar
And:   Sortierung: neueste oben
```

### TC-015.3 — Einzelne Notification als gelesen markieren
```
Given: Inbox mit ungelesenen Einträgen
When:  Eine Notification wird getappt/„gelesen"-markiert
Then:  Sie erscheint visuell als gelesen
And:   Badge-Zähler sinkt um 1
```

### TC-015.4 — Alle als gelesen markieren
```
Given: Inbox mit 3 ungelesenen Einträgen
When:  „Alle gelesen" wird geklickt
Then:  Badge verschwindet (Zähler 0)
And:   `localStorage['notifications']` hat alle betroffenen isRead=true
```

### TC-015.5 — Parent sieht eigene Notifications
```
Given: Parent „Mama" hat Notifications questCompleted, rewardRedeemed
When:  Parent-Dashboard öffnen
Then:  Glocke zeigt Badge „2"
And:   Inbox listet beide Einträge
```

### TC-015.6 — Notifications sind User-isoliert
```
Given: Luca hat 3, Mama hat 2
When:  Mama öffnet die Inbox
Then:  Nur Mama-Notifications sind sichtbar (keine Vermischung)
```

## Out of Scope

- Push-Notifications außerhalb der App (nicht implementiert)
- Notification-Settings-Page (separate UI, nicht Teil dieser Spec)

## Offene Fragen

- Löscht die App jemals alte Notifications? Aktuell offenbar nicht —
  Spec nimmt das nicht als Assertion auf.
