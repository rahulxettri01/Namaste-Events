import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';

class ApiVendorAvailability {
  static Future<List<dynamic>> getAvailableSlots(
      String vendorEmail, String token) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${APIConstants.baseUrl}api/vendorAvailability/available?vendorEmail=$vendorEmail'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("get the availability slots");
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch availability slots: $e');
    }
  }

  static Future<bool> createSlot(
      String token, Map<String, dynamic> slotData) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}api/vendorAvailability/create-slot'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(slotData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error in createSlot: $e');
      return false;
    }
  }

  static Future<bool> updateSlot(
      String token, String slotId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${APIConstants.baseUrl}api/vendorAvailability/update-slot/$slotId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      print('Update Response status: ${response.statusCode}');
      print('Update Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error in updateSlot: $e');
      return false;
    }
  }

  static Future<List<dynamic>> fetchVendorAvailability(
      String vendorEmail) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${APIConstants.baseUrl}api/vendorAvailability/slots/$vendorEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Fetch Availability Response status: ${response.statusCode}');
      print('Fetch Availability Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching vendor availability: $e');
      return [];
    }
  }

  static Future<List<dynamic>> fetchVendorAvailabilityById(
      String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${APIConstants.baseUrl}api/vendorAvailability/slots/vendor/$vendorId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Fetch Availability Response status: ${response.statusCode}');
      print('Fetch Availability Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching vendor availability: $e');
      return [];
    }
  }

  static Future<dynamic> createBooking(
      Map<String, dynamic> bookingData, String token) async {
    try {
      print("Booking data");
      print(bookingData);
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}api/bookings/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vendorId': bookingData['vendorId'],
          'price': bookingData['price'],
          'eventType': bookingData['eventType'],
          'startDate': bookingData['startDate'],
          'endDate': bookingData['endDate'],
          'eventName': bookingData['eventName'],
          'eventDescription': bookingData['eventDescription'],
          'guestCount': bookingData['guests'],
          'totalAmount': bookingData['totalPrice'],
        }),
      );

      print('Booking Response status: ${response.statusCode}');
      print('Booking Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // print("Response data");
        // print(responseData);
        return responseData;
      } else {
        return null;
      }
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getBookedDates(String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${APIConstants.baseUrl}api/vendorAvailability/slots/vendor/$vendorId'), // Fix URL path
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': 200,
          'data': responseData['data']
              .map((slot) => DateTime.parse(slot['startDate']))
              .toList(),
        };
      } else {
        return {
          'status': response.statusCode,
          'message': responseData['message'] ?? 'Failed to fetch booked dates',
        };
      }
    } catch (e) {
      return {
        'status': 500,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Add new method for getting vendor availability by ID
  static Future<List<dynamic>> getVendorAvailabilityById(
      String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${APIConstants.baseUrl}api/vendorAvailability/slots/vendor/$vendorId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching vendor availability by ID: $e');
      return [];
    }
  }
}
