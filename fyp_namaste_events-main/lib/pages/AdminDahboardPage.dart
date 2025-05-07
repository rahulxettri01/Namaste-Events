import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';
import 'package:fyp_namaste_events/pages/vendor_details_page.dart';
import 'package:fyp_namaste_events/services/Api/api_authentication.dart';
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fyp_namaste_events/pages/vendor_list_page.dart'; // Import the new page

class AdminDashboardPage extends StatefulWidget {
  final String token;

  const AdminDashboardPage({required this.token, Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<dynamic> vendors = [];
  bool isLoading = true;
  String errorMessage = '';
  late SharedPreferences prefs;
  String _currentView =
      'all'; // 'all', 'verified', 'unverified', 'rejected', 'dashboard'
  Map<String, int> vendorTypeCounts = {}; // To store counts of each vendor type
  // Add these variables at the top of the class
  int totalUsers = 0;
  int verifiedUsers = 0;
  int unverifiedUsers = 0;
  @override
  void initState() {
    super.initState();
    _fetchVendors();
    _fetchVendorTypeCounts(); // Fetch vendor type counts on init
    _fetchUserStatistics();
  }

  // Add this method to fetch vendor type counts
  Future<void> _fetchVendorTypeCounts() async {
    try {
      var url = Uri.parse('${APIConstants.baseUrl}superadmin/get_all_vendors');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          List<dynamic> allVendors = responseData['data'];

          // Initialize counts with more specific categories
          Map<String, int> counts = {
            'venue': 0,
            'decoration': 0,
            'photography': 0,
            'catering': 0,
            'music': 0,
            'transportation': 0,
            'other': 0,
          };

          // Count vendors by type with better category detection
          for (var vendor in allVendors) {
            String vendorType = 'other';

            // Check different possible field names for vendor type
            if (vendor['vendorType'] != null) {
              vendorType = vendor['vendorType'].toString().toLowerCase();
            } else if (vendor['category'] != null) {
              vendorType = vendor['category'].toString().toLowerCase();
            } else if (vendor['type'] != null) {
              vendorType = vendor['type'].toString().toLowerCase();
            }

            // Map similar categories together
            if (vendorType.contains('venue') ||
                vendorType.contains('hall') ||
                vendorType.contains('location')) {
              counts['venue'] = (counts['venue'] ?? 0) + 1;
            } else if (vendorType.contains('decor') ||
                vendorType.contains('decoration')) {
              counts['decoration'] = (counts['decoration'] ?? 0) + 1;
            } else if (vendorType.contains('photo') ||
                vendorType.contains('camera') ||
                vendorType.contains('video')) {
              counts['photography'] = (counts['photography'] ?? 0) + 1;
            } else if (vendorType.contains('cater') ||
                vendorType.contains('food')) {
              counts['catering'] = (counts['catering'] ?? 0) + 1;
            } else if (vendorType.contains('music') ||
                vendorType.contains('dj') ||
                vendorType.contains('band')) {
              counts['music'] = (counts['music'] ?? 0) + 1;
            } else if (vendorType.contains('transport') ||
                vendorType.contains('car') ||
                vendorType.contains('vehicle')) {
              counts['transportation'] = (counts['transportation'] ?? 0) + 1;
            } else {
              counts['other'] = (counts['other'] ?? 0) + 1;
            }
          }

          setState(() {
            vendorTypeCounts = counts;
            print('Vendor type counts: $vendorTypeCounts');
          });
        }
      }
    } catch (e) {
      print('Error fetching vendor type counts: ${e.toString()}');
    }
  }

  Future<void> _fetchVendors() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Choose the appropriate endpoint based on current view
      String endpoint;
      if (_currentView == 'all') {
        endpoint = 'superadmin/get_all_vendors';
      } else if (_currentView == 'verified') {
        endpoint = 'superadmin/get_verified_vendors';
      } else if (_currentView == 'rejected') {
        endpoint =
            'superadmin/get_rejected_vendors'; // new endpoint for rejected vendors
      } else {
        endpoint = 'superadmin/get_vendors'; // unverified vendors
      }

      var url = Uri.parse('${APIConstants.baseUrl}$endpoint');
      print('Fetching from: $url');

