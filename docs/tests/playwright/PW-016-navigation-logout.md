# PW-016: Bottom-Navigation & Logout

- **Prozess:** Cross-cutting (ergänzt P3, P5, P6, P8, P10)
- **Actor:** beide
- **Status:** draft

## Zielsetzung

Die Bottom-Navigation in beiden Dashboards (Parent & Child) wechselt
zwischen den Tabs ohne State-Verlust (da `IndexedStack` verwendet wird).
Logout landet zurück auf LoginPage. Wiedereinloggen mit anderer Rolle
lädt das passende Dashboard.

## Preconditions / Fixtures

- `familyWithChild` (Parent „Mama" und Child „Luca"), Parent eingeloggt

## Testfälle

### TC-016.1 — Parent-Navigation
```
Given: Parent-Dashboard
When:  Tabs „Home", „Quests", „Rewards", „Genehmigungen", „Profil" jeweils antippen
Then:  Jeweiliger Tab-Inhalt ist sichtbar
```
**Assertions:**
- Für jeden Tab ein Heading/Role-Selector (z. B. Liste auf Quest-Management)

### TC-016.2 — IndexedStack behält Scroll-Position
```
Given: Parent → Quests-Tab, Liste nach unten gescrollt
When:  Zu „Home" und zurück zu „Quests" wechseln
Then:  Scroll-Position der Quest-Liste ist erhalten
```

### TC-016.3 — Child-Navigation
```
Given: Child-Dashboard (5 Tabs: Home, Quests, My Rewards, Shop, Profil)
When:  Alle Tabs durchgeschaltet
Then:  Jeweiliger Inhalt sichtbar
```

### TC-016.4 — Logout leitet auf Login
```
Given: Parent-Dashboard → Profil-Tab
When:  „Logout" wird geklickt (mit ggf. Bestätigung)
Then:  LoginPage wird angezeigt
And:   `last_user_id` aus `localStorage` entfernt
```

### TC-016.5 — Wiedereinloggen mit Child zeigt Hero-Home
```
Given: TC-016.4 abgeschlossen
When:  Avatar „Luca" auf LoginPage antippen
Then:  Hero-Home wird angezeigt (nicht Parent-Dashboard)
```

### TC-016.6 — Browser-Refresh bleibt in aktueller Route
```
Given: Parent-Dashboard → Quests-Tab
When:  Browser-Refresh
Then:  Tab-Index wird ggf. zurückgesetzt (IndexedStack ist nicht URL-synchronisiert)
And:   Der User bleibt authentifiziert (kein Zwangs-Login)
```
> **Hinweis:** Der Tab-Index ist lokal und überlebt den Refresh nicht. Die
> Assertion beschränkt sich auf „User bleibt eingeloggt".

## Out of Scope

- Deep-Linking (nicht implementiert)
- Benachrichtigungen (→ PW-015)

## Offene Fragen

- Besitzt die Bottom-Nav `aria-label` o. ä.? Andernfalls muss der Test
  auf Text-basierte Locators ausweichen.
