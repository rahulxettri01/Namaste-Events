import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> setToken(String token) async {
    await _prefs?.setString('FrontToken', token);
  }

  static String? getToken() {
    return _prefs?.getString('FrontToken');
  }

  // User data management
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    await _prefs?.setString('userData', json.encode(userData));
  }

  static String? getUserData() {
    return _prefs?.getString('userData');
  }

  static Map<String, dynamic>? getUserDataMap() {
    final userDataString = _prefs?.getString('userData');
    if (userDataString == null || userDataString.isEmpty) {
      return null;
    }
    
    try {
      return json.decode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  static String? getUserId() {
    final userData = getUserDataMap();
    return userData?['userId'] ?? userData?['_id'] ?? userData?['id'];
  }

  static String? getUserRole() {
    final userData = getUserDataMap();
    return userData?['role'];
  }

  static String? getUserEmail() {
    final userData = getUserDataMap();
    return userData?['email'];
  }

  // Clear all data (for logout)
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Add these methods to your SharedPreferencesService class

  // Store the last password reset time
  // Add this method if it doesn't exist
  static Future<void> setLastPasswordResetTime(DateTime time) async {
    await _prefs?.setString('last_password_reset_time', time.toIso8601String());
  }
  
  // Add this method if it doesn't exist
  static String? getLastPasswordResetTime() {
    return _prefs?.getString('last_password_reset_time');
  }

  // Store the last password change time
  static Future<void> setLastPasswordChangeTime(DateTime changeTime) async {
    await _prefs?.setString('last_password_change_time', changeTime.toIso8601String());
  }

  // Get the last password change time
  static String? getLastPasswordChangeTime() {
    return _prefs?.getString('last_password_change_time');
  }

  // Logout flag management
  static Future<void> setWasLoggedOut(bool value) async {
    await _prefs?.setBool('was_logged_out', value);
  }

  static bool? getWasLoggedOut() {
    return _prefs?.getBool('was_logged_out');
  }

  // Store the last login time
  static Future<void> setLastLoginTime(DateTime loginTime) async {
    await _prefs?.setString('last_login_time', loginTime.toIso8601String());
  }

  // Get the last login time
  static String? getLastLoginTime() {
    return _prefs?.getString('last_login_time');
  }

  // Add these methods to store notification history
  static Future<void> saveNotificationHistory(Map<String, dynamic> notification) async {
    final notificationsList = getNotificationHistory() ?? [];
    notificationsList.add(notification);
    await _prefs?.setString('notification_history', json.encode(notificationsList));
  }

  static List<Map<String, dynamic>>? getNotificationHistory() {
    final historyString = _prefs?.getString('notification_history');
    if (historyString == null || historyString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = json.decode(historyString);
      return decoded.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error parsing notification history: $e');
      return [];
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    final notificationsList = getNotificationHistory() ?? [];
    for (var notification in notificationsList) {
      if (notification['id'] == notificationId) {
        notification['isRead'] = true;
        break;
      }
    }
    await _prefs?.setString('notification_history', json.encode(notificationsList));
  }

  static Future<void> markAllNotificationsAsRead() async {
    final notificationsList = getNotificationHistory() ?? [];
    for (var notification in notificationsList) {
      notification['isRead'] = true;
    }
    await _prefs?.setString('notification_history', json.encode(notificationsList));
  }
}
