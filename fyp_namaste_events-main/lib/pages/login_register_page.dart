import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/dashboardVenue.dart';
import 'package:fyp_namaste_events/pages/home_page.dart';
import 'package:fyp_namaste_events/pages/SignUpPage.dart';
import 'package:fyp_namaste_events/pages/furtherMore_page.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp_namaste_events/services/Api/api_authentication.dart';
import 'package:fyp_namaste_events/pages/AdminDahboardPage.dart';

import 'otp/VerifyOTPPage.dart';
import 'otp/ForgotPasswordOTPPage.dart';
import 'package:fyp_namaste_events/utils/validator.dart';
import 'package:fyp_namaste_events/pages/VendorForgotPasswordOTPPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  String? errorMessage = '';
  bool isPasswordVisible = false;
  String? selectedRole;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  void _login() async {
    setState(() {
      errorMessage = '';
    });

    // Validate all fields
    String? emailError = Validator.validateLoginEmail(_controllerEmail.text);
    String? passwordError =
        Validator.validateLoginPassword(_controllerPassword.text);

    if (emailError != null) {
      setState(() {
        errorMessage = emailError;
      });
      return;
    } else if (passwordError != null) {
      setState(() {
        errorMessage = passwordError;
      });
      return;
    } else if (selectedRole == null || selectedRole!.isEmpty) {
      setState(() {
        errorMessage = "Please select a role.";
      });
      return;
    }

    // If validation passes, proceed with login
    var data = {
      "email": _controllerEmail.text,
      "password": _controllerPassword.text,
      "role": selectedRole,
    };

    try {
      if (selectedRole == "Super Admin") {
        final response = await Api.loginAdmin(data);
        if (response != null) {
          int statusCode = response["status_code"];
          var newToken = response["token"];
          if (statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Login successful! Welcome."),
                backgroundColor: Colors.green,
              ),
            );

            prefs.setString("FrontToken", newToken);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AdminDashboardPage(token: newToken)),
            );
          } else {
            setState(() {
              errorMessage = response["message"] ?? "Login failed. Try again.";
            });
          }
        }
      } else {
        final response = await Api.login(data);
        if (response != null) {
          int statusCode = response["status_code"];

          if (statusCode == 401) {
            // Unauthorized - invalid credentials
            setState(() {
              errorMessage = "Invalid email or password";
            });
            return;
          }

          if (statusCode == 200) {
            String role = response["role"];
            var newToken = response["token"];

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Login successful! Welcome."),
                backgroundColor: Colors.green,
              ),
            );

            prefs.setString("FrontToken", newToken);
            if (role == "Vendor") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => VerificationPage(token: newToken)),
              );
            } else if (role == "Super Admin") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => AdminDashboardPage(token: newToken)),
              );
            } else {
              if (response["status"] == "unverified") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerifyOTPPage(
                      userId: response['userId'].toString(),
                      email: response['email'],
                    ),
                  ),
                );
              } else if (response["status"] == "verified") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomePage(
                            token: newToken,
                          )),
                );
              }
            }
          } else if (statusCode == 404) {
            setState(() {
              errorMessage = "User does not exist. Please sign up first.";
            });
          } else {
            setState(() {
              errorMessage = response["message"] ?? "Login failed. Try again.";
            });
          }
        } else {
          setState(() {
            errorMessage = "Invalid email or password";
          });
        }
      }
    } catch (error) {
      setState(() {
        errorMessage = "Error occurred: ${error.toString()}";
      });
    }
  }

  Widget _entryField(String title, TextEditingController controller,
      {bool isPassword = false}) {
    // Get field-specific error message
    String? getFieldError() {
      if (controller.text.isEmpty) return null;

      switch (title) {
        case "Email":
          return Validator.validateLoginEmail(controller.text);
        case "Password":
          return Validator.validateLoginPassword(controller.text);
        default:
          return null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          onChanged: (value) {
            // Trigger rebuild to show/hide error
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(
                color: getFieldError() != null ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(
                color: getFieldError() != null ? Colors.red : Colors.black,
              ),
            ),
            fillColor: Colors.white,
            filled: true,
            prefixIcon: Icon(
              isPassword ? Icons.lock : Icons.email,
              color: getFieldError() != null ? Colors.red : Colors.grey,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: getFieldError() != null ? Colors.red : null,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  )
                : null,
            errorText: getFieldError(),
          ),
        ),
      ],
    );
  }

  Widget _roleDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      decoration: InputDecoration(
        labelText: 'Select Role',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.black),
        ),
        fillColor: Colors.white,
        filled: true,
        prefixIcon: const Icon(
          Icons.person_outline,
          color: Colors.grey,
        ),
      ),
      items: ['User', 'Vendor', 'Super Admin'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedRole = newValue;
        });
      },
    );
  }

  Widget _registerText() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              child: const Text(
                "Join us",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        // Forgot Password button
        TextButton(
          onPressed: () {
            _showForgotPasswordDialog();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          ),
          child: const Text(
            "Forgot Password?",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Add forgot password dialog
  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;
    String? selectedResetRole;
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text("Reset Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter your email address and we'll send you a OTP to reset your password.",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.email),
                    errorText: errorText,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Add role dropdown
                DropdownButtonFormField<String>(
                  value: selectedResetRole,
                  decoration: InputDecoration(
                    labelText: 'Select Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  items: ['User', 'Vendor'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedResetRole = newValue;
                      errorText = null;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        // Validate inputs
                        if (emailController.text.isEmpty) {
                          setState(() {
                            errorText = "Please enter your email address";
                          });
                          return;
                        }

                        if (selectedResetRole == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a role"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Show loading indicator
                        setState(() {
                          isLoading = true;
                          errorText = null;
                        });

                        Map<String, String> emailData = {
                          "email": emailController.text,
                          "role": selectedResetRole!,
                        };

                        // In the _showForgotPasswordDialog method, update the response handling section:
                        try {
                          // Call different API methods based on role
                          var response;
                          if (selectedResetRole == "Vendor") {
                            // First check if vendor email exists
                            response = await Api.checkVendorEmail(emailData);
                            print("Vendor email check response: $response");

                            if (response["success"] == true &&
                                response["exists"] == true) {
                              // If email exists, send OTP
                              final forgotResult =
                                  await Api.forgotVendorPassword(
                                      emailController.text);
                              print(
                                  "Forgot vendor password response: $forgotResult");

                              if (forgotResult != null &&
                                  forgotResult["success"] == true) {
                                Navigator.of(context).pop();

                                // Navigate to vendor OTP page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VendorForgotPasswordOTPPage(
                                      email: emailController.text,
                                      vendorId: forgotResult["vendorId"] ??
                                          response["vendorId"] ??
                                          '',
                                    ),
                                  ),
                                );
                              } else {
                                setState(() {
                                  isLoading = false;
                                  errorText = forgotResult?["message"] ??
                                      "Failed to send OTP. Please try again.";
                                });
                              }
                            } else {
                              setState(() {
                                isLoading = false;
                                errorText = "Email not found or invalid";
                              });
                            }
                          } else {
                            // User password reset flow
                            response = await Api.checkValidEmail(emailData);

                            setState(() {
                              isLoading = false;
                            });

                            if (response["status"] == "success") {
                              Navigator.of(context).pop();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordOTPPage(
                                    email: response["email"],
                                    userId: response["userId"],
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                errorText = response["message"] ??
                                    "Email not found or invalid";
                              });
                            }
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                            errorText = "Error: ${e.toString()}";
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text(
                        "Send Reset OTP",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Image.asset(
            'assets/login.JPG',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.3))),
          Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '"Turning Plans into Perfect Moments!"',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _entryField("Email", _controllerEmail),
                        const SizedBox(height: 16),
                        _entryField("Password", _controllerPassword,
                            isPassword: true),
                        const SizedBox(height: 16),
                        _roleDropdown(),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                        if (errorMessage != null && errorMessage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _registerText(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
