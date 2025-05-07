import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';

class BookingService {
  // Create a new booking
  static Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    var url = Uri.parse("${APIConstants.baseUrl}api/bookings/create");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(bookingData),
      );

      if (response.statusCode == 201) {
        return {'success': true, ...jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to create booking'};
      }
    } catch (e) {
      debugPrint("Error creating booking: ${e.toString()}");
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get user's bookings
  static Future<List<dynamic>> getUserBookings() async {
    var url = Uri.parse("${APIConstants.baseUrl}api/bookings/user-bookings");
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
        final responseData = jsonDecode(response.body);
        return responseData['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching user bookings: ${e.toString()}");
      return [];
    }
  }

  // Get vendor's bookings
  static Future<List<dynamic>> getVendorBookings() async {
    var url = Uri.parse("${APIConstants.baseUrl}api/bookings/vendor-bookings");
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
        final responseData = jsonDecode(response.body);
        return responseData['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching vendor bookings: ${e.toString()}");
      return [];
    }
  }

  // Update booking status
  static Future<Map<String, dynamic>> updateBookingStatus(
      String bookingId, String status) async {
    var url = Uri.parse(
        "${APIConstants.baseUrl}api/bookings/update-status/$bookingId");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return {'success': true, ...jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to update booking status'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Cancel booking
  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    var url =
        Uri.parse("${APIConstants.baseUrl}api/bookings/cancel/$bookingId");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, ...jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to cancel booking'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<List<Map<String, dynamic>>> getVendorAvailability(
      String vendorId) async {
    var url = Uri.parse(
        "${APIConstants.baseUrl}api/vendorAvailability/vendor-availability/$vendorId");
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
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching vendor availability: ${e.toString()}");
      return [];
    }
  }

  static Future<bool> updateVendorAvailability(String vendorId, DateTime date,
      bool isAvailable, String vendorType) async {
    var url = Uri.parse(
        "${APIConstants.baseUrl}api/vendorAvailability/vendor-availability/update");
    String? token = await APIConstants.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'vendorId': vendorId,
          'date': date.toIso8601String(),
          'isAvailable': isAvailable,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating vendor availability: ${e.toString()}");
      return false;
    }
  }
}
