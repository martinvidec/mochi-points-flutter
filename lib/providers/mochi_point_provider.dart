import 'package:flutter/foundation.dart';
import '../models/mochi_point.dart';

class MochiPointProvider extends ChangeNotifier {
  final List<MochiPoint> _mochiPoints = [];

  List<MochiPoint> get mochiPoints => _mochiPoints;

  void addMochiPoint(MochiPoint mochiPoint) {
    _mochiPoints.add(mochiPoint);
    notifyListeners();
  }

  // Weitere Methoden wie updateMochiPoint, deleteMochiPoint, etc. können hier hinzugefügt werden
}
