import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';

class Api {
  static Future<Map<String, dynamic>> signup(Map<String, dynamic> udata) async {
    var url = Uri.parse("${APIConstants.baseUrl}auth/sign_up");
    debugPrint("Request URL: $url");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode(udata),
      );
      print("register resp");
      print(response);
      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      return {
        "success": false,
        "message": "Something went wrong. Please try again later."
      };
    }
  }

  static Future<Map<String, dynamic>> login(Map<String, dynamic> udata) async {
    var url = Uri.parse("${APIConstants.baseUrl}auth/log_in");
    var token = APIConstants.getToken();
    debugPrint("Request URL: $url");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(udata),
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      return {
        "success": false,
        "message": "Something went wrong. Please try again later."
      };
    }
  }

  static Future<Map<String, dynamic>> loginAdmin(
      Map<String, dynamic> udata) async {
    var url = Uri.parse("${APIConstants.baseUrl}superadmin/log_in");
    debugPrint("Request URL: $url");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(udata),
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Server error: ${response.body}"};
      }
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      return {
        "success": false,
        "message": "Something went wrong. Please try again later."
      };
    }
  }

  static Future<Map<String, dynamic>> addInventory(
      Map<String, dynamic> vdata) async {
    var url = Uri.parse("${APIConstants.baseUrl}api/add_inventory");
    String? token = await APIConstants.getToken();
    debugPrint("Request URL: $url");

    try {
      var response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(vdata),
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        return {"message": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      return {
        "success": false,
        "message": "Something went wrong. Please try again later."
      };
    }
  }

  static Future<List<dynamic>> getInventory() async {
    var url = Uri.parse("${APIConstants.baseUrl}api/get_inventory");
    String? token = await APIConstants.getToken();

    try {
      var response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['data'];
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching inventory: ${e.toString()}");
      return [];
    }
  }

  static Future<List<dynamic>> getVendorsByStatus(String status) async {
    var url = Uri.parse("${APIConstants.baseUrl}api/vendors/$status");
    String? token = await APIConstants.getToken();

    try {
      var response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['data'];
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching vendors: ${e.toString()}");
      return [];
    }
  }

  static Future<List<dynamic>> fetchImages() async {
    var url = Uri.parse("${APIConstants.baseUrl}images");
    debugPrint("Request URL: $url");

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['data'];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      return [];
    }
  }

  static Future<List<dynamic>> fetchImagesByEmail(String email) async {
    var url = Uri.parse("${APIConstants.baseUrl}images/email/$email");
    debugPrint("Request URL: $url");

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['data'];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateInventory(
      String id, Map<String, dynamic> data) async {
    try {
      String? token = await APIConstants.getToken();
      debugPrint("Update inventory URL: ${APIConstants.baseUrl}api/update/$id");
      debugPrint("Update data: ${jsonEncode(data)}");

      final response = await http.put(
        Uri.parse('${APIConstants.baseUrl}api/update/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      debugPrint("Update response status: ${response.statusCode}");
      debugPrint("Update response body: ${response.body}");

      // Check if response is HTML
      if (response.body.trim().toLowerCase().startsWith('<!doctype html>')) {
        return {
          'success': false,
          'message': 'Server returned HTML instead of JSON. Check API endpoint.'
        };
      }

      try {
        return jsonDecode(response.body);
      } catch (e) {
        if (e is FormatException) {
          return {
            'success': false,
            'message': 'Invalid response format: ${e.message}'
          };
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint("Update error: ${e.toString()}");
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteInventory(String id) async {
    try {
      String? token = await APIConstants.getToken();
      debugPrint("Delete inventory URL: ${APIConstants.baseUrl}api/delete/$id");

      final response = await http.delete(
        Uri.parse('${APIConstants.baseUrl}api/delete/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Delete response status: ${response.statusCode}");
      debugPrint("Delete response body: ${response.body}");

      // Check if response is HTML
      if (response.body.trim().toLowerCase().startsWith('<!doctype html>')) {
        return {
          'success': false,
          'message': 'Server returned HTML instead of JSON. Check API endpoint.'
        };
      }

      try {
        return jsonDecode(response.body);
      } catch (e) {
        if (e is FormatException) {
          return {
            'success': false,
            'message': 'Invalid response format. Check server logs.'
          };
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint("Delete error: ${e.toString()}");
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>?> verifyOTP(
    String userId,
    String otp,
  ) async {
    try {
      print("UserId on veyrify otp");
      print(userId);
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, ...jsonDecode(response.body)};
      } else {
        return {'success': false, ...jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>?> resendOTP(
    String email,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}api/otp/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> resetPassword(
    String userId,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, ...jsonDecode(response.body)};
      } else {
        return {'success': false, ...jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, ...jsonDecode(response.body)};
      } else {
        return {'success': false, ...jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    var url = Uri.parse("${APIConstants.baseUrl}auth/users/profile");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to fetch profile: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error fetching profile: ${e.toString()}"
      };
    }
  }

  // Add these methods to the Api class

    static Future<Map<String, dynamic>> getVendorProfile(String vendorId) async {
      var url = Uri.parse("${APIConstants.baseUrl}auth/vendors/$vendorId");
      String? token = await APIConstants.getToken();
  
      try {
        final response = await http.get(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );
  
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          debugPrint("Vendor profile fetch error: ${response.statusCode}");
          debugPrint("Response body: ${response.body}");
          return {
            "success": false,
            "message": "Failed to fetch vendor profile: ${response.statusCode}"
          };
        }
      } catch (e) {
        debugPrint("Error fetching vendor profile: ${e.toString()}");
        return {
          "success": false,
          "message": "Error fetching vendor profile: ${e.toString()}"
        };
      }
    }
  
    static Future<Map<String, dynamic>> updateVendorProfile({
      required String vendorId,
      required Map<String, dynamic> vendorData,
    }) async {
      var url = Uri.parse("${APIConstants.baseUrl}auth/vendors/update/$vendorId");
      String? token = await APIConstants.getToken();
  
      try {
        final response = await http.put(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(vendorData),
        );
  
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          debugPrint("Vendor profile update error: ${response.statusCode}");
          debugPrint("Response body: ${response.body}");
          return {
            "success": false,
            "message": "Failed to update vendor profile: ${response.statusCode}"
          };
        }
      } catch (e) {
        debugPrint("Error updating vendor profile: ${e.toString()}");
        return {
          "success": false,
          "message": "Error updating vendor profile: ${e.toString()}"
        };
      }
    }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String userName,
    required String phone,
  }) async {
    var url = Uri.parse("${APIConstants.baseUrl}auth/users/update_profile");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userName": userName,
          "phone": phone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to update profile: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error updating profile: ${e.toString()}"
      };
    }
  }

  // Fix the checkVendorEmail method with the correct endpoint
    static Future<Map<String, dynamic>> checkVendorEmail(Map<String, String> data) async {
      try {
        print("Checking vendor email: ${data['email']}");
        
        // Update the endpoint path to include vendor/auth prefix
        final response = await http.post(
          Uri.parse('${APIConstants.baseUrl}vendor/auth/vendors/check-email'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': data['email'],
          }),
        );
      
        print("Vendor email check response status: ${response.statusCode}");
        print("Vendor email check response body: ${response.body}");
      
        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          return {
            "success": true,
            "exists": responseData['exists'] ?? false,
            "email": data['email'],
            "vendorId": responseData['vendorId'] ?? '',
            "message": responseData['message'] ?? "Email check completed"
          };
        } else {
          return {
            "success": false,
            "message": "Email check failed: ${response.statusCode}",
          };
        }
      } catch (e) {
        print("Exception in checkVendorEmail: ${e.toString()}");
        return {
          "success": false,
          "message": "Error: ${e.toString()}",
        };
      }
    }

  static Future<Map<String, dynamic>> checkValidEmail(
      Map<String, String> emailData) async {
    var url = Uri.parse("${APIConstants.baseUrl}auth/isValidMail");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailData["email"],
          "role": emailData["role"],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to check email: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error checking email: ${e.toString()}"
      };
    }
  }

  static Future<Map<String, dynamic>> resetUserPassword({
    required String userId,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}auth/users/reset-password'),
        headers: {
          "Authorization": "Bearer ${await APIConstants.getToken()}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to reset password: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error resetting password: ${e.toString()}"
      };
    }
  }

  // Add new methods inside the Api class
  static Future<List<dynamic>> getAllUsers() async {
    var url = Uri.parse("${APIConstants.baseUrl}superadmin/get_all_users");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['data'];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching all users: ${e.toString()}");
      return [];
    }
  }

  static Future<List<dynamic>> getVerifiedUsers() async {
    var url = Uri.parse("${APIConstants.baseUrl}superadmin/get_verified_users");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['data'];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching verified users: ${e.toString()}");
      return [];
    }
  }

  static Future<List<dynamic>> getUnverifiedUsers() async {
    var url =
        Uri.parse("${APIConstants.baseUrl}superadmin/get_unverified_users");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['data'];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching unverified users: ${e.toString()}");
      return [];
    }
  }
 // End of Api class

