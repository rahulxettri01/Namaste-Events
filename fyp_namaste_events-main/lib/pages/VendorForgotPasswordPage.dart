import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/services/Api/api_authentication.dart';
import 'package:fyp_namaste_events/pages/VendorForgotPasswordOTPPage.dart';
import 'package:fyp_namaste_events/utils/validator.dart';

class VendorForgotPasswordPage extends StatefulWidget {
  const VendorForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _VendorForgotPasswordPageState createState() => _VendorForgotPasswordPageState();
}

class _VendorForgotPasswordPageState extends State<VendorForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetOTP() async {
    // Validate email
    String? emailError = Validator.validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() {
        _errorMessage = emailError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check if vendor email exists
      final checkResult = await Api.checkVendorEmail({
        'email': _emailController.text,
      });
      
      print("Vendor email check result: $checkResult");
      
      if (checkResult['success'] == true && checkResult['exists'] == true) {
        // Email exists, initiate forgot password flow
        print("Email exists, sending OTP...");
        final forgotResult = await Api.forgotVendorPassword(_emailController.text);
        
        if (forgotResult != null && forgotResult['success'] == true) {
          // Navigate to OTP verification page
          if (!mounted) return;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorForgotPasswordOTPPage(
                email: _emailController.text,
                vendorId: forgotResult['vendorId'] ?? checkResult['vendorId'] ?? '',
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = forgotResult?['message'] ?? "Failed to send OTP. Please try again.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "No vendor account found with this email.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade800],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.store_rounded,
                        size: 80,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Vendor Password Reset",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enter your email address to receive a password reset code",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          hintText: "Enter your vendor email",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _errorMessage,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Send Reset Code",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Back to Login",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}