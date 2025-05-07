import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/AddInventory.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';
import 'package:fyp_namaste_events/pages/pending_req_vendor.dart';
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../services/Api/api_authentication.dart';
import 'InventoryDetailsPage.dart';
import 'package:fyp_namaste_events/pages/VendorAvailabilityPage.dart';

class VendorDashboard extends StatefulWidget {
  final String token;

  const VendorDashboard({required this.token, super.key});

  @override
  _VendorDashboardState createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  late String userStatus;
  late String vendorName;
  Map<String, dynamic> jwtde = {};
  List<dynamic> inventoryList = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    // Decode JWT Token
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userStatus = jwtDecodedToken['status'];
    jwtde = jwtDecodedToken;
    vendorName = jwtDecodedToken['vendorName'] ?? 'Unknown Vendor';

    if (userStatus == "unverified") {
      // If user is unverified, redirect to Pending Request Page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PendingRequestVendor()),
        );
      });
    }
    _decodeToken();
    _fetchInventory();
  }

  void _decodeToken() {
    try {
      Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
      userStatus = jwtDecodedToken['status'] ?? 'Unknown';
      vendorName = jwtDecodedToken['vendorName'] ?? 'Unknown Vendor';
    } catch (e) {
      userStatus = 'Unknown';
      vendorName = 'Unknown Vendor';
    }
  }

  // Fetch Inventory from API
  void _fetchInventory() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<dynamic> data = await Api.getInventory();
      print("Fetched data: $data"); // Add print statement
      setState(() {
        inventoryList = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching inventory: $e"); // Add error handling
      setState(() {
        isLoading = false;
      });
    }
  }

  // Edit inventory item
  Future<void> _editInventory(Map<String, dynamic> inventory) async {
    // Navigate to edit page and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInventoryPage(
          inventory: inventory,
          token: widget.token,
        ),
      ),
    );

    // If inventory was updated, refresh the list
    if (result == true) {
      _fetchInventory();
    }
  }

  // Delete inventory item
  Future<void> _deleteInventory(String inventoryId) async {
    // Show confirmation dialog
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
      final response = await http.delete(
        Uri.parse('${APIConstants.baseUrl}inventory/delete/$inventoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory deleted successfully')),
        );
        _fetchInventory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete inventory')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Sign-out function
  void _signOut() {
    // Navigate to login page and remove the current screen from stack
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Function to navigate to different pages
  // In the _navigateToPage method, add this case:
  void _navigateToPage(String page) async {
    switch (page) {
      case 'Dashboard':
        // Navigate to the Dashboard page
        break;
      case 'Profile':
        // Navigate to Profile page
        break;
      case 'Settings':
        // Navigate to Settings page
        break;
      case 'Add Inventory':
        // Navigate to Add Inventory page
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddInventoryPage(token: widget.token),
          ),
        );

        // Check if the result indicates that an inventory item was added
        if (result == true) {
          print("Inventory item added");
          _fetchInventory(); // Refresh inventory list
        }
        break;
      case 'Availability': // Add this case
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorAvailabilityPage(
              vendorId: jwtde['id'],
              vendorType: 'venue',
              token: widget.token,
            ),
          ),
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Venue Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchInventory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : inventoryList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "No inventory items found",
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _navigateToPage('Add Inventory'),
                        child: Text("Add New Item"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: inventoryList.length,
                  itemBuilder: (context, index) {
                    final inventory = inventoryList[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(
                          inventory['venueName'] ?? "Unknown Item",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Price: ${inventory['price'] ?? 'N/A'}"),
                            Text("Type: ${inventory['type'] ?? 'N/A'}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InventoryDetailsPage(
                                  inventory: inventory,
                                  token: widget.token,
                                ),
                              ),
                            ).then((_) => _fetchInventory());
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InventoryDetailsPage(
                                inventory: inventory,
                                token: widget.token,
                              ),
                            ),
                          ).then((_) => _fetchInventory());
                        },
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(vendorName),
              accountEmail: Text('Status: $userStatus'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard Home'),
              onTap: () {
                _navigateToPage('Dashboard');
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Inventory'),
              onTap: () {
                _navigateToPage('Add Inventory');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Manage Availability'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorAvailabilityPage(
                      vendorId: jwtde['id'],
                      vendorType: 'venue',
                      token: widget.token,
                    ),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}

// Remove the _editInventory and _deleteInventory functions completely

// Update the ListTile trailing section to remove edit/delete buttons

// Remove the EditInventoryPage class completely
class EditInventoryPage extends StatefulWidget {
  final Map<String, dynamic> inventory;
  final String token;

  const EditInventoryPage({
    required this.inventory,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  _EditInventoryPageState createState() => _EditInventoryPageState();
}

class _EditInventoryPageState extends State<EditInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _typeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.inventory['photographyName']);
    _priceController = TextEditingController(
        text: widget.inventory['price']?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: widget.inventory['description'] ?? '');
    _typeController =
        TextEditingController(text: widget.inventory['type'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _updateInventory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> updatedData = {
        'venueName': _nameController.text,
        'price': _priceController.text,
        'description': _descriptionController.text,
        'type': _typeController.text,
      };

      final response = await http.put(
        Uri.parse(
            '${APIConstants.baseUrl}inventory/update/${widget.inventory['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode(updatedData),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to update: ${responseData['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit venue Item'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Photography Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _typeController,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a type';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateInventory,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Update Inventory',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
