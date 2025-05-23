import 'dart:async';
import 'dart:developer'; // Add this import for log function
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';

import 'package:fyp_namaste_events/services/Api/api_authentication.dart';
import 'package:fyp_namaste_events/utils/shared_preferences.dart';

class ForgotPasswordOTPPage extends StatefulWidget {
  final String userId;
  final String email;

  const ForgotPasswordOTPPage({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  _ForgotPasswordOTPPageState createState() => _ForgotPasswordOTPPageState();
}

class _ForgotPasswordOTPPageState extends State<ForgotPasswordOTPPage>
    with SingleTickerProviderStateMixin {
  // Using 6 separate controllers for each digit
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _canResend = false;
  int _countDown = 120; // 2 minutes cooldown
  Timer? _timer;
  bool _otpVerified = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Animation controller
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _canResend = false;
      _countDown = 120;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countDown > 0) {
          _countDown--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  String _getCompleteOTP() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    final otp = _getCompleteOTP();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Api.verifyOTP(
        widget.userId,
        otp,
      );

      if (response != null && response['success'] == true) {
        // Reset animation before showing new form
        _animationController.reset();

        setState(() {
          _otpVerified = true;
          _isLoading = false;
        });

        // Start animation for password reset form
        _animationController.forward();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('OTP verified successfully! Please set a new password.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Api.resetPassword(
        widget.userId,
        _newPasswordController.text,
      );

      if (response != null && response["status_code"] == 200) {
        // Save the password reset time
        final now = DateTime.now();
        await SharedPreferencesService.setLastPasswordResetTime(now);
        
        // Save to notification history
        await SharedPreferencesService.saveNotificationHistory({
          'id': 'pwd_reset_${now.millisecondsSinceEpoch}',
          'type': 'security',
          'title': 'Password Reset',
          'body': 'Your password was reset successfully',
          'createdAt': now.toIso8601String(),
          'isRead': false
        });
        
        // Send email notification to user
        await _sendPasswordResetEmail(widget.email);
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Failed to reset password');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simulate API call with delay
    await Future.delayed(const Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back to login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Update the _sendPasswordResetEmail method to handle errors gracefully
  Future<void> _sendPasswordResetEmail(String email) async {
    try {

      log('Attempting to send password reset email to: $email');
      
      try {
        final result = await Api.sendPasswordResetConfirmationEmail(email);
        log('Password reset email result: $result');
        
        if (result['success'] == true) {
          log('Password reset confirmation email sent successfully');
        } else {
          log('Failed to send password reset email: ${result['message']}');
          // Continue with password reset even if email fails
        }
      } catch (e) {
        // If the API endpoint doesn't exist yet, log it but don't block the flow
        log('API endpoint for password reset email not available: $e');
      }
    } catch (e) {
      log('Error sending password reset email: $e');
      // We don't want to block the password reset process if email fails
      // So we just log the error and continue
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
    });

    // Simulate API call with delay
    await Future.delayed(const Duration(seconds: 1));

    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP resent successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background image
            Image.asset(
              'assets/login.JPG',
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
            ),
            // Overlay
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
            // Content
            Column(
              children: [
                // Fixed top section
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '"Turning Plans into Perfect Moments!"',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable bottom section
                Expanded(
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      if (notification.extent <= 0.2) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      }
                      return true;
                    },
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.7,
                      minChildSize: 0.1,
                      maxChildSize: 0.9,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Pull down indicator
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 5,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  // Form content
                                  _otpVerified
                                      ? _buildPasswordResetForm()
                                      : _buildOTPVerificationForm(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPVerificationForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter 6 Digits Code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter the 6 digits code that you received on your email.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),

        // OTP Input Boxes - 6 boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 45,
              height: 55,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  }
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Verify OTP Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  )
                : const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        // Resend OTP option
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _canResend ? _resendOTP : null,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            child: Text(
              _canResend ? 'Resend OTP' : 'Resend in $_countDown seconds',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordResetForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set New Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please enter your new password.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),

        // New Password Field
        TextField(
          controller: _newPasswordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'New Password',
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
              Icons.lock,
              color: Colors.grey,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Confirm Password Field
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
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
              Icons.lock,
              color: Colors.grey,
            ),
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Reset Password Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
