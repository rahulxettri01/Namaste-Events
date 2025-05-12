import 'dart:ui';
import 'package:fyp_namaste_events/pages/otp/VerifyOTPPage.dart';
import 'package:fyp_namaste_events/services/Api/api_authentication.dart';
import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';
import 'package:fyp_namaste_events/utils/validator.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  var controllerName = TextEditingController();
  var controllerEmail = TextEditingController();
  var controllerPhone = TextEditingController();
  var controllerPassword = TextEditingController();
  var controllerConfirmPassword = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isTermsAccepted = false;
  String? selectedRole;
  String? selectedVendorType;
  String? errorMessage = '';

  // Add this variable to track loading state
  bool isSigningUp = false;

  void _signUp() async {
    if (isSigningUp) return;

    setState(() {
      isSigningUp = true;
      errorMessage = '';
    });

    // Validate all fields
    String? nameError = Validator.validateName(controllerName.text);
    String? emailError = Validator.validateEmail(controllerEmail.text);
    String? phoneError = Validator.validatePhone(controllerPhone.text);
    String? passwordError = Validator.validatePassword(controllerPassword.text);
    String? confirmPasswordError = Validator.validateConfirmPassword(
        controllerConfirmPassword.text, controllerPassword.text);
    String? roleError = Validator.validateRole(selectedRole);
    String? vendorTypeError =
        Validator.validateVendorType(selectedVendorType, selectedRole);

    // Check for validation errors
    if (nameError != null) {
      setState(() {
        errorMessage = nameError;
        isSigningUp = false;
      });
      return;
    } else if (emailError != null) {
      setState(() {
        errorMessage = emailError;
        isSigningUp = false;
      });
      return;
    } else if (phoneError != null) {
      setState(() {
        errorMessage = phoneError;
        isSigningUp = false;
      });
      return;
    } else if (passwordError != null) {
      setState(() {
        errorMessage = passwordError;
        isSigningUp = false;
      });
      return;
    } else if (confirmPasswordError != null) {
      setState(() {
        errorMessage = confirmPasswordError;
        isSigningUp = false;
      });
      return;
    } else if (roleError != null) {
      setState(() {
        errorMessage = roleError;
        isSigningUp = false;
      });
      return;
    } else if (vendorTypeError != null) {
      setState(() {
        errorMessage = vendorTypeError;
        isSigningUp = false;
      });
      return;
    } else if (!isTermsAccepted) {
      setState(() {
        errorMessage = "You must accept the Terms of Service";
        isSigningUp = false;
      });
      return;
    }

    // If all validations pass, proceed with signup
    var data = {
      "userName": controllerName.text,
      "email": controllerEmail.text,
      "phone": controllerPhone.text,
      "password": controllerPassword.text,
      "role": selectedRole,
    };
    
    // Add vendor-specific data if the role is Vendor
    if (selectedRole == "Vendor") {
      data["vendorType"] = selectedVendorType;
      data["category"] = selectedVendorType;
      
      // Create a vendor model to store locally if needed
      Map<String, dynamic> vendorData = {
        "userName": controllerName.text,
        "email": controllerEmail.text,
        "phone": controllerPhone.text,
        "vendorType": selectedVendorType,
        "category": selectedVendorType,
      };
      
      // Save vendor data to local storage or state management
      // This could be implemented using shared_preferences or another storage method
      print("Saving vendor data: $vendorData");
    }

    try {
      // Call the API and handle the response
      final response = await Api.signup(data);
      
      if (response != null) {
        int statusCode = response["status_code"];
        if (statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Signup successful! Please verify your email."),
              backgroundColor: Colors.green,
            ),
          );
          if (response["userDetails"]["role"] == "User") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyOTPPage(
                  userId: response['userId'],
                  email: controllerEmail.text,
                ),
              ),
            );
          }
        } else if (statusCode == 409) {  // Assuming 409 is the status code for email conflict
          setState(() {
            errorMessage = "This email address is already registered.";
            // Update the email field error state
            controllerEmail.text = controllerEmail.text; // Trigger field validation
          });
        } else {
          setState(() {
            errorMessage = response["message"] ?? "Signup failed. Try again.";
          });
        }
      } else {
        setState(() {
          errorMessage = "Unexpected response from server.";
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Error occurred: ${error.toString()}";
      });
    } finally {
      setState(() {
        isSigningUp = false;
      });
    }
  }

  Widget _entryField(String title, TextEditingController controller,
      {bool isPassword = false, bool isConfirmPassword = false}) {
    // Get field-specific error message
    String? getFieldError() {
      if (controller.text.isEmpty) return null;
      
      switch (title) {
        case "Name":
          return Validator.validateName(controller.text);
        case "Email":
          return Validator.validateEmail(controller.text);
        case "Phone Number":
          return Validator.validatePhone(controller.text);
        case "Password":
          return Validator.validatePassword(controller.text);
        case "Confirm Password":
          return Validator.validateConfirmPassword(
              controller.text, controllerPassword.text);
        default:
          return null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: (isPassword && !isPasswordVisible) ||
              (isConfirmPassword && !isConfirmPasswordVisible),
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
              isPassword || isConfirmPassword
                  ? Icons.lock
                  : title == "Email"
                      ? Icons.email
                      : title == "Name"
                          ? Icons.person
                          : title == "Phone Number"
                              ? Icons.phone
                              : Icons.text_fields,
              color: getFieldError() != null ? Colors.red : Colors.grey,
            ),
            suffixIcon: isPassword || isConfirmPassword
                ? IconButton(
                    icon: Icon(
                      (isPassword && isPasswordVisible) ||
                              (isConfirmPassword && isConfirmPasswordVisible)
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: getFieldError() != null ? Colors.red : null,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPassword) {
                          isPasswordVisible = !isPasswordVisible;
                        } else {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        }
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
      items: ['User', 'Vendor'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedRole = newValue;
          selectedVendorType = null;
          
          // If vendor is selected, prepare vendor model data
          if (selectedRole == "Vendor") {
            // This will be used when submitting the form
            print("Vendor role selected - will save as VendorModel");
          }
        });
      },
    );
  }

  Widget _vendorTypeDropdown() {
    return selectedRole == "Vendor"
        ? DropdownButtonFormField<String>(
            value: selectedVendorType,
            decoration: InputDecoration(
              labelText: 'Select Vendor Type',
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
                Icons.business,
                color: Colors.grey,
              ),
            ),
            items: ['Venue', 'Decoration', 'Photography'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedVendorType = newValue;
              });
            },
          )
        : Container();
  }

  Widget _termsAndConditions() {
    return Row(
      children: [
        Transform.scale(
          scale: 1.3,
          child: Checkbox(
            value: isTermsAccepted,
            onChanged: (value) {
              setState(() {
                isTermsAccepted = value!;
              });
            },
            activeColor: Colors.black,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const Flexible(
          child: Text(
            "I agree with the Terms of Service & Privacy Policy",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _loginText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Have an account?",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          ),
          child: const Text(
            "Log in",
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

  // Updated forgot password dialog with loading indicator
  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;

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
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                        if (emailController.text.isNotEmpty) {
                          // Show loading indicator
                          setState(() {
                            isLoading = true;
                          });

                          // Simulate API call with a delay
                          await Future.delayed(const Duration(seconds: 2));

                          // Call password reset API here

                          // Hide dialog and show success message
                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("OTP sent to your email"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
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
        child: Stack(
          children: [
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
                  "Join us to start searching",
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
                          _entryField("Name", controllerName),
                          const SizedBox(height: 16),
                          _entryField("Email", controllerEmail),
                          const SizedBox(height: 16),
                          _entryField("Phone Number", controllerPhone),
                          const SizedBox(height: 16),
                          _entryField("Password", controllerPassword,
                              isPassword: true),
                          const SizedBox(height: 16),
                          _entryField(
                              "Confirm Password", controllerConfirmPassword,
                              isConfirmPassword: true),
                          const SizedBox(height: 16),
                          _roleDropdown(),
                          const SizedBox(height: 16),
                          _vendorTypeDropdown(),
                          const SizedBox(height: 16),
                          _termsAndConditions(),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: isSigningUp
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text(
                                    'Sign up',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _loginText(),
                          if (errorMessage != null && errorMessage!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
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
}
