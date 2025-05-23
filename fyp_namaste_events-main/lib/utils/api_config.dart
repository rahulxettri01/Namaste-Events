import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // When running on web, use the window location origin or a fixed address
      return 'http://192.168.1.87:2000/';
    } else {
      // For mobile devices
      return 'http://192.168.1.87:2000/';
    }
  }
  
  // Helper method to get full URL for an endpoint
  static String getUrl(String endpoint) {
    return baseUrl + endpoint;
  }
}