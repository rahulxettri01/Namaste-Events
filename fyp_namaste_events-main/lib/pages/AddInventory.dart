import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp_namaste_events/services/Api/api_authentication.dart';

class AddInventoryPage extends StatefulWidget {
  final String token;
  const AddInventoryPage({required this.token, Key? key}) : super(key: key);

  @override
  _AddInventoryPageState createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  List<File> selectedFiles = [];
  List<String> selectedFileNames = [];
  bool isUploading = false;
  String uploadStatus = '';

  // Function to pick multiple files
  Future<void> pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        selectedFiles = result.files.map((file) => File(file.path!)).toList();
        selectedFileNames = result.files.map((file) => file.name).toList();
      });
    }
  }

  // Function to upload inventory images and add inventory details
  Future<void> _addInventory() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _addressController.text.isEmpty) {
      setState(() {
        errorMessage = "Please fill in all fields.";
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage!)));
      return;
    } else if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select files before uploading")),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadStatus = 'Uploading...';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${APIConstants.baseUrl}api/add_inventory'),
      );

      // Add token to headers
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      // Add inventory metadata if needed
      request.fields['type'] = 'inventory';
      request.fields['inventoryName'] = _nameController.text;
      request.fields['address'] = _addressController.text;
      request.fields['price'] = _priceController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['accommodation'] = jsonEncode(accommodations);

      // Add all files to the request
      for (var file in selectedFiles) {
        request.files
            .add(await http.MultipartFile.fromPath('files', file.path));
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("Response : $response ");
      print("Response Body: $responseBody");
      if (response.statusCode == 200) {
        setState(() {
          isUploading = false;
          uploadStatus = '';
          selectedFiles = [];
          selectedFileNames = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inventory added successfully!")),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        setState(() {
          isUploading = false;
          uploadStatus = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to add inventory: ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      setState(() {
        isUploading = false;
        uploadStatus = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding inventory: $e")),
      );
    }
  }

  // File Picker UI Widget
  Widget filePickerButton() {
    return GestureDetector(
      onTap: pickFiles,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Inventory Images",
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selectedFileNames
                  .map((fileName) => Text(fileName,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87)))
                  .toList(),
            ),
            const Icon(Icons.upload_file, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  late String userStatus;
  late String vendorType;
  late SharedPreferences prefs;
  String? errorMessage = '';
  List<Map<String, String>> accommodations = [];

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userStatus = jwtDecodedToken['status'];
    vendorType = jwtDecodedToken['category'];
  }

  void _addAccommodationField() {
    setState(() {
      accommodations.add({"type": "", "details": ""});
    });
  }

  void _updateAccommodation(int index, String field, String value) {
    setState(() {
      accommodations[index][field] = value;
    });
  }

  void _removeAccommodation(int index) {
    setState(() {
      accommodations.removeAt(index);
    });
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Inventory")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: "Inventory Name", border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: "Description", border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Price (\Rs)", border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                    labelText: "Address", border: OutlineInputBorder()),
              ),
              SizedBox(height: 20),
              Text("Accommodation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Column(
                children: accommodations.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) =>
                              _updateAccommodation(index, "type", value),
                          decoration: InputDecoration(
                              labelText: "Type", border: OutlineInputBorder()),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (value) =>
                              _updateAccommodation(index, "details", value),
                          decoration: InputDecoration(
                              labelText: "Details",
                              border: OutlineInputBorder()),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeAccommodation(index),
                      )
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.blue, size: 30),
                  onPressed: _addAccommodationField,
                ),
              ),
              SizedBox(height: 20),
              // File Picker Button
              filePickerButton(),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addInventory,
                  child: Text(isUploading ? "Uploading..." : "Add Inventory",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
