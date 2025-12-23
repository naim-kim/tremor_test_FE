import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class UserProvider extends ChangeNotifier {
  String _userName = '';
  String _userEmail = '';
  String _loginProvider = '';
  bool _isLoggedIn = false;
  int? _userId;
  double? _pixelsPerMm;

  String get userName => _userName;
  String get userEmail => _userEmail;
  String get loginProvider => _loginProvider;
  bool get isLoggedIn => _isLoggedIn;
  int? get userId => _userId;
  String get userIdString => _userId?.toString() ?? '';
  double? get pixelsPerMm => _pixelsPerMm;

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? '';
    _userEmail = prefs.getString('user_email') ?? '';
    _loginProvider = prefs.getString('login_provider') ?? '';
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _userId = prefs.getInt('user_id');
    _pixelsPerMm = prefs.getDouble('pixels_per_mm');
    notifyListeners();
  }

  Future<void> setUser({
    required String name,
    required String email,
    required String loginProvider,
    int? userId,
  }) async {
    _userName = name;
    _userEmail = email;
    _loginProvider = loginProvider;
    _isLoggedIn = true;
    _userId = userId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('login_provider', loginProvider);
    await prefs.setBool('is_logged_in', true);
    if (userId != null) {
      await prefs.setInt('user_id', userId);
    }

    notifyListeners();
  }

  Future<void> loginAndSync({
    required String name,
    required String email,
    required String loginProvider,
    required ApiClient apiClient,
  }) async {
    final created = await apiClient.createUser(
      name: name,
      email: email,
      loginProvider: loginProvider,
    );
    final backendId = (created['id'] as num?)?.toInt();
    if (backendId == null) {
      throw Exception('Backend did not return user id');
    }
    await setUser(
      name: name,
      email: email,
      loginProvider: loginProvider,
      userId: backendId,
    );
  }

  Future<void> logout() async {
    _userName = '';
    _userEmail = '';
    _loginProvider = '';
    _isLoggedIn = false;
    _userId = null;
    _pixelsPerMm = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    notifyListeners();
  }

  Future<void> setPixelsPerMm(double value) async {
    _pixelsPerMm = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pixels_per_mm', value);
    notifyListeners();
  }
}
