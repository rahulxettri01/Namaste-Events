/*--- List of constants used in API--*/
import 'package:shared_preferences/shared_preferences.dart';

class APIConstants {
  static String baseUrl = "http://192.168.1.127:2000/";
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('FrontToken');
  }
}
