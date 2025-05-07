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
    var url = Uri.parse("${APIConstants.baseUrl}auth/users/reset-password");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
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
} // End of Api class