// Add this method for vendor password change
  static Future<Map<String, dynamic>> changeVendorPassword({
    required String vendorId,
    required String newPassword,
    required String token, 
    required String currentPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}auth/vendors/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vendorId': vendorId,
          'currentPassword': currentPassword, // Include current password for verification
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, ...jsonDecode(response.body)};
      } else {
        return {'success': false, ...jsonDecode(response.body)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Add this method for user password change
  static Future<Map<String, dynamic>> changeUserPassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}auth/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      debugPrint("Change password response status: ${response.statusCode}");
      
      // Check if response is HTML (which happens with 404 errors)
      if (response.body.trim().toLowerCase().startsWith('<!doctype html>')) {
        return {
          'success': false,
          'message': 'Server Error: 404 Not Found. The endpoint could not be reached.',
          'statusCode': response.statusCode
        };
      }
      
      // Try to parse JSON response
      try {
        final responseData = jsonDecode(response.body);
        responseData['statusCode'] = response.statusCode;
        
        if (response.statusCode == 404) {
          return {
            'success': false,
            'message': 'Server Error: 404 Not Found. The server endpoint could not be reached.',
            'statusCode': 404
          };
        } else if (response.statusCode == 401) {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Authentication failed. Please log in again.',
            'statusCode': 401
          };
        } else if (response.statusCode == 400) {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Invalid request. Please check your inputs.',
            'statusCode': 400
          };
        } else if (response.statusCode != 200) {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Server error: ${response.statusCode}',
            'statusCode': response.statusCode
          };
        }
        
        return responseData;
      } catch (e) {
        // JSON parsing error
        return {
          'success': false,
          'message': 'Invalid response format. Server returned status code: ${response.statusCode}',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      debugPrint("Change password error: ${e.toString()}");
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'statusCode': 0
      };
    }
  }

