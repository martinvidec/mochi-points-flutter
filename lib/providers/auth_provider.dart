import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/family.dart';
import '../models/enums.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  Family? _currentFamily;
  List<User> _familyMembers = [];

  User? get currentUser => _currentUser;
  Family? get currentFamily => _currentFamily;
  List<User> get familyMembers => List.unmodifiable(_familyMembers);

  bool get isLoggedIn => _currentUser != null;
  bool get isParent => _currentUser?.isParent ?? false;
  bool get isChild => _currentUser?.isChild ?? false;

  List<User> get children =>
      _familyMembers.where((user) => user.isChild).toList();
  List<User> get parents =>
      _familyMembers.where((user) => user.isParent).toList();

  User? getUserById(String userId) =>
      _familyMembers.where((user) => user.id == userId).firstOrNull;

  static const String _familyKey = 'family';
  static const String _membersKey = 'family_members';
  static const String _lastUserIdKey = 'last_user_id';

  Future<void> initialize() async {
    try {
      // Load family
      _currentFamily = await StorageService.loadObject(
        _familyKey,
        Family.fromJson,
      );

      // Load family members
      _familyMembers = await StorageService.loadList(
        _membersKey,
        User.fromJson,
      );

      // Load last user
      final prefs = await SharedPreferences.getInstance();
      final lastUserId = prefs.getString(_lastUserIdKey);
      if (lastUserId != null) {
        _currentUser = _familyMembers
            .where((user) => user.id == lastUserId)
            .firstOrNull;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider.initialize error: $e');
    }
  }

  Future<bool> login(String userId, {String? pin}) async {
    try {
      final user = _familyMembers.where((u) => u.id == userId).firstOrNull;
      if (user == null) return false;

      // TODO: Verify PIN if provided

      _currentUser = user;

      // Save last user ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserIdKey, userId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider.login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;

    // Clear last user ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserIdKey);

    notifyListeners();
  }

  Future<bool> switchUser(String userId) async {
    return login(userId);
  }

  Future<bool> createFamily(String name) async {
    try {
      final family = Family(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
      );

      _currentFamily = family;
      _familyMembers = [];

      await StorageService.saveObject(_familyKey, family, (f) => f.toJson());
      await StorageService.saveList(_membersKey, _familyMembers, (u) => u.toJson());

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider.createFamily error: $e');
      return false;
    }
  }

  Future<bool> addMember(String name, UserRole role, {String? pin}) async {
    try {
      if (_currentFamily == null) return false;

      // Generate unique ID using timestamp + member count to avoid collisions
      final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${_familyMembers.length}';

      final user = User(
        id: uniqueId,
        familyId: _currentFamily!.id,
        name: name,
        email: '', // TODO: Add email support
        role: role,
        createdAt: DateTime.now(),
      );

      _familyMembers.add(user);

      await StorageService.saveList(_membersKey, _familyMembers, (u) => u.toJson());

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider.addMember error: $e');
      return false;
    }
  }
}
