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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            Icon(Icons.upload_file, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Inventory Images",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 5),
                  selectedFileNames.isEmpty
                      ? Text(
                          "No files selected",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: selectedFileNames
                              .map((fileName) => Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      fileName,
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black87),
                                    ),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),
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
              _entryField("Inventory Name", _nameController),
              SizedBox(height: 15),
              _entryField("Description", _descriptionController, maxLines: 3),
              SizedBox(height: 15),
              _entryField("Price", _priceController, keyboardType: TextInputType.number),
              SizedBox(height: 15),
              _entryField("Address", _addressController),
              SizedBox(height: 20),
              Text("Accommodation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Column(
                children: accommodations.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _accommodationField("Type", index, "type"),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _accommodationField("Details", index, "details"),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeAccommodation(index),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.black, size: 30),
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
                  onPressed: isUploading ? null : _addInventory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    isUploading ? "Uploading..." : "Add Inventory",
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom text field widget matching SignUpPage style
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
                    title == "Inventory Name" 
                        ? Icons.inventory
                        : title == "Description"
                            ? Icons.description
                            : title == "Address"
                                ? Icons.location_on
                                : Icons.text_fields,
                    color: Colors.grey,
                  ),
          ),
        ),
      ],
    );
  }

  // Custom accommodation field widget
  Widget _accommodationField(String label, int index, String field) {
    return TextField(
      onChanged: (value) => _updateAccommodation(index, field, value),
      decoration: InputDecoration(
        labelText: label,
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
        prefixIcon: Icon(
          field == "type" ? Icons.category : Icons.info_outline,
          color: Colors.grey,
        ),
      ),
    );
  }
}
