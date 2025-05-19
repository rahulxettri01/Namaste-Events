/*--- List of constants used in API--*/
import 'package:shared_preferences/shared_preferences.dart';

class APIConstants {
  static String baseUrl = "http://192.168.1.86"
      ":2000/";
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('FrontToken');
  }

  // Method to clear the token from shared preferences
  static Future<bool> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove('token');
  }
}
