import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/InventoryDetailsPage.dart';
import 'package:fyp_namaste_events/pages/ProfilePage.dart';
import 'package:fyp_namaste_events/pages/dashboardPhotography.dart';
import 'package:fyp_namaste_events/pages/furtherMore_page.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';
import 'package:fyp_namaste_events/providers/user_provider.dart';
import 'package:fyp_namaste_events/utils/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the SignUpPage widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesService.init();
  runApp(MyApp());
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
