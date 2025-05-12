import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/utils/theme/custom_themes/text_theme.dart';
// Make sure these packages are added to your pubspec.yaml

import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class VendorDetailPage extends StatefulWidget {
  final dynamic vendorData;
  final String vendorType;

  const VendorDetailPage({
    Key? key,
    required this.vendorData,
    required this.vendorType,
  }) : super(key: key);

  @override
  _VendorDetailPageState createState() => _VendorDetailPageState();
}

class _VendorDetailPageState extends State<VendorDetailPage> {
  int _currentImageIndex = 0;
  // Remove this line:
  // final CarouselController _carouselController = CarouselController();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).brightness == Brightness.dark
        ? TTextTheme.darkTextTheme
        : TTextTheme.lightTextTheme;

    // Get vendor name based on type
    String vendorName = '';
    if (widget.vendorType == 'venue') {
      vendorName = widget.vendorData['venueName'] ?? 'Venue';
    } else if (widget.vendorType == 'photographer') {
      vendorName = widget.vendorData['photographyName'] ?? 'Photographer';
    } else if (widget.vendorType == 'decorator') {
      vendorName = widget.vendorData['decoratorName'] ?? 'Decorator';
    }

    // Get vendor description
    String description = widget.vendorData['description'] ?? 'No description available';
    
    // Get vendor price
    String price = widget.vendorData['price'] != null 
        ? 'Rs. ${widget.vendorData['price']}' 
        : 'Price not available';
    
    // Get vendor address
    String address = widget.vendorData['address'] ?? 'Address not available';
    
    // Get vendor images - handle different image formats
    List<dynamic> images = [];
    if (widget.vendorData['images'] != null) {
      if (widget.vendorData['images'] is List) {
        images = widget.vendorData['images'];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(vendorName, style: textTheme.headlineSmall),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            if (images.isNotEmpty)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  CarouselSlider(
                    // Remove the controller parameter for now
                    options: CarouselOptions(
                      height: 250,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                    items: images.map((image) {
                      String imageUrl = '';
                      if (image is Map) {
                        imageUrl = image['fullUrl'] ?? '';
                      } else if (image is String) {
                        imageUrl = image;
                      }
                      
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            child: imageUrl.isNotEmpty 
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print("Image error: $error");
                                    return Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image_not_supported, size: 40),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image_not_supported, size: 40),
                                ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedSmoothIndicator(
                      activeIndex: _currentImageIndex,
                      count: images.length,
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Theme.of(context).primaryColor,
                        dotColor: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: Icon(
                  widget.vendorType == 'venue'
                      ? Icons.home
                      : widget.vendorType == 'photographer'
                          ? Icons.camera_alt
                          : Icons.celebration,
                  size: 80,
                  color: Colors.grey.shade700,
                ),
              ),
              
            // Vendor details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor name
                  Text(
                    vendorName,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  // Price
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(price, style: textTheme.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(address, style: textTheme.bodyLarge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text('Description', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Book Now button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Show booking confirmation dialog
                        _showBookingDialog(context, vendorName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Book Now',
                        style: textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showBookingDialog(BuildContext context, String vendorName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Book ${widget.vendorType.capitalize()}'),
          content: Text('Would you like to book $vendorName?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Handle booking logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking request sent for $vendorName'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}