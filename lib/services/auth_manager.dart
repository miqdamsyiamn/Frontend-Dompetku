import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager extends ChangeNotifier {

  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();


  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';


  String? _token;
  Map<String, dynamic>? _user;
  bool _isInitialized = false;


  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get isInitialized => _isInitialized;

  // User info
  String? get userId => _user?['id'];
  String? get userName => _user?['nama'];
  String? get userUsername => _user?['username'];
  String? get userFoto => _user?['foto'];
  String? get userRole => _user?['role'];
  bool get isAdmin => _user?['role'] == 'admin';


  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    // Load token
    _token = prefs.getString(_tokenKey);

    // Load user data
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _user = jsonDecode(userJson);
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Get token 
  Future<String?> getToken() async {
    if (!_isInitialized) await init();
    return _token;
  }

  /// Save token setelah login
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _token = token;
    notifyListeners();
  }

  /// Save user data setelah login
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    _user = user;
    notifyListeners();
  }

  /// Update user data 
  Future<void> updateUser(Map<String, dynamic> updatedFields) async {
    if (_user != null) {
      _user!.addAll(updatedFields);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_user));
      notifyListeners();
    }
  }

  /// Logout - hapus semua data auth
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _token = null;
    _user = null;
    notifyListeners();
  }

  /// Check apakah token masih valid
  bool hasValidToken() {
    return _token != null && _token!.isNotEmpty;
  }

  /// Clear all data 
  Future<void> clearAll() async {
    await logout();
  }
}
