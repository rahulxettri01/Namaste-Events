import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:fyp_namaste_events/pages/dashboardDecoration.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';

import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import 'dashboardPhotography.dart';
import 'dashboardVenue.dart';

class VerificationPage extends StatefulWidget {
  final String token;

  const VerificationPage({required this.token, super.key});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool isChecked = false;
  List<File> selectedFiles = [];
  List<String> selectedFileNames = [];
  late String userStatus;
  late String vendorType;

  @override
  void initState() {
    super.initState();

    // Decode JWT Token
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userStatus = jwtDecodedToken['status'];
    vendorType = jwtDecodedToken['category'];
    print(vendorType);
    // If user is verified, redirect to respective dashboard
    print(userStatus);
    if (userStatus == "verified") {
      if (vendorType == "Venue") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => VendorDashboard(token: widget.token)),
          );
        });
      } else if (vendorType == "Photography") {
        print(" photography redirectt");
        print(widget.token);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PhotographyDashboard(token: widget.token)),
          );
        });
      } else if (vendorType == "Decoration") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => DecorationDashboard(token: widget.token)),
          );
        });
      }
    }
  }

  // Function to pick multiple files
  Future<void> pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        selectedFiles = result.files.map((file) => File(file.path!)).toList();
        selectedFileNames = result.files.map((file) => file.name).toList();
      });
    }
  }

  // Function to upload multiple files
  Future<void> uploadFiles() async {
    if (selectedFiles.isNotEmpty) {
      try {
        String? token = await APIConstants.getToken();

        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unauthorized: Please log in again.")),
          );
          return;
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${APIConstants.baseUrl}vendor/vendorAuth/upload'),
        );

        for (var file in selectedFiles) {
          request.files
              .add(await http.MultipartFile.fromPath('files', file.path));
        }
        request.headers['Authorization'] = 'Bearer $token';

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          print('Files uploaded successfully: $responseBody');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Files uploaded successfully!")),
          );

          if (vendorType == "Venue") {
            // Redirect to Vendor Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => VendorDashboard(token: widget.token)),
            );
          } else if (vendorType == "Photography") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PhotographyDashboard(token: widget.token)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      DecorationDashboard(token: widget.token)),
            );
          }
        } else {
          print('Failed to upload files: ${response.reasonPhrase}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload files")),
          );
        }
      } catch (e) {
        print('Error uploading files: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred while uploading")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select files before uploading")),
      );
    }
  }

  // Sign-out function
  void _signOut() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Changed background image to furthermore.JPG
            Image.asset('assets/furthermore.JPG',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity),
            Positioned.fill(
                child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 5, sigmaY: 5), // Reduced blur intensity
              child: Container(color: Colors.black.withOpacity(0.3)),
            )),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Furthermore details",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '"Turning Plans into Perfect Moments!"',
                      style: TextStyle(fontSize: 14, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 30),

                    filePickerButton(), // File Picker Button
                    const SizedBox(height: 20),

                    // Checkbox for agreeing to Terms & Conditions
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: Colors.purple,
                          onChanged: (value) {
                            setState(() {
                              isChecked = value!;
                            });
                          },
                        ),
                        const Text("I agree with the "),
                        const Text(
                          "Terms of Service & Privacy Policy",
                          style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isChecked ? uploadFiles : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "For verification",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Navigate to Login Page
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Have an account? Log in",
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Sign-out button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Sign Out",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // File Picker UI
  Widget filePickerButton() {
    return GestureDetector(
      onTap: pickFiles,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Files",
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selectedFileNames
                  .map((fileName) => Text(fileName,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87)))
                  .toList(),
            ),
            const Icon(Icons.upload_file, color: Colors.purple),
          ],
        ),
      ),
    );
  }
}
