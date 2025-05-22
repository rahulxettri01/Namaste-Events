import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../utils/shared_preferences.dart';

class NotificationApiService {
  final String token;
  final String baseUrl = 'http://192.168.1.87:2000';

  NotificationApiService({required this.token});

  Map<String, String> get _headers => {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };

  Future<List<NotificationModel>> fetchUserNotifications() async {
    final userDataString = SharedPreferencesService.getUserData();
    log('User data from SharedPreferencesService: $userDataString');
    
    if (userDataString == null || userDataString.isEmpty) {
      log('No user data found in shared preferences');
      return [];
    }
    
    try {
      final userData = json.decode(userDataString);
      final userId = userData['_id'] ?? userData['id'];
      final userEmail = userData['email'];
      
      log('Fetching notifications for user: ${userId ?? userEmail ?? "unknown"}');
      
      if (userId == null && userEmail == null) {
        log('No user identifier found in user data');
        return [];
      }
      
      final identifier = userId ?? userEmail;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/user/$identifier'),
        headers: _headers,
      );
      
      log('Response from fetchNotifications: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['notifications'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        log('Failed to load notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error fetching notifications: $e');
      return [];
    }
  }

  Future<List<NotificationModel>> fetchVendorNotifications() async {
    final userDataString = SharedPreferencesService.getUserData();
    log('Vendor data from SharedPreferencesService: $userDataString');
    
    if (userDataString == null || userDataString.isEmpty) {
      log('No vendor data found in shared preferences');
      return [];
    }
    
    try {
      final userData = json.decode(userDataString);
      final vendorId = userData['_id'] ?? userData['id'];
      final vendorEmail = userData['email'];
      
      log('Fetching notifications for vendor: ${vendorId ?? vendorEmail ?? "unknown"}');
      
      if (vendorId == null && vendorEmail == null) {
        log('No vendor identifier found in user data');
        return [];
      }
      
      final identifier = vendorId ?? vendorEmail;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/vendor/$identifier'),
        headers: _headers,
      );
      
      log('Response from fetchVendorNotifications: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['notifications'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        log('Failed to load vendor notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Error fetching vendor notifications: $e');
      return [];
    }
  }

  Future<int> fetchUnreadCount() async {
    final userDataString = SharedPreferencesService.getUserData();
    
    if (userDataString == null || userDataString.isEmpty) {
      log('No user data found in shared preferences');
      return 0;
    }
    
    try {
      final userData = json.decode(userDataString);
      final userId = userData['_id'] ?? userData['id'];
      final userEmail = userData['email'];
      
      if (userId == null && userEmail == null) {
        log('No user identifier found in user data');
        return 0;
      }
      
      final identifier = userId ?? userEmail;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread-count/$identifier'),
        headers: _headers,
      );
      
      log('Response from fetchUnreadCount: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      log('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/read/$notificationId'),
        headers: _headers,
      );
      
      log('Response from markAsRead: ${response.statusCode} - ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      log('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final userDataString = SharedPreferencesService.getUserData();
    
    if (userDataString == null || userDataString.isEmpty) {
      log('No user data found in shared preferences');
      return false;
    }
    
    try {
      final userData = json.decode(userDataString);
      final userId = userData['_id'] ?? userData['id'];
      final userEmail = userData['email'];
      
      if (userId == null && userEmail == null) {
        log('No user identifier found in user data');
        return false;
      }
      
      final identifier = userId ?? userEmail;
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/read-all/$identifier'),
        headers: _headers,
      );
      
      log('Response from markAllAsRead: ${response.statusCode} - ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      log('Error marking all notifications as read: $e');
      return false;
    }
  }
}