import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/storage_service.dart';

class MochiPointAccountProvider extends ChangeNotifier {
  double _balance = 0;

  MochiPointAccountProvider() {
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final data = await StorageService.loadData('balance');
    _balance = data['balance'] ?? 0;
    notifyListeners();
  }

  Future<void> _saveBalance() async {
    await StorageService.saveData('balance', {'balance': _balance});
  }

  double get balance => _balance;

  void addPoints(double points) {
    _balance += points;
    notifyListeners();
  }

  Future<bool> deductPoints(double amount) async {
    if (_balance >= amount) {
      _balance -= amount;
      await _saveBalance();
      notifyListeners();
      return true;
    }
    return false;
  }
}
