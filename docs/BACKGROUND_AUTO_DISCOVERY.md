# Spec: Automatische Discovery von Hintergrundbildern

- **Status:** draft
- **Komponente:** `BackgroundService` · `pubspec.yaml` · `AppearanceSettingsPage`
- **Ziel-Release:** MVP-Polish

## 1. Kontext & Ziel

Der gewünschte Workflow zum Hinzufügen eines neuen Hintergrundbildes soll
so einfach sein wie:

1. Bilddatei in den Assets-Ordner legen
2. App neu bauen
3. Das neue Bild erscheint **automatisch** im Hintergrund-Picker

Kein manuelles Eintragen in Dart-Code, kein manuelles Eintragen in
`pubspec.yaml`. Ein einziger Ort (der Asset-Ordner) ist Source of Truth.

## 2. IST-Analyse

### 2.1 Aktueller Workflow (hart gekoppelt an zwei Listen)

Um ein neues Hintergrundbild zu ergänzen, müssen aktuell **drei** Orte
angefasst werden:

1. **Datei ablegen** in `./assets/meinBild.png`
2. **`pubspec.yaml`** — Eintrag unter `flutter.assets` hinzufügen:
   ```yaml
   flutter:
     assets:
       - assets/meinBild.png
   ```
3. **`lib/services/background_service.dart:16-26`** — Eintrag in die
   hartcodierte `_backgrounds`-Liste:
   ```dart
   static const List<String> _backgrounds = [
     'assets/rx451g_athlete_runner_mochis_competing_anime_style.png',
     …
     'assets/meinBild.png',   // ← manuell
   ];
   ```

Wird einer der Schritte vergessen, erscheint das Bild **nicht** im Picker
(Schritt 3 vergessen) oder crasht die App beim Anzeigen (Schritt 2
vergessen).

### 2.2 Evidenz des Problems im aktuellen Repository

Unter `./assets/` liegen **18 Dateien**:

| Typ | Anzahl | In `pubspec.yaml`? | In `_backgrounds`-Liste? |
|-----|--------|--------------------|--------------------------|
| Registrierte PNGs | 9 | ✅ | ✅ |
| **Nicht registrierte PNGs** | **7** | ❌ | ❌ |
| MP4-Videos | 2 | ❌ | ❌ |

Die 7 nicht registrierten PNGs (`A_bustling_cyberpunk_…`,
`A_mystical_forest_…`, `A_peaceful_hot_spring_…`,
`A_peaceful_traditional_Japanese_village_…`, `A_traditional_Japanese_dojo_…`,
`A_whimsical_anime_map-like_landscape_…`,
`An_empty_classroom_and_schoolyard_…`) wurden offenbar mit der Intention
hinzugefügt, sie als Hintergrund nutzen zu können — sie sind in der App
aber weder sichtbar noch anwählbar. Das ist die Reibung, die dieses
Issue adressiert.

### 2.3 Architektur-Stand (wie Hintergründe heute geladen werden)

```
pubspec.yaml                 BackgroundService (hartcodierte Liste)
      │                                │
      │ (Flutter bundelt                │ (Dart-Konstanten)
      │  Assets in die App)             │
      ▼                                 ▼
         AssetBundle enthält 9 PNGs
                         │
                         ▼
      GlassScaffold.Image.asset(service.currentBackground)
                         │
                         ▼
         SharedPreferences['selected_background']
```

- **`lib/services/background_service.dart`** — Singleton,
  hartcodierte `_backgrounds`-Liste von 9 Pfaden
- **`pubspec.yaml`** (Zeilen 69–78) — 9 Einzeldeklarationen
- **`lib/pages/appearance_settings_page.dart`** — GridView iteriert
  `BackgroundService.availableBackgrounds`
- **`lib/widgets/glass_scaffold.dart:37-41`** — zeigt
  `BackgroundService().currentBackground` via `Image.asset`
- **`main.dart:23`** — `await BackgroundService().init()` vor runApp

## 3. Lösungsansatz (SOLL)

Flutter bietet **zwei Bausteine**, mit denen die doppelte Liste
eliminiert wird:

1. **Verzeichnis-basierte Asset-Deklaration in `pubspec.yaml`**
   — ein Eintrag mit nachgestelltem `/` bundelt alle direkten
   Kinder des Verzeichnisses:
   ```yaml
   flutter:
     assets:
       - assets/backgrounds/
   ```

2. **`AssetManifest` zur Laufzeit-Enumeration**
   — Flutter liefert über `AssetManifest.loadFromAssetBundle(rootBundle)`
   eine Liste **aller** gebundelten Assets. Wir filtern auf unser
   Verzeichnis und erlaubte Endungen.

Damit bleibt die `pubspec.yaml` stabil, der Dart-Code enthält **keine**
Datei-Namen mehr, und das Hinzufügen eines Bildes reduziert sich auf:

