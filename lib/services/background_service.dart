import 'package:shared_preferences/shared_preferences.dart';

/// Service that provides a persistent background image selection.
///
/// Defaults to the first background. The user's choice is saved to
/// SharedPreferences and restored on next app start.
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal() {
    _currentBackground = _backgrounds[0];
  }

  static const String _prefsKey = 'selected_background';

  static const List<String> _backgrounds = [
    'assets/rx451g_athlete_runner_mochis_competing_anime_style.png',
    'assets/rx451g_olympic_athlete_mochis_posing_anime_style.png',
    'assets/rx451g_olympic_karate_mochis_competing_anime_style.png',
    'assets/rx451g_olympic_karate_mochis_competing_anime_style_2.png',
    'assets/rx451g_olympic_swimmer_mochis_competing_anime_style_2.png',
    'assets/rx451g_olympic_swimmer_mochis_competing_anime_style_3.png',
    'assets/rx451g_some_football_gaming_character_resembling_a_mochi_2.png',
    'assets/rx451g_some_soccer_gaming_character_resembling_a_mochi_2.png',
    'assets/rx451g_some_volleyball_gaming_character_resembling_a_mochi_0.png',
  ];

  late String _currentBackground;

  /// The currently selected background image asset path.
  String get currentBackground => _currentBackground;

  /// All available background image paths.
  static List<String> get availableBackgrounds =>
      List.unmodifiable(_backgrounds);

  /// Load saved background preference from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && _backgrounds.contains(saved)) {
      _currentBackground = saved;
    }
  }

  /// Set and persist a new background.
  Future<void> setBackground(String path) async {
    if (!_backgrounds.contains(path)) return;
    _currentBackground = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path);
  }
}
