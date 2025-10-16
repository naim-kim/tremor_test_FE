import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _userName = '';
  String _userEmail = '';
  String _loginProvider = '';
  bool _isLoggedIn = false;

  String get userName => _userName;
  String get userEmail => _userEmail;
  String get loginProvider => _loginProvider;
  bool get isLoggedIn => _isLoggedIn;

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? '';
    _userEmail = prefs.getString('user_email') ?? '';
    _loginProvider = prefs.getString('login_provider') ?? '';
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    notifyListeners();
  }

  Future<void> setUser({
    required String name,
    required String email,
    required String loginProvider,
  }) async {
    _userName = name;
    _userEmail = email;
    _loginProvider = loginProvider;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('login_provider', loginProvider);
    await prefs.setBool('is_logged_in', true);

    notifyListeners();
  }

  Future<void> logout() async {
    _userName = '';
    _userEmail = '';
    _loginProvider = '';
    _isLoggedIn = false;

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
}
