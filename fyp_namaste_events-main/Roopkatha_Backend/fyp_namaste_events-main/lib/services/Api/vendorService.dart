import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';

class VendorService {
  final String baseUrl;

  VendorService(this.baseUrl);

  Future<Map<String, dynamic>> fetchAllInventory() async {
    var url = Uri.parse("${APIConstants.baseUrl}inventory/get_all_inventory");
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
        return jsonDecode(response.body);
      } else {
        return {"success": false, "data": []};
      }
    } catch (e) {
      debugPrint("Error fetching all inventory: ${e.toString()}");
      return {"success": false, "data": []};
    }
  }
}