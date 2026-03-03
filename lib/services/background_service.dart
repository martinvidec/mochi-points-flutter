import 'dart:math';

/// Service that provides a random background image for the session.
///
/// The selected image persists for the app session (singleton pattern).
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal() {
    _selectRandomBackground();
  }

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
  static List<String> get availableBackgrounds => _backgrounds;

  void _selectRandomBackground() {
    final random = Random();
    _currentBackground = _backgrounds[random.nextInt(_backgrounds.length)];
  }

  /// Select a new random background (e.g. on pull-to-refresh or manual trigger).
  void shuffle() {
    _selectRandomBackground();
  }
}