// Add these methods to your Api class

static Future<Map<String, dynamic>?> forgotVendorPassword(String email) async {
  try {
    print("Sending forgot password request for vendor email: $email");
    
    // Update the endpoint to match the one that has OTP generation implemented
    final response = await http.post(
      Uri.parse('${APIConstants.baseUrl}vendor/auth/vendor/forgot-password'),  // Changed to use the correct endpoint
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    print("Forgot vendor password response status: ${response.statusCode}");
    print("Forgot vendor password response body: ${response.body}");

    // Rest of the method remains the same
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return {
        'success': true, 
        'vendorId': responseData['vendorId'] ?? '',
        'message': responseData['message'] ?? "OTP sent to your email"
      };
    } else {
      try {
        var responseData = jsonDecode(response.body);
        return {
          'success': false, 
          'message': responseData['message'] ?? "Failed to send OTP"
        };
      } catch (e) {
        return {
          'success': false, 
          'message': "Failed to send OTP. Status code: ${response.statusCode}"
        };
      }
    }
  } catch (e) {
    print("Exception in forgotVendorPassword: ${e.toString()}");
    return {'success': false, 'message': 'Error: ${e.toString()}'};
  }
}

static Future<Map<String, dynamic>?> verifyVendorOTP({
  required String email,
  required String otp,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${APIConstants.baseUrl}vendor/auth/verify-otp'),  // Make sure this matches your backend
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    print("Verify vendor OTP response status: ${response.statusCode}");
    print("Verify vendor OTP response body: ${response.body}");

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return {
        'success': true,
        'vendorId': responseData['vendorId'] ?? '',
        'token': responseData['token'] ?? '',
        'message': responseData['message'] ?? "OTP verified successfully"
      };
    } else {
      var responseData = jsonDecode(response.body);
      return {
        'success': false,
        'message': responseData['message'] ?? "Failed to verify OTP"
      };
    }
  } catch (e) {
    print("Exception in verifyVendorOTP: ${e.toString()}");
    return {'success': false, 'message': 'Error: ${e.toString()}'};
  }
}

static Future<Map<String, dynamic>?> resetVendorPassword({
  required String token,
  required String vendorId,
  required String newPassword,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${APIConstants.baseUrl}vendor/auth/reset-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'vendorId': vendorId,
        'newPassword': newPassword,
      }),
    );

    debugPrint("Reset vendor password response status: ${response.statusCode}");
    debugPrint("Reset vendor password response body: ${response.body}");

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': responseData['message'] ?? "Password reset successfully"
      };
    } else {
      try {
        var responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? "Failed to reset password",
          'statusCode': response.statusCode
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Error processing server response',
          'statusCode': response.statusCode
        };
      }
    }
  } catch (e) {
    debugPrint("Reset vendor password error: ${e.toString()}");
    return {'success': false, 'message': 'Error: ${e.toString()}'};
  }
}
}