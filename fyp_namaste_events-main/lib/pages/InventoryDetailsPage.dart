import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/services/Api/bookingService.dart';
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:fyp_namaste_events/services/Api/api_authentication.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class InventoryDetailsPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> inventory;

  const InventoryDetailsPage(
      {required this.inventory, required this.token, Key? key})
      : super(key: key);

  @override
  _InventoryDetailsPageState createState() => _InventoryDetailsPageState();
}

class _InventoryDetailsPageState extends State<InventoryDetailsPage> {
  Map<String, dynamic> inventoryData = {};
  Map<String, dynamic> inventory = {};
  List<dynamic> images = [];
  bool isLoading = true;
  bool isEditing = false;
  String errorMessage = '';
  var email = '';

  // Controllers for editable fields
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController addressController;
  late TextEditingController descriptionController;
  // Add this to your existing variables
  List<DateTime> unavailableDates = [];

  @override
  void initState() {
    super.initState();
    inventory = widget.inventory;
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    email = jwtDecodedToken['email'];

    // Initialize controllers with current values
    nameController =
        TextEditingController(text: inventory['photographyName'] ?? '');
    priceController =
        TextEditingController(text: inventory['price']?.toString() ?? '');
    addressController = TextEditingController(text: inventory['address'] ?? '');
    descriptionController =
        TextEditingController(text: inventory['description'] ?? '');

    fetchImages();
    fetchAvailability(); // Add this line
  }

