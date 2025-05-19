import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> setToken(String token) async {
    await _prefs?.setString('token', token);
  }

  static String? getToken() {
    return _prefs?.getString('token');
  }

  static Future<void> removeToken() async {
    await _prefs?.remove('token');
  }

  // User data management
  static Future<void> setUserData(String userData) async {
    await _prefs?.setString('userData', userData);
  }

  static String? getUserData() {
    return _prefs?.getString('userData');
  }

  static Future<void> removeUserData() async {
    await _prefs?.remove('userData');
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
