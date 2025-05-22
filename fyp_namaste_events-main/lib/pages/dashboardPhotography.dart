import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/AddInventory.dart';
import 'package:fyp_namaste_events/pages/ChangePasswordPage.dart';
import 'package:fyp_namaste_events/pages/VendorAvailabilityPage.dart';
import 'package:fyp_namaste_events/pages/VendorProfilePage.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';
import 'package:fyp_namaste_events/pages/pending_req_vendor.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/Api/api_authentication.dart';
import 'InventoryDetailsPage.dart';
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PhotographyDashboard extends StatefulWidget {
  final String token;

  const PhotographyDashboard({required this.token, super.key});

  @override
  _PhotographyDashboardState createState() => _PhotographyDashboardState();
}

class _PhotographyDashboardState extends State<PhotographyDashboard> {
  late String userStatus;
  late String vendorName;
  late String vendorEmail;
  Map<String, dynamic> jwtde = {};
  List<dynamic> inventoryList = [];
  bool isLoading = true;

  String? profileImageUrl; // Add this line to store profile image URL

  @override
  void initState() {
    super.initState();
    // Decode JWT Token
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userStatus = jwtDecodedToken['status'];
    jwtde = jwtDecodedToken;
    vendorName = jwtDecodedToken['vendorName'] ?? 'Unknown Vendor';
    vendorEmail = jwtDecodedToken['email'] ?? 'Unknown Vendor';
    print(jwtDecodedToken);
    print("vendorEmail");
    print(vendorEmail);
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
    _fetchVendorProfile(); // Add this line to fetch profile image
  }

  void _decodeToken() {
    try {
      Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
      userStatus = jwtDecodedToken['status'] ?? 'Unknown';
      vendorName = jwtDecodedToken['email'] ?? 'Unknown Vendor';
      vendorEmail = jwtDecodedToken['email'] ?? 'Unknown Vendor';
      print("vendorEmail");
      print(vendorEmail);
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
      print("Fetched data: $data");
      print("decoded data: $jwtde");
      setState(() {
        inventoryList = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching inventory: $e");
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Function to navigate to different pages
  void _navigateToPage(String page) async {
    switch (page) {
      case 'Dashboard':
        break;
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorProfilePage(
              vendorId: jwtde['id'],
              token: widget.token,
            ),
          ),
        );
        break;
      case 'ChangePassword':
        // Navigate to change password page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangePasswordPage(token: widget.token),
          ),
        );
        break;
      case 'Settings':
        break;
      case 'Add Inventory':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddInventoryPage(token: widget.token),
          ),
        );

        if (result == true) {
          print("Inventory item added");
          _fetchInventory();
        }
        break;
      case 'Availability': // Add this case
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorAvailabilityPage(
              vendorId: jwtde['id'],
              vendorType: 'photography',
              token: widget.token,
            ),
          ),
        );
        break;
      default:
        break;
    }
  }

  // Modified method to fetch vendor profile including profile image
  Future<void> _fetchVendorProfile() async {
    try {
      // Debug the API call
      print("Fetching profile for vendor ID: ${jwtde['id']}");

      final response = await Api.getVendorProfile(jwtde['id']);

      // Debug the response
      print("Vendor profile response: ${json.encode(response)}");

      if (response['success'] == true) {
        final vendor = response['vendor'] ?? {};

        // Debug the vendor data
        print("Vendor data: ${json.encode(vendor)}");

        // Print all keys in the vendor object to help identify the correct field
        print("All vendor keys: ${vendor.keys.toList()}");

        setState(() {
          // Update vendor name if available
          if (vendor['vendorName'] != null &&
              vendor['vendorName'].toString().isNotEmpty) {
            vendorName = vendor['vendorName'];
          } else if (vendor['businessName'] != null &&
              vendor['businessName'].toString().isNotEmpty) {
            vendorName = vendor['businessName'];
          }
        });
      } else {
        print("Failed to fetch vendor profile: ${response['message']}");
      }
    } catch (e) {
      print("Error fetching vendor profile: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photography Dashboard"),
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
                          inventory['photographyName'] ?? "Unknown Item",
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
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              accountName: Text(vendorName),
              accountEmail: Text('Status: $userStatus'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.black),
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
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                _navigateToPage('Profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onTap: () {
                _navigateToPage('ChangePassword');
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
              onTap: () async {
                try {
                  final response = await http.get(
                    Uri.parse(
                        '${APIConstants.baseUrl}api/vendorAvailability/exist?vendorEmail=$vendorEmail'),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                  );

                  final data = json.decode(response.body);

                  print("avail check");
                  print(data);

                  if (data['success'] == true) {
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
                  } else {
                    Navigator.pop(context); // Close drawer first
                    ScaffoldMessenger.of(context)
                        .clearSnackBars(); // Clear existing SnackBars
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please add inventory first to access this service'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior
                            .floating, // Makes it float above other elements
                        margin: EdgeInsets.all(
                            8.0), // Adds margin from screen edges
                        elevation: 6.0, // Increases shadow to stand out more
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Error checking availability: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
        'photographyName': _nameController.text,
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

  // Custom text field widget matching AddInventory style
  Widget _entryField(String title, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
              borderSide: BorderSide(color: Colors.black),
            ),
            fillColor: Colors.white,
            filled: true,
            prefixIcon: title == "Price"
                ? Container(
                    width: 24,
                    alignment: Alignment.center,
                    child: Text(
                      "रू",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Icon(
                    title == "Photography Name"
                        ? Icons.camera_alt
                        : title == "Description"
                            ? Icons.description
                            : title == "Type"
                                ? Icons.category
                                : Icons.text_fields,
                    color: Colors.grey,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Photography Item')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _entryField("Photography Name", _nameController),
                      SizedBox(height: 15),
                      _entryField("Description", _descriptionController,
                          maxLines: 3),
                      SizedBox(height: 15),
                      _entryField("Price", _priceController,
                          keyboardType: TextInputType.number),
                      SizedBox(height: 15),
                      _entryField("Type", _typeController),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateInventory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            _isLoading ? "Updating..." : "Update Photography",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// Add this method to check if an image exists at a URL
Future<bool> _checkImageExists(String url) async {
  try {
    final response = await http.head(Uri.parse(url));
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (e) {
    print("Error checking image existence: $e");
    return false;
  }
}