  // Add this new method
  Future<void> fetchAvailability() async {
    try {
      final availability = await BookingService.getVendorAvailability(email);
      setState(() {
        unavailableDates = availability
            .where((a) => a['isAvailable'] == false)
            .map((a) => DateTime.parse(a['date']))
            .toList();
      });
    } catch (e) {
      print("Error fetching availability: $e");
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> updateInventory() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Prepare the updated data based on inventory type
      final Map<String, dynamic> updatedData =
          {}; // Explicitly declare as Map<String, dynamic>

      if (inventory.containsKey('venueName')) {
        updatedData['venueName'] = nameController.text;
      } else if (inventory.containsKey('decoratorName')) {
        updatedData['decoratorName'] = nameController.text;
      } else if (inventory.containsKey('photographyName')) {
        updatedData['photographyName'] = nameController.text;
      }

      updatedData['price'] = priceController.text;
      updatedData['address'] = addressController.text;
      updatedData['description'] = descriptionController.text;
      updatedData['owner'] = email; // Add owner email for backend verification

      // Print the updated data to console for debugging
      print("Updating inventory with ID: ${inventory['_id']}");
      print("Updated data: $updatedData");

      // Use the API service to update
      final result = await Api.updateInventory(inventory['_id'], updatedData);

      print("Update result: $result");

      if (result['success'] == true) {
        // Update local state with new data
        setState(() {
          inventory = {
            ...inventory,
            ...updatedData,
          };
          isEditing = false;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory updated successfully')),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Update failed')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteInventory() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      setState(() {
        isLoading = true;
      });

      // Print the inventory ID for debugging
      print("Deleting inventory with ID: ${inventory['_id']}");

      // Use the API service to delete
      final result = await Api.deleteInventory(inventory['_id']);

      print("Delete result: $result");

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory deleted successfully')),
        );
        Navigator.pop(
            context, true); // Return to previous screen with refresh flag
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Delete failed')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> fetchInventoryData() async {
    try {
      // First fetch the inventory data using the token
      final response = await http.get(
        Uri.parse('${APIConstants.baseUrl}api/get_inventory'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Response body: ${response.body}");
        print("Parsed data: $data");

        // Check data structure and handle different formats
        if (data != null && data.containsKey('data')) {
          var inventoryInfo = data['data'];
          print("Data['data'] type: ${inventoryInfo.runtimeType}");

          if (inventoryInfo is List && inventoryInfo.isNotEmpty) {
            // If data is a list, take the first item
            setState(() {
              inventoryData = Map<String, dynamic>.from(inventoryInfo[0]);
              print("Set inventoryData from list: $inventoryData");
            });
          } else if (inventoryInfo is Map) {
            // If data is already a map
            setState(() {
              inventoryData = Map<String, dynamic>.from(inventoryInfo);
              print("Set inventoryData from map: $inventoryData");
            });
          } else {
            print("Unexpected data format: $inventoryInfo");
            setState(() {
              isLoading = false;
              errorMessage = 'Invalid data format received';
            });
            return;
          }
        } else {
          // If no 'data' key, try using the whole response
          setState(() {
            if (data is Map) {
              inventoryData = Map<String, dynamic>.from(data);
            } else {
              errorMessage = 'Invalid response format';
              isLoading = false;
              return;
            }
          });
        }

        // Now fetch the images
        fetchImages();
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              'Failed to load inventory details: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("Error in fetchInventoryData: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> getImageFiles(folderName) async {
    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}vendor/get_inventory_files'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(
            {'email': email, 'type': "inventory", "folderName": "$folderName"}),
      );
      print("ResponseForImagesFromFolder: ${response.body}");
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> fetchImages() async {
    try {
      // Determine the email from the inventory data
      print("Inventoreeeeey: $inventory");
      print("email: $email");
      if (email.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No email found for this inventory';
        });
        return;
      }

      // Determine the type based on inventory category
      String type = 'photography'; // Default type
      if (inventoryData['venueName'] != null) {
        type = 'venue';
      } else if (inventoryData['decoratorName'] != null) {
        type = 'decoration';
      } else if (inventoryData['photographyName'] != null) {
        type = 'photography';
      }

      print("email: $email");
      print("type: $type");
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}vendor/get_verification_images'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'email': email,
          'type': "inventory",
        }),
      );
      // print("Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Response aayo lol: ${data['data']}");
        // getImageFiles(data['data']['filePath']);

        print("imgeUrl: ${data['data'][0]['fullUrl']}");
        setState(() {
          images = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load images: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String inventoryName = inventory['venueName'] ??
        inventory['decoratorName'] ??
        inventory['photographyName'] ??
        "Unknown Inventory";

    return Scaffold(
      appBar: AppBar(
        title: Text("$inventoryName Details"),
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          if (isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: updateInventory,
            ),
          if (isEditing)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isEditing = false;
                  // Reset controllers to original values
                  nameController.text = inventory['photographyName'] ?? '';
                  priceController.text = inventory['price']?.toString() ?? '';
                  addressController.text = inventory['address'] ?? '';
                  descriptionController.text = inventory['description'] ?? '';
                });
              },
            ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteInventory,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditing) ...[
                      Text(
                        inventoryName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text("Address: ${inventory['address'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text("Price: ${inventory['price'] ?? 'N/A'}",
                          style: const TextStyle(
                              fontSize: 18, color: Colors.green)),
                      const SizedBox(height: 10),
                      Text("Status: ${inventory['status'] ?? 'Unknown'}",
                          style: TextStyle(
                              fontSize: 18,
                              color: inventory['status'] == 'available'
                                  ? Colors.green
                                  : Colors.red)),
                      const SizedBox(height: 10),
                      Text("Description: ${inventory['description'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 18)),
                    ],
                    if (isEditing) ...[
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Name'),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: priceController,
                        decoration: InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(labelText: 'Address'),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text("Images:",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if (images.isNotEmpty)
                      Column(
                        children: images.map((image) {
                          return Image.network(
                            '${image['fullUrl']}',
                            height: 300,
                            fit: BoxFit.contain,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      "Unavailable Dates:",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (unavailableDates.isEmpty)
                      Text("No unavailable dates",
                          style: TextStyle(fontSize: 16))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: unavailableDates.map((date) {
                          return Chip(
                            label: Text(
                              "${date.day}/${date.month}/${date.year}",
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
                    Text("Images:",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if (images.isNotEmpty)
                      Column(
                        children: images.map((image) {
                          return Image.network(
                            '${image['fullUrl']}',
                            height: 300,
                            fit: BoxFit.contain,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