1. Bild in `assets/backgrounds/` legen
2. `flutter pub get` (nur nötig, wenn neuer Subordner angelegt wird)
3. `flutter run` / `flutter build web …` — das Bild erscheint im Picker

> **Flutter-Einschränkung**: Neue Assets werden bei **Hot Reload
> nicht** neu eingelesen. Ein vollständiger Restart (`R` im
> `flutter run`-Terminal) oder Neu-Build ist erforderlich. Das ist eine
> Flutter-Plattform-Eigenschaft und nicht Teil dieser Spec.

## 4. Änderungen im Detail

### 4.1 Assets umstrukturieren

```
assets/
├── backgrounds/          ← NEU: nur Hintergrundbilder
│   ├── rx451g_athlete_runner_…png
│   ├── A_bustling_cyberpunk_city_…png
│   └── …
└── videos/               ← optional: MP4-Mochi-Animationen
    ├── rx451g_…_basketball_…mp4
    └── rx451g_…_soccer_…mp4
```

**Rationale**: klare Trennung nach Asset-Zweck. Verhindert, dass
z. B. Screenshots, Demo-Videos oder andere künftige Asset-Arten
versehentlich im Background-Picker landen.

### 4.2 `pubspec.yaml` anpassen

**Vorher** (Zeilen 69–78 — 9 Einzeldeklarationen, Diff bei jedem neuen
Bild):

```yaml
  assets:
    - assets/rx451g_athlete_runner_…png
    - assets/rx451g_olympic_athlete_…png
    - assets/rx451g_olympic_karate_…png
    - assets/rx451g_olympic_karate_…png_2.png
    - assets/rx451g_olympic_swimmer_…_2.png
    - assets/rx451g_olympic_swimmer_…_3.png
    - assets/rx451g_some_football_…png
    - assets/rx451g_some_soccer_…png
    - assets/rx451g_some_volleyball_…png
```

**Nachher** (ein Eintrag, kein Diff bei neuen Bildern):

```yaml
  assets:
    - assets/backgrounds/
```

### 4.3 `BackgroundService` umbauen

Die hartcodierte Liste entfällt komplett. `init()` enumeriert Assets
über `AssetManifest`:

```dart
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String _prefsKey = 'selected_background';
  static const String _prefix = 'assets/backgrounds/';
  static const _allowedExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

  List<String> _backgrounds = [];
  String? _currentBackground;

  String get currentBackground =>
      _currentBackground ?? (_backgrounds.isNotEmpty ? _backgrounds.first : '');
  List<String> get availableBackgrounds => List.unmodifiable(_backgrounds);

  Future<void> init() async {
    // 1. Bundled Assets enumerieren
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest.listAssets();

    // 2. Auf unseren Ordner + erlaubte Endungen filtern
    _backgrounds = all
        .where((p) => p.startsWith(_prefix))
        .where((p) => _allowedExtensions.any((e) => p.toLowerCase().endsWith(e)))
        .toList()
      ..sort(); // stabile alphabetische Reihenfolge

    // 3. Gespeicherte Auswahl wiederherstellen (falls existiert)
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && _backgrounds.contains(saved)) {
      _currentBackground = saved;
    } else if (_backgrounds.isNotEmpty) {
      _currentBackground = _backgrounds.first;
    }
  }

  Future<void> setBackground(String path) async {
    if (!_backgrounds.contains(path)) return;
    _currentBackground = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path);
  }
}
```

**Wichtig**: die Reihenfolge `init() → runApp()` in `main.dart` bleibt
bestehen — `AssetManifest.loadFromAssetBundle` braucht die
`WidgetsFlutterBinding`, die in `main()` ohnehin bereits vor `init()`
initialisiert wird.

### 4.4 `AppearanceSettingsPage` — keine Änderung nötig

Die Seite iteriert bereits `BackgroundService.availableBackgrounds` /
`_backgrounds`. Solange das Getter-API stabil bleibt, funktioniert der
Picker automatisch mit der dynamisch erzeugten Liste.

### 4.5 Tests

- **Unit-Test** (`test/services/background_service_test.dart`)
  — mocke `rootBundle.loadString('AssetManifest.json')`-Antwort,
  verifiziere dass `_backgrounds` korrekt gefiltert + sortiert wird.
- **Widget-Test** — `AppearanceSettingsPage` rendert N Thumbnails für N
  gebundelte Backgrounds.
- **E2E-Test (Playwright)** — optional; aktuell kein Coverage für
  AppearanceSettings, hat keine Priorität.

## 5. Migration

### 5.1 Assets-Umzug

