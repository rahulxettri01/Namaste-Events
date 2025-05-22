import 'dart:convert';
import 'package:flutter/material.dart';


import 'package:fyp_namaste_events/pages/home_page.dart'; // Import home page
import 'package:fyp_namaste_events/pages/login_register_page.dart';

import 'package:fyp_namaste_events/utils/shared_preferences.dart';

import 'package:jwt_decoder/jwt_decoder.dart'; // Add this package for token validation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namaste Events',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isLoading = true;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Get token from SharedPreferences
    final token = SharedPreferencesService.getToken();
    
    if (token != null && token.isNotEmpty) {
      try {
        // Decode token to get payload
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        debugPrint('Decoded token: ${decodedToken.toString()}');
        
        // Check if exp claim exists
        if (decodedToken.containsKey('exp')) {
          // Get expiration timestamp (in seconds since epoch)
          int expirationTimestamp = decodedToken['exp'];
          
          // Convert to DateTime
          DateTime expirationDate = DateTime.fromMillisecondsSinceEpoch(expirationTimestamp * 1000);
          
          // Print expiration time for debugging
          debugPrint('Token expires at: $expirationDate');
        } else {
          debugPrint('Token does not have an expiration date');
        }
        
        // Check for logout flag
        bool wasLoggedOut = SharedPreferencesService.getWasLoggedOut() ?? false;
        
        if (wasLoggedOut) {
          // User logged out, clear the flag and go to login page
          await SharedPreferencesService.setWasLoggedOut(false);
          _nextScreen = const LoginPage();
          return;
        }
        
        // Instead of using JwtDecoder.isExpired which causes errors,
        // manually check expiration if it exists, otherwise consider token valid
        bool isTokenExpired = false;
        if (decodedToken.containsKey('exp') && decodedToken['exp'] != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          isTokenExpired = decodedToken['exp'] < now;
        }
        
        if (!isTokenExpired) {
          // Token is valid, get user data
          final userDataString = SharedPreferencesService.getUserData();
          
          if (userDataString != null && userDataString.isNotEmpty) {
            try {
              final userData = json.decode(userDataString);
              final role = userData['role'];
              
              // Only proceed if user is a regular user (not vendor or admin)
              if (role != 'vendor' && role != 'Vendor' && role != 'Super Admin') {
                _nextScreen = HomePage(token: token);
              } else {
                // Not a regular user, go to login
                _nextScreen = const LoginPage();
              }
            } catch (e) {
              debugPrint('Error parsing user data: $e');
              _nextScreen = const LoginPage();
            }
          } else {
            _nextScreen = const LoginPage();
          }
        } else {
          // Token is expired
          debugPrint('Token is expired');
          await SharedPreferencesService.clearAll(); // Clear all stored data
          _nextScreen = const LoginPage();
        }
      } catch (e) {
        // Error decoding token
        debugPrint('Error decoding token: $e');
        await SharedPreferencesService.clearAll();
        _nextScreen = const LoginPage();
      }
    } else {
      // No token found
      _nextScreen = const LoginPage();
    }
    
    // Update state and navigate
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    } else {
      return _nextScreen ?? const LoginPage();
    }
  }
}