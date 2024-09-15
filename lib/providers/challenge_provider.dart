import 'package:flutter/foundation.dart';
import '../models/challenge.dart';

class ChallengeProvider extends ChangeNotifier {
  List<Challenge> _challenges = [];

  List<Challenge> get challenges => _challenges;

  void addChallenge(Challenge challenge) {
    _challenges.add(challenge);
    notifyListeners();
  }

  void updateChallenge(Challenge challenge) {
    final index = _challenges.indexWhere((c) => c.id == challenge.id);
    if (index != -1) {
      _challenges[index] = challenge;
      notifyListeners();
    }
  }

  void deleteChallenge(String id) {
    _challenges.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
