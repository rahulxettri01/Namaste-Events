import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/services/Api/api_authentication.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';

class VendorDetailsPage extends StatefulWidget {
  final Map<String, dynamic> vendor;
  final String token;

  const VendorDetailsPage({required this.vendor, required this.token, Key? key})
      : super(key: key);

  @override
  _VendorDetailsPageState createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends State<VendorDetailsPage> {
  bool isLoading = false;
  String errorMessage = '';
  List<dynamic> images = [];

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print("Fetching images...");  
      print("Token: ${widget.token}");
      var url = Uri.parse(
          '${APIConstants.baseUrl}vendor/auth/get_verification_images');
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(
            {"email": widget.vendor['email'], "type": "verification"}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            images = data['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'Failed to fetch images: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _updateVendorStatus(String status) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print(widget.vendor['_id']);
      var url =
          Uri.parse('${APIConstants.baseUrl}vendor/auth/update_vendor_status');
      print(url);
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": status, "id": widget.vendor['_id']}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            widget.vendor['status'] = status;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage =
                'Failed to update vendor status: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.vendor['vendorName']} Details"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          title: Text("Vendor Name"),
                          subtitle: Text(widget.vendor['vendorName']),
                        ),
                        ListTile(
                          title: Text("Email"),
                          subtitle: Text(widget.vendor['email']),
                        ),
                        ListTile(
                          title: Text("Phone"),
                          subtitle: Text(widget.vendor['phone']),
                        ),
                        ListTile(
                          title: Text("Category"),
                          subtitle: Text(widget.vendor['category']),
                        ),
                        ListTile(
                          title: Text("Status"),
                          subtitle: Text(widget.vendor['status']),
                        ),
                        // Display verification documents
                        if (images.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Verification Documents",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...images.map((image) {
                                print(image);
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Document Type: ${image['type'] ?? 'Verification Document'}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Image.network(
                                        '${APIConstants.baseUrl}${image['filePath']}/${image['fileName']}',
                                        height: 300,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 300,
                                            width: double.infinity,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print("Error loading image: $error");
                                          print(
                                              "Image URL: ${APIConstants.baseUrl}uploads/vendor/${image['fileName']}");
                                          return Container(
                                            height: 300,
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image,
                                                    size: 50,
                                                    color: Colors.grey[600]),
                                                SizedBox(height: 10),
                                                Text('Failed to load image',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[700])),
                                                SizedBox(height: 5),
                                                Text(
                                                    error.toString().substring(
                                                        0,
                                                        error
                                                                    .toString()
                                                                    .length >
                                                                50
                                                            ? 50
                                                            : error
                                                                .toString()
                                                                .length),
                                                    style: TextStyle(
                                                        color: Colors.red[300],
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            "Source: ${image['srcFrom'] ?? widget.vendor['email']}"),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        // Add more fields as needed
                      ],
                    ),
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _updateVendorStatus('verified'),
                        child: Text("Verify"),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateVendorStatus('rejected'),
                        child: Text("Reject"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