Alle 16 PNGs aus `assets/*.png` nach `assets/backgrounds/` verschieben.
Die MP4-Files optional nach `assets/videos/` (oder beibehalten an der
Wurzel, wenn noch unklar). Screenshots unter
`docs/screenshots/` sind nicht betroffen.

### 5.2 SharedPreferences-Migration für bestehende User

Der Storage-Key `selected_background` enthält bei existierenden
Installationen den **alten** Pfad
(`assets/rx451g_athlete_runner_…png`). Nach dem Move zeigt dieser Pfad
auf kein bundleendes Asset mehr — `contains()`-Check im neuen `init()`
schlägt fehl, Service fällt auf `_backgrounds.first` zurück.

**Option A — No-op (empfohlen)**
Einfach: bei unbekanntem Pfad fällt die App auf das Default-Background
zurück. Der User sieht einmal einen anderen Hintergrund und kann ggf.
neu auswählen. Komplexität: minimal.

**Option B — Auto-Migration**
Bei gefundenem alten Pfad programmatisch `assets/` → `assets/backgrounds/`
ersetzen und — falls das neue Ziel in der Liste ist — speichern.
Mehraufwand: niedrig, aber User-Experience-Win. **Empfehlung**.

```dart
// In init() nach dem Laden des saved-Wertes:
if (saved != null && !_backgrounds.contains(saved) && saved.startsWith('assets/')) {
  final migrated = saved.replaceFirst('assets/', _prefix);
  if (_backgrounds.contains(migrated)) {
    _currentBackground = migrated;
    await prefs.setString(_prefsKey, migrated);
  }
}
```

### 5.3 Dokumentation

Neuen Abschnitt in `CLAUDE.md` unter „Assets" ergänzen:

> **Neue Hintergrundbilder ergänzen:** Datei in `assets/backgrounds/`
> ablegen (erlaubte Endungen: .png, .jpg, .jpeg, .webp). Kein Eintrag
> in `pubspec.yaml` oder `BackgroundService` nötig — die Datei erscheint
> automatisch im Picker (Erscheinungsbild → Hintergrund) nach einem
> Full-Restart oder Neu-Build.

## 6. Risiken & Edge Cases

| # | Fall | Verhalten |
|---|------|-----------|
| R1 | `assets/backgrounds/` ist leer | `_backgrounds` leer → `currentBackground` gibt `''` → `Image.asset('')` wirft zur Laufzeit. **Mitigation**: Mindestens 1 Default-Background muss immer enthalten sein; zusätzlich im `init()` prüfen und ggf. auf einen eingebetteten Fallback (Farbe / Gradient) umschalten, wenn leer. |
| R2 | User fügt Datei mit unbekannter Endung (.heic, .gif) ein | Wird vom Filter ignoriert, erscheint **nicht** im Picker. Gewollt. |
| R3 | Asset-Name enthält Sonderzeichen | Flutter liefert die URL-Kodierung im `AssetManifest` — `Image.asset` kann das lesen, funktioniert transparent. |
| R4 | Hot-Reload zeigt neue Bilder nicht | Flutter-Plattform-Limit. `R` für Full-Restart oder Neu-Build erforderlich. **In CLAUDE.md dokumentieren**. |
| R5 | Performance: viele große PNGs werden alle gebundelt | App-Größe steigt proportional. Keine Regression gegenüber IST. Empfehlung: Bilder vor Commit optimieren (TinyPNG o. ä.). Nicht Teil dieser Spec. |
| R6 | Listen-Reihenfolge nicht stabil | `AssetManifest.listAssets()` ist per se nicht sortiert. Lösung: `..sort()` nach dem Filter. |

## 7. Akzeptanzkriterien

- [ ] Eine neue Datei in `assets/backgrounds/` erscheint ohne Code- oder
      `pubspec.yaml`-Änderung im Hintergrund-Picker (nach Full-Restart).
- [ ] Alle 16 vorhandenen PNGs sind nach der Migration sichtbar und
      auswählbar.
- [ ] `BackgroundService` enthält **keine** hartcodierten Datei-Namen
      mehr.
- [ ] `pubspec.yaml` enthält nur einen Eintrag pro Asset-Kategorie
      (Verzeichnis statt Einzeldatei).
- [ ] Bestehende User-Selection bleibt erhalten (Auto-Migration, Option B)
      oder fällt sauber auf Default zurück (Option A).
- [ ] CLAUDE.md dokumentiert den neuen Workflow.
- [ ] `flutter analyze` bleibt sauber.

## 8. Out of Scope

- MP4-Video-Hintergründe — separate Design-Entscheidung, eigenes Ticket
- Per-User-Backgrounds (derzeit app-weit persistiert, ein Background
  für alle Familienmitglieder)
- Background-Thumbnail-Preload / Caching-Strategien jenseits der
  bestehenden Flutter-Defaults
- Bildoptimierung / WebP-Conversion — separate Maßnahme
