import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/shared_preferences.dart';
import '../components/bottom_nav_bar.dart'; // Add this import

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late NotificationApiService _apiService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasLoginNotification = false;
  DateTime? _loginTime;
  String _token = '';
  
  // Add these flags for password notifications
  bool _hasPasswordResetNotification = false;
  bool _hasPasswordChangeNotification = false;
  DateTime? _passwordResetTime;
  DateTime? _passwordChangeTime;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    _loadNotificationHistory(); // Add this line to load notification history
  }

  Future<void> _initializeApiService() async {
    // Get token and log it for debugging
    _token = SharedPreferencesService.getToken() ?? '';
    log('Token from SharedPreferencesService: $_token');
    
    // Get user data and log it for debugging
    final userData = SharedPreferencesService.getUserData();
    log('User data from SharedPreferencesService: $userData');
    
    _apiService = NotificationApiService(token: _token);
    await _fetchNotifications();
    
    // Check if we should add a login notification
    final lastLoginTime = SharedPreferencesService.getLastLoginTime();
    if (lastLoginTime != null) {
      setState(() {
        _hasLoginNotification = true;
        _loginTime = DateTime.parse(lastLoginTime);
      });
    } else {
      // If no login time is stored, use current time
      setState(() {
        _hasLoginNotification = true;
        _loginTime = DateTime.now();
      });
    }
    
    // Check for password reset notification
    final lastPasswordResetTime = SharedPreferencesService.getLastPasswordResetTime();
    if (lastPasswordResetTime != null) {
      final resetTime = DateTime.parse(lastPasswordResetTime);
      // Only show notification if reset happened in the last 24 hours
      if (DateTime.now().difference(resetTime).inHours < 24) {
        setState(() {
          _hasPasswordResetNotification = true;
          _passwordResetTime = resetTime;
        });
      }
    }
    
    // Check for password change notification
    final lastPasswordChangeTime = SharedPreferencesService.getLastPasswordChangeTime();
    if (lastPasswordChangeTime != null) {
      final changeTime = DateTime.parse(lastPasswordChangeTime);
      // Only show notification if change happened in the last 24 hours
      if (DateTime.now().difference(changeTime).inHours < 24) {
        setState(() {
          _hasPasswordChangeNotification = true;
          _passwordChangeTime = changeTime;
        });
      }
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      // Get user data to determine role
      final userDataString = SharedPreferencesService.getUserData();
      bool isVendor = false;
      String? userName;
      String? userId;
      
      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          final userData = json.decode(userDataString);
          isVendor = userData['role'] == 'vendor';
          userName = userData['userName'] ?? 'User';
          userId = userData['id']; // Get user ID for logging
          log('Fetching notifications for user: $userId');
        } catch (e) {
          // Handle JSON parsing error
          log('Error parsing user data: $e');
        }
      }
      
      // Attempt to fetch notifications
      try {
        if (isVendor) {
          _notifications = await _apiService.fetchVendorNotifications();
        } else {
          _notifications = await _apiService.fetchUserNotifications();
        }
        
        // Log the response for debugging
        log('Notifications fetched: ${_notifications.length}');
        
        // Always add a login notification
        setState(() {
          _isLoading = false;
          _hasLoginNotification = true;
          _loginTime = DateTime.now(); // Use current time for demo
        });
      } catch (e) {
        log('Error fetching notifications: $e');
        // Even if notification fetch fails, still show login notification
        setState(() {
          _isLoading = false;
          _hasLoginNotification = true;
          _loginTime = DateTime.now();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
        // Still try to show login notification
        _hasLoginNotification = true;
        _loginTime = DateTime.now();
      });
    }
  }

  // Add this property to the _NotificationPageState class
  List<Map<String, dynamic>> _notificationHistory = [];



  void _loadNotificationHistory() {
    _notificationHistory = SharedPreferencesService.getNotificationHistory() ?? [];
    setState(() {});
  }

  // Modify the _markAsRead method
  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      final success = await _apiService.markAsRead(notification.id);
      if (success) {
        setState(() {
          notification.isRead = true;
        });
        // Also mark as read in history
        await SharedPreferencesService.markNotificationAsRead(notification.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notification as read: $e')),
      );
    }
  }

  // Modify the _markAllAsRead method
  Future<void> _markAllAsRead() async {
    try {
      final success = await _apiService.markAllAsRead();
      if (success) {
        setState(() {
          for (var notification in _notifications) {
            notification.isRead = true;
          }
          _hasLoginNotification = false;
          _hasPasswordResetNotification = false;
          _hasPasswordChangeNotification = false;
        });
        // Mark all as read in history
        await SharedPreferencesService.markAllNotificationsAsRead();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      // Error handling remains the same
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'), // Changed from Notifications to Messages
        actions: [
          if (_notifications.isNotEmpty || _hasLoginNotification || 
              _hasPasswordResetNotification || _hasPasswordChangeNotification)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError && !_hasLoginNotification
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load messages'), // Changed from notifications to messages
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _hasError = false;
                            _errorMessage = null;
                          });
                          _fetchNotifications();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty && !_hasLoginNotification
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey), // Changed icon
                          SizedBox(height: 16),
                          Text('No messages yet'), // Changed text
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _fetchNotifications();
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          // Login notification at the top if available
                          if (_hasLoginNotification)
                            _buildLoginNotification(),
                            
                          // Password reset notification
                          if (_hasPasswordResetNotification)
                            _buildPasswordResetNotification(),
                            
                          // Password change notification
                          if (_hasPasswordChangeNotification)
                            _buildPasswordChangeNotification(),
                            
                          // Regular notifications
                          ..._notifications.map((notification) => _buildNotificationCard(notification)).toList(),

                          
                          // History notifications
                          if (_notificationHistory.isNotEmpty) ...[
                            const Divider(thickness: 1),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Previous Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            ..._notificationHistory.map((notification) => _buildHistoryNotificationCard(notification)).toList(),
                          ],
                          
                          // If we only have system notifications, add some space at the bottom
                          if (_notifications.isEmpty && 
                              (_hasLoginNotification || _hasPasswordResetNotification || _hasPasswordChangeNotification))
                            const SizedBox(height: 100),
                        ],
                      ),
                    ),
      bottomNavigationBar: BottomNavBar(token: _token), // Add the bottom navigation bar
    );
  }

  Widget _buildLoginNotification() {
    final formattedTime = _loginTime != null 
        ? DateFormat('MMM d, yyyy h:mm a').format(_loginTime!) 
        : 'Recently';
        
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.login, color: Colors.blue),
        ),
        title: const Text(
          'Login Successful',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('You logged in successfully at $formattedTime'),
            const SizedBox(height: 4),
            Text(
              'New',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: () {
            setState(() {
              _hasLoginNotification = false;
            });
          },
          tooltip: 'Mark as read',
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification);
          }
          // Handle notification tap based on type
          // You can navigate to different screens based on notification type
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getNotificationIcon(notification.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.body,
                style: TextStyle(
                  color: notification.isRead ? Colors.grey[600] : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'booking':
        iconData = Icons.calendar_today;
        iconColor = Colors.green;
        break;
      case 'payment':
        iconData = Icons.payment;
        iconColor = Colors.blue;
        break;
      case 'vendor':
        iconData = Icons.store;
        iconColor = Colors.purple;
        break;
      case 'system':
        iconData = Icons.info;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  // Add new methods for password reset and change notifications
  Widget _buildPasswordResetNotification() {
    final formattedTime = _passwordResetTime != null 
        ? DateFormat('MMM d, yyyy h:mm a').format(_passwordResetTime!) 
        : 'Recently';
        
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.orange.shade100,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset, color: Colors.orange),
        ),
        title: const Text(
          'Password Reset',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Your password was reset at $formattedTime'),
            const SizedBox(height: 4),
            Text(
              'Security Alert',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: () {
            setState(() {
              _hasPasswordResetNotification = false;
            });
          },
          tooltip: 'Mark as read',
        ),
      ),
    );
  }

  // Make sure you have this method in your notification_page.dart file
  
  Widget _buildPasswordChangeNotification() {
    final formattedTime = _passwordChangeTime != null 
        ? DateFormat('MMM d, yyyy h:mm a').format(_passwordChangeTime!) 
        : 'Recently';
        
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.green.shade100,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.password, color: Colors.green),
        ),
        title: const Text(
          'Password Changed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Your password was changed successfully at $formattedTime'),
            const SizedBox(height: 4),
            Text(
              'Security Update',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: () {
            setState(() {
              _hasPasswordChangeNotification = false;
            });
          },
          tooltip: 'Mark as read',
        ),
      ),
    );
  }
  
  // Add this method to build history notification cards
  Widget _buildHistoryNotificationCard(Map<String, dynamic> notification) {
    final DateTime createdAt = DateTime.parse(notification['createdAt']);
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(createdAt);
    
    IconData iconData;
    Color iconColor;
    
    switch (notification['type']) {
      case 'security':
        iconData = Icons.security;
        iconColor = Colors.green;
        break;
      case 'login':
        iconData = Icons.login;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: notification['isRead'] ? Colors.grey.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification['title'],
                    style: TextStyle(
                      fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (!notification['isRead'])
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification['body'],
              style: TextStyle(
                color: notification['isRead'] ? Colors.grey[600] : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}