      final response = await http.get(url);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          setState(() {
            vendors = responseData['data'];
            print('Fetched ${vendors.length} vendors');
            // Debug print to see what fields each vendor has
            if (vendors.isNotEmpty) {
              print('First vendor fields: ${vendors[0].keys.toList()}');
              print('First vendor: ${vendors[0]}');
            }
            isLoading = false;
          });
        } else {
          print('No data found');
          setState(() {
            vendors = [];
            isLoading = false;
            errorMessage = 'No data found';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to fetch vendors: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error fetching vendors: ${e.toString()}');
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // Add these variables to store email lists
  List<String> verifiedEmails = [];
  List<String> unverifiedEmails = [];

  // Update the _fetchUserStatistics method
  Future<void> _fetchUserStatistics() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final allUsers = await Api.getAllUsers();
      final verifiedUsersList = allUsers.where((user) => 
        user['status'] == 'verified' || 
        user['isVerified'] == true || 
        user['isVerified'] == 'true' || 
        user['isVerified'] == 1
      ).toList();
      
      final unverifiedUsersList = allUsers.where((user) => 
        user['status'] != 'verified' && 
        user['isVerified'] != true && 
        user['isVerified'] != 'true' && 
        user['isVerified'] != 1
      ).toList();

      setState(() {
        totalUsers = allUsers.length;
        verifiedUsers = verifiedUsersList.length;
        unverifiedUsers = unverifiedUsersList.length;
        
        verifiedEmails = verifiedUsersList
            .map((user) => user['email'].toString())
            .toList();
        unverifiedEmails = unverifiedUsersList
            .map((user) => user['email'].toString())
            .toList();
            
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
      print('Error fetching user statistics: $e');
    }
  }

  void _changeView(String view) {
    setState(() {
      _currentView = view;
    });
    Navigator.pop(context); // Close the drawer

    print("naya   error khaxa view ma");
    print(view);

    if (view == 'dashboard') {
      _fetchVendorTypeCounts();
    } else if (view == 'users') {
      _fetchUserStatistics();
    } else {
      _fetchVendors();
    }
  }

  Future<void> _verifyVendor(String vendorId) async {
    try {
      final response = await http.put(
        Uri.parse('${APIConstants.baseUrl}superadmin/verify_vendor/$vendorId'),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vendor verified successfully')),
        );
        _fetchVendors(); // Refresh the vendor list
      } else {
        print('Failed to verify vendor: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify vendor')),
        );
      }
    } catch (e) {
      print('Error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Add this method after _verifyVendor
  Future<void> _rejectVendor(String vendorId) async {
    try {
      final response = await http.put(
        Uri.parse('${APIConstants.baseUrl}superadmin/reject_vendor/$vendorId'),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vendor rejected successfully')),
        );
        _fetchVendors(); // Refresh the vendor list
      } else {
        print('Failed to reject vendor: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject vendor')),
        );
      }
    } catch (e) {
      print('Error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _signOut() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  // Filter vendors based on verification status
  List<dynamic> get filteredVendors {
    // We're already fetching from the correct endpoints, so we can just return the vendors
    return vendors;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentView == 'all'
            ? "Admin Dashboard"
            : _currentView == 'verified'
                ? "Verified Vendors"
                : _currentView == 'rejected'
                    ? "Rejected Vendors"
                    : _currentView == 'dashboard'
                        ? "Vendor Statistics"
                        : _currentView == 'users'
                            ? "User Details"
                            : "Unverified Vendors"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (_currentView == 'dashboard') {
                _fetchVendorTypeCounts();
              } else if (_currentView == 'users') {
                _fetchUserStatistics();
              } else {
                _fetchVendors();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                'Admin Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('User Statistics'),
              selected: _currentView == 'users',
              onTap: () => _changeView('users'),
            ),
            ListTile(
              leading: Icon(Icons.pie_chart),
              title: Text('Vendor Statistics'),
              selected: _currentView == 'dashboard',
              onTap: () => _changeView('dashboard'),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('All Vendors'),
              selected: _currentView == 'all',
              onTap: () => _changeView('all'),
            ),
            ListTile(
              leading: Icon(Icons.verified),
              title: Text('Verified Vendors'),
              selected: _currentView == 'verified',
              onTap: () => _changeView('verified'),
            ),
            ListTile(
              leading: Icon(Icons.pending),
              title: Text('Unverified Vendors'),
              selected: _currentView == 'unverified',
              onTap: () => _changeView('unverified'),
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Rejected Vendors'),
              selected: _currentView == 'rejected',
              onTap: () => _changeView('rejected'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign Out'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: _currentView == 'dashboard'
          ? _buildVendorDashboardView()
          : _currentView == 'users'
              ? _buildUserDashboardView()
              : isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage))
                      : filteredVendors.isEmpty
                          ? Center(
                              child: Text('No ${_currentView} vendors found'))
                          : ListView.builder(
                              itemCount: filteredVendors.length,
                              // Update the ListView.builder to include a reject button
                              itemBuilder: (context, index) {
                                final vendor = filteredVendors[index];
                                bool isVerified =
                                    vendor['status'] == 'verified' ||
                                        vendor['isVerified'] == true ||
                                        vendor['isVerified'] == 'true' ||
                                        vendor['isVerified'] == 1;
                                bool isRejected =
                                    vendor['status'] == 'rejected';

                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    title: Text(
                                      vendor['vendorName'] ?? 'Unknown Vendor',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(vendor['email'] ?? 'No email'),
                                        SizedBox(height: 4),
                                        Text(
                                          isVerified
                                              ? 'Verified'
                                              : isRejected
                                                  ? 'Rejected'
                                                  : 'Not Verified',
                                          style: TextStyle(
                                            color: isVerified
                                                ? Colors.green
                                                : isRejected
                                                    ? Colors.red
                                                    : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isVerified && !isRejected)
                                          ElevatedButton(
                                            onPressed: () {
                                              _verifyVendor(vendor['_id']);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                            ),
                                            child: Text("Verify"),
                                          ),
                                        if (!isVerified && !isRejected)
                                          SizedBox(width: 8),
                                        if (!isVerified && !isRejected)
                                          ElevatedButton(
                                            onPressed: () {
                                              _rejectVendor(vendor['_id']);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: Text("Reject"),
                                          ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            vendorJWT(vendor);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VendorDetailsPage(
                                                  vendor: vendor,
                                                  token: widget.token,
                                                ),
                                              ),
                                            ).then((_) => _fetchVendors());
                                          },
                                          child: Text("Details"),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
    );
  }

  // Add this method to build the dashboard view
  Widget _buildUserDashboardView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          // Summary card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Users: $totalUsers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Active Users: ${verifiedUsers + unverifiedUsers}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Users by Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          // Status cards
          _buildUserTypeCard(
            'Verified Users',
            verifiedUsers,
            Colors.green,
            Icons.verified_user,
          ),
          _buildUserTypeCard(
            'Unverified Users',
            unverifiedUsers,
            Colors.orange,
            Icons.pending,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard(String type, int count, Color color, IconData icon) {
      return Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          title: Text(
            type,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text('$count users'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(type),
                  content: Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: type.contains('Verified') ? verifiedEmails.length : unverifiedEmails.length,
                      itemBuilder: (context, index) {
                        final email = type.contains('Verified') 
                            ? verifiedEmails[index] 
                            : unverifiedEmails[index];
                        return ListTile(
                          leading: Icon(
                            type.contains('Verified') ? Icons.check_circle : Icons.pending,
                            color: color,
                          ),
                          title: Text(email),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    }

  // Rename existing _buildDashboardView to _buildVendorDashboardView
  Widget _buildVendorDashboardView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendor Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          // Summary card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Vendors: ${vendorTypeCounts.values.fold(0, (sum, count) => sum + count)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Categories: ${vendorTypeCounts.keys.where((k) => vendorTypeCounts[k]! > 0).length}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Vendors by Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          // Category cards
          _buildVendorTypeCard('Venue', vendorTypeCounts['venue'] ?? 0,
              Colors.blue, Icons.location_on),
          _buildVendorTypeCard(
              'Decoration',
              vendorTypeCounts['decoration'] ?? 0,
              Colors.purple,
              Icons.celebration),
          _buildVendorTypeCard(
              'Photography',
              vendorTypeCounts['photography'] ?? 0,
              Colors.amber,
              Icons.camera_alt),
          _buildVendorTypeCard('Catering', vendorTypeCounts['catering'] ?? 0,
              Colors.green, Icons.restaurant),
          _buildVendorTypeCard('Music', vendorTypeCounts['music'] ?? 0,
              Colors.red, Icons.music_note),
          _buildVendorTypeCard(
              'Transportation',
              vendorTypeCounts['transportation'] ?? 0,
              Colors.indigo,
              Icons.directions_car),
          _buildVendorTypeCard('Other', vendorTypeCounts['other'] ?? 0,
              Colors.grey, Icons.more_horiz),
        ],
      ),
    );
  }

  // Enhanced vendor type card with icons
  Widget _buildVendorTypeCard(
      String type, int count, Color color, IconData icon) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('$count vendors'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () async {
          try {
            var url =
                Uri.parse('${APIConstants.baseUrl}inventory/get_all_inventory');
            final response = await http.get(url);

            if (response.statusCode == 200) {
              final responseData = json.decode(response.body);
              if (responseData['data'] != null) {
                List<dynamic> filteredVendors = [];

                switch (type.toLowerCase()) {
                  case 'venue':
                    filteredVendors = responseData['data']['venues'] ?? [];
                    break;
                  case 'decoration':
                    filteredVendors = responseData['data']['decorators'] ?? [];
                    break;
                  case 'photography':
                    filteredVendors =
                        responseData['data']['photographers'] ?? [];
                    break;
                  case 'catering':
                    filteredVendors =
                        responseData['data']['foodServices'] ?? [];
                    break;
                  case 'music':
                    filteredVendors = responseData['data']['musicians'] ?? [];
                    break;
                  case 'transportation':
                    filteredVendors =
                        responseData['data']['transportation'] ?? [];
                    break;
                  default:
                    filteredVendors = responseData['data']['others'] ?? [];
                }

                print(
                    'Filtered Vendors for ${type}: ${filteredVendors.length}');

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorListPage(
                      vendors: filteredVendors,
                      category: type,
                      token: widget.token,
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            print('Error fetching vendors: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load vendors')),
            );
          }
        },
      ),
    );
  }

  Widget _buildUserStatRow(
      String label, int count, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  vendorJWT(vendor) {
    // prefs.setString("CurrentVendor", );
  }
}
