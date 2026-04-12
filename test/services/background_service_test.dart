import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal [AssetManifest] double for tests — we only need [listAssets].
/// [getAssetVariants] is not used by [BackgroundService] and therefore
/// unimplemented.
class _FakeAssetManifest implements AssetManifest {
  _FakeAssetManifest(this._assets);

  final List<String> _assets;

  @override
  List<String> listAssets() => List.of(_assets);

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundService', () {
    setUp(() {
      // Reset persisted selection between tests so each starts from scratch.
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('discovers png/jpg/jpeg/webp files under assets/backgrounds/', () async {
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/sunset.png',
        'assets/backgrounds/forest.jpg',
        'assets/backgrounds/river.jpeg',
        'assets/backgrounds/city.webp',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      expect(service.availableBackgrounds, [
        'assets/backgrounds/city.webp',
        'assets/backgrounds/forest.jpg',
        'assets/backgrounds/river.jpeg',
        'assets/backgrounds/sunset.png',
      ]);
    });

    test('ignores files outside assets/backgrounds/', () async {
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/keep.png',
        'assets/other_folder/skip.png',
        'assets/root_level.png',
        'some/other/path.png',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      expect(service.availableBackgrounds, ['assets/backgrounds/keep.png']);
    });

    test('ignores files with unsupported extensions', () async {
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/keep.png',
        'assets/backgrounds/video.mp4',
        'assets/backgrounds/anim.gif',
        'assets/backgrounds/photo.heic',
        'assets/backgrounds/readme.txt',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      expect(service.availableBackgrounds, ['assets/backgrounds/keep.png']);
    });

    test('sorts backgrounds alphabetically for stable ordering', () async {
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/zulu.png',
        'assets/backgrounds/alpha.png',
        'assets/backgrounds/mike.png',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      expect(service.availableBackgrounds, [
        'assets/backgrounds/alpha.png',
        'assets/backgrounds/mike.png',
        'assets/backgrounds/zulu.png',
      ]);
    });

    test('defaults currentBackground to the first asset on fresh install', () async {
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/b.png',
        'assets/backgrounds/a.png',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      expect(service.currentBackground, 'assets/backgrounds/a.png');
    });

    test('restores a previously saved selection', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_background': 'assets/backgrounds/chosen.png',
      });
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/chosen.png',
        'assets/backgrounds/other.png',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      expect(service.currentBackground, 'assets/backgrounds/chosen.png');
    });

    test('migrates a pre-auto-discovery saved path to assets/backgrounds/',
        () async {
      // Pre-spec behaviour: paths were stored as `assets/<file>`.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_background': 'assets/legacy.png',
      });
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/legacy.png',
        'assets/backgrounds/other.png',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      // Current selection migrated to new path.
      expect(service.currentBackground, 'assets/backgrounds/legacy.png');
      // And persisted so subsequent runs skip the migration branch.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_background'),
          'assets/backgrounds/legacy.png');
    });

    test('falls back to first asset when saved path no longer exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_background': 'assets/backgrounds/deleted.png',
      });
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/available.png',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      expect(service.currentBackground, 'assets/backgrounds/available.png');
    });

    test('setBackground persists a valid selection', () async {
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/one.png',
        'assets/backgrounds/two.png',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);
      await service.setBackground('assets/backgrounds/two.png');

      expect(service.currentBackground, 'assets/backgrounds/two.png');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('selected_background'),
        'assets/backgrounds/two.png',
      );
    });

    test('setBackground ignores paths that are not in the manifest', () async {
      final manifest = _FakeAssetManifest([
        'assets/backgrounds/one.png',
      ]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);
      await service.setBackground('assets/backgrounds/not_there.png');

      expect(service.currentBackground, 'assets/backgrounds/one.png');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_background'), isNull);
    });

    test('currentBackground returns empty string when no assets available',
        () async {
      final manifest = _FakeAssetManifest([]);

      final service = BackgroundService();
      await service.init(manifestOverride: manifest);

      expect(service.availableBackgrounds, isEmpty);
      expect(service.currentBackground, '');
    });
  });
}
