import 'package:flutter/foundation.dart';
import '../models/eaty.dart';

class EatyProvider extends ChangeNotifier {
  final List<Eaty> _eaties = [];

  List<Eaty> get eaties => _eaties;

  void addEaty(Eaty eaty) {
    _eaties.add(eaty);
    notifyListeners();
  }

  void removeEaty(Eaty eaty) {
    _eaties.remove(eaty);
    notifyListeners();
  }

  // Additional methods for updating or deleting Eaties can be added here
}

