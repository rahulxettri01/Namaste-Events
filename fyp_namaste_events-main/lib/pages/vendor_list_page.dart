import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/vendor_availability_view.dart';
import 'package:fyp_namaste_events/pages/vendor_detail_page.dart';
import '../services/Api/api_vendor_availability.dart';

// for admin
class VendorListPage extends StatelessWidget {
  final List<dynamic> vendors;
  final String category;

  const VendorListPage({
    Key? key,
    required this.vendors,
    required this.category,
  }) : super(key: key);

  Future<void> _checkAvailability(
      BuildContext context, Map<String, dynamic> vendor) async {
    try {
      final vendorId = vendor['_id']?.toString();
      if (vendorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vendor ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final availableSlots =
          await ApiVendorAvailability.fetchVendorAvailabilityById(
        vendorId,
      );

      if (availableSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No availability slots found for this vendor'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show availability view
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VendorAvailabilityView(
            availabilitySlots: availableSlots,
            vendorData: vendor,
          ),
        ),
      );
    } catch (e) {
      print('Error checking availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching availability: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(
                          vendor['images'] != null &&
                                  vendor['images'].isNotEmpty
                              ? vendor['images'][0]['fullUrl']
                              : 'https://via.placeholder.com/150',
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    _getVendorName(vendor),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        vendor['address'] ?? 'No address provided',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getPriceText(vendor),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VendorDetailPage(
                                vendorData: vendor,
                                vendorType: _getVendorType(),
                              ),
                            ),
                          );
                        },
                        child: Text('View Details'),
                      ),
                      ElevatedButton(
                        onPressed: () => _checkAvailability(context, vendor),
                        style: ElevatedButton.styleFrom(
                            // primary: Colors.green,
                            ),
                        child: Text('Book Now'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getVendorName(Map<String, dynamic> vendor) {
    switch (category.toLowerCase()) {
      case 'venue':
        return vendor['venueName'] ?? 'Unknown Venue';
      case 'photographer':
        return vendor['photographyName'] ?? 'Unknown Photographer';
      case 'food':
        return vendor['foodServiceName'] ?? 'Unknown Food Service';
      case 'decorator':
        return vendor['decoratorName'] ?? 'Unknown Decorator';
      default:
        return 'Unknown Vendor';
    }
  }

  String _getPriceText(Map<String, dynamic> vendor) {
    switch (category.toLowerCase()) {
      case 'venue':
        return 'Rs ${vendor['price'] ?? '0'} per plate';
      case 'photographer':
        return 'Rs ${vendor['price'] ?? '0'} per event';
      case 'food':
        return 'Rs ${vendor['price'] ?? '0'} per plate';
      case 'decorator':
        return 'Rs ${vendor['price'] ?? '0'} per event';
      default:
        return 'Rs ${vendor['price'] ?? '0'}';
    }
  }

  String _getVendorType() {
    switch (category.toLowerCase()) {
      case 'venue':
        return 'venue';
      case 'photographer':
        return 'photographer';
      case 'food':
        return 'food';
      case 'decorator':
        return 'decorator';
      default:
        return 'vendor';
    }
  }
}
