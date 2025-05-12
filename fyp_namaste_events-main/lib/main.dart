import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/AddInventory.dart';
import 'package:fyp_namaste_events/pages/AdminDahboardPage.dart';

import 'package:fyp_namaste_events/pages/SignUpPage.dart';
import 'package:fyp_namaste_events/pages/dashboardDecoration.dart';
import 'package:fyp_namaste_events/pages/home_page.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';
import 'package:fyp_namaste_events/pages/splashScreen.dart';
import 'package:fyp_namaste_events/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the SignUpPage widget
import 'package:khalti_flutter/khalti_flutter.dart';

void main() {
  runApp(
    KhaltiScope(
      publicKey:
          "f2031fc6ad264335a75309fa6d49f089", // Replace with your Khalti public key
      enabledDebugging: true,
      builder: (context, navigatorKey) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Flutter App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: LoginPage(), // Set SignUpPage as the first screen
          localizationsDelegates: const [
            KhaltiLocalizations.delegate,
          ],
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  final token;
  const MyApp({@required this.token, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(), // Set SignUpPage as the first screen
    );
  }
}
