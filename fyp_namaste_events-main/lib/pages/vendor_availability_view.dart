  import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VendorAvailabilityView extends StatelessWidget {
  final List<dynamic> availabilitySlots;
  final Map<String, dynamic> vendorData;

  const VendorAvailabilityView({
    Key? key,
    required this.availabilitySlots,
    required this.vendorData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Slots'),
      ),
      body: availabilitySlots.isEmpty
          ? Center(
              child: Text(
                'No available slots found',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: availabilitySlots.length,
              itemBuilder: (context, index) {
                final slot = availabilitySlots[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      '${DateFormat('MMM dd, yyyy').format(DateTime.parse(slot['startDate']))} - '
                      '${DateFormat('MMM dd, yyyy').format(DateTime.parse(slot['endDate']))}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text('Status: ${slot['status']}'),
                        Text('Category: ${slot['category']}'),
                        Text('Vendor: ${vendorData['name'] ?? 'Unknown Vendor'}'),
                      ],
                    ),
                    trailing: Container(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: slot['status'] == 'Available'
                            ? () {
                                // Show booking confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Confirm Booking'),
                                    content: Text(
                                      'Would you like to book this slot?\n\n'
                                      'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(slot['startDate']))} - '
                                      '${DateFormat('MMM dd, yyyy').format(DateTime.parse(slot['endDate']))}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Add booking logic here
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Booking request sent!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                        child: Text('Confirm'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: slot['status'] == 'Available' 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                        child: Text(
                          slot['status'] == 'Available' ? 'Book' : 'Unavailable',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
