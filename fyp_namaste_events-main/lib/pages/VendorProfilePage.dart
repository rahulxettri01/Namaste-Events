import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';
import 'package:fyp_namaste_events/services/Api/api_authentication.dart';
import 'dart:convert';
import 'dart:io';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class VendorProfilePage extends StatefulWidget {
  final String vendorId;
  final String token;

  const VendorProfilePage({
    required this.vendorId,
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  _VendorProfilePageState createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true;
  String _errorMessage = '';
  String _vendorType = 'Photography';
  String _status = 'Unknown';
  late Map<String, dynamic> _jwtData;
  Map<String, dynamic> _vendorData = {};
  
  // Add variables for profile image handling
  File? _profileImage;
  bool _isUploadingImage = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _jwtData = JwtDecoder.decode(widget.token);
    _fetchVendorProfile();
    _fetchInventoryData();
  }

  // Add method to pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        
        // Upload the image immediately after picking
        _uploadProfileImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  // Add method to upload profile image
  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${APIConstants.baseUrl}vendor/upload-profile-image'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      // Add vendor ID as a field
      request.fields['vendorId'] = widget.vendorId;

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', _profileImage!.path),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      debugPrint("Profile image upload response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Log the entire response to see its structure
        debugPrint("Upload response structure: ${jsonEncode(jsonResponse)}");
        
        // Try different possible field names for the image URL
        final imageUrl = jsonResponse['imageUrl'] ?? 
                         jsonResponse['profileImageUrl'] ?? 
                         jsonResponse['url'] ?? 
                         jsonResponse['image'] ??
                         jsonResponse['profileImage'];
                         
        setState(() {
          _isUploadingImage = false;
          _profileImageUrl = imageUrl;
          
          // If URL doesn't start with http, add the base URL
          if (_profileImageUrl != null && !_profileImageUrl!.startsWith('http')) {
            _profileImageUrl = '${APIConstants.baseUrl}uploads/vendor/profiles/$_profileImageUrl';
          }
          
          // Update vendor data with new image URL
          if (_vendorData.isNotEmpty) {
            _vendorData['profileImage'] = _profileImageUrl;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile image uploaded successfully!")),
        );
      } else {
        setState(() {
          _isUploadingImage = false;
          _errorMessage = 'Failed to upload image: ${response.reasonPhrase}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _errorMessage = 'Error uploading image: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  // Add method to show image source selection dialog
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: const [
                        Icon(Icons.photo_library, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: const [
                        Icon(Icons.photo_camera, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Existing method to fetch inventory data
  Future<void> _fetchInventoryData() async {
    try {
      final inventoryList = await Api.getInventory();
      debugPrint("Inventory list length: ${inventoryList.length}");
      
      if (inventoryList.isNotEmpty) {
        // Debug the first inventory item to see its structure
        debugPrint("First inventory item structure: ${json.encode(inventoryList[0])}");
        
        // The vendorId might be stored with a different key or format
        // Try different approaches to match the vendor
        final vendorInventory = inventoryList.where((item) {
          // Check if vendorId exists and matches in different formats
          return (item['vendorId']?.toString() == widget.vendorId) || 
                 (item['vendor_id']?.toString() == widget.vendorId) ||
                 (item['vendor']?.toString() == widget.vendorId) ||
                 (item['vendorID']?.toString() == widget.vendorId);
        }).toList();
        
        debugPrint("Vendor inventory items found: ${vendorInventory.length}");
        debugPrint("Vendor ID: ${widget.vendorId}");
        
        if (vendorInventory.isNotEmpty) {
          debugPrint("First inventory item: ${json.encode(vendorInventory[0])}");
          setState(() {
            // Check for address in different possible field names
            final address = vendorInventory[0]['address'] ?? 
                           vendorInventory[0]['location'] ?? 
                           vendorInventory[0]['venue_address'] ??
                           vendorInventory[0]['venueAddress'];
                           
            if (address != null) {
              debugPrint("Found address: $address");
              _addressController.text = address;
              if (_vendorData.isNotEmpty) {
                _vendorData['address'] = address;
              }
            } else {
              debugPrint("Address is null in inventory item");
            }
          });
        } else {
          // If no match found, try to get address from the first inventory item
          debugPrint("No matching inventory found, using first item");
          final firstItem = inventoryList[0];
          final address = firstItem['address'] ?? 
                         firstItem['location'] ?? 
                         firstItem['venue_address'] ??
                         firstItem['venueAddress'];
                         
          if (address != null) {
            debugPrint("Using address from first item: $address");
            setState(() {
              _addressController.text = address;
              if (_vendorData.isNotEmpty) {
                _vendorData['address'] = address;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching inventory data: ${e.toString()}");
    }
  }

  // Modified method to fetch vendor profile to include profile image
  Future<void> _fetchVendorProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Log the token and vendor ID for debugging
      debugPrint("Using token: ${widget.token.substring(0, 20)}...");
      debugPrint("Fetching profile for vendor ID: ${widget.vendorId}");
      
      final response = await Api.getVendorProfile(widget.vendorId);
      
      // Log the entire response to see its structure
      debugPrint("Vendor profile response: ${jsonEncode(response)}");
      
      if (response['success'] == true) {
        final vendor = response['vendor'] ?? {};
        
        // Log the entire vendor object to see all available fields
        debugPrint("Vendor data: ${jsonEncode(vendor)}");
        
        // Check for profile image in different possible field names
        final profileImage = vendor['profileImageUrl'] ?? 
                            vendor['profileImage'] ?? 
                            vendor['profile_image'] ?? 
                            vendor['profile_image_url'] ??
                            vendor['image'] ??
                            vendor['imageUrl'] ??
                            vendor['img'] ??
                            vendor['imgUrl'];
        
        debugPrint("Profile image from API (all possible fields): $profileImage");
        
        // If no profile image found in vendor data, try to use data from JWT
        if (profileImage == null) {
          debugPrint("No profile image found in vendor data, checking JWT data");
          // Check if there's any profile image info in the JWT data
          final jwtProfileImage = _jwtData['profileImage'] ?? 
                                 _jwtData['profileImageUrl'] ?? 
                                 _jwtData['image'];
          
          if (jwtProfileImage != null) {
            debugPrint("Found profile image in JWT: $jwtProfileImage");
          }
        }
        
        setState(() {
          _vendorData = vendor; // Store the entire vendor data
          _nameController.text = vendor['vendorName'] ?? _jwtData['email'] ?? '';
          _emailController.text = vendor['email'] ?? _jwtData['email'] ?? '';
          _phoneController.text = vendor['phone'] ?? '';
          _addressController.text = vendor['address'] ?? '';
          _businessNameController.text = vendor['businessName'] ?? '';
          _vendorType = vendor['category'] ?? _jwtData['category'] ?? 'Photography';
          _status = vendor['status'] ?? _jwtData['status'] ?? 'Unknown';
          
          // Update to use the found profile image
          _profileImageUrl = profileImage;
          
          // If profile image exists but doesn't have the full URL, add the base URL
          if (_profileImageUrl != null && !_profileImageUrl!.startsWith('http')) {
            _profileImageUrl = '${APIConstants.baseUrl}uploads/vendor/profiles/$_profileImageUrl';
          }
          
          debugPrint("Set profile image URL: $_profileImageUrl");
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'Failed to load profile';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      debugPrint("Error fetching vendor profile: ${e.toString()}");
    }
  }

  // Existing method to update profile
  Future<void> _updateProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final vendorData = {
        'vendorName': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'businessName': _businessNameController.text,
      };

      final response = await Api.updateVendorProfile(
        vendorId: widget.vendorId,
        vendorData: vendorData,
      );

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _isEditing = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = response['message'] ?? 'Failed to update profile';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                await _updateProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Center(
                    child: Column(
                      children: [
                        // Modified profile image section with upload functionality
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _isEditing ? _showImageSourceDialog : null,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!) as ImageProvider
                                    : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                        ? NetworkImage(_profileImageUrl!) 
                                        : null,
                                child: (_profileImageUrl == null || _profileImageUrl!.isEmpty) && _profileImage == null
                                    ? Icon(Icons.person, size: 70, color: Colors.black)
                                    : null,
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: _isUploadingImage
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _vendorData['vendorName'] ?? _jwtData['email'] ?? 'Unknown Vendor',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Status: ${_vendorData['status'] ?? _jwtData['status'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  // Rest of your existing UI...
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          label: 'Name',
                          icon: Icons.person,
                          controller: _nameController,
                          enabled: _isEditing,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: 'Email',
                          icon: Icons.email,
                          controller: _emailController,
                          enabled: false,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: 'Phone',
                          icon: Icons.phone,
                          controller: _phoneController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: 'Address',
                          icon: Icons.location_on,
                          controller: _addressController,
                          enabled: _isEditing,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: 'Vendor Type',
                          icon: Icons.category,
                          controller: TextEditingController(text: _vendorData['vendorType'] ?? 'Photography'),
                          enabled: false,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  if (!_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Edit Profile",
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // Existing helper method for text fields
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }
}