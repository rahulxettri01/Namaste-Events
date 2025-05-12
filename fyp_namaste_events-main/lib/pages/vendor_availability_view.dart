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
      body: ListView.builder(
        itemCount: availabilitySlots.length,
        itemBuilder: (context, index) {
          final slot = availabilitySlots[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                '${DateFormat('MMM dd, yyyy').format(DateTime.parse(slot['startDate']))} - '
                '${DateFormat('MMM dd, yyyy').format(DateTime.parse(slot['endDate']))}',
              ),
              subtitle: Text('Status: ${slot['status']}'),
              trailing: ElevatedButton(
                onPressed: slot['status'] == 'Available'
                    ? () {
                        // Add booking logic here
                      }
                    : null,
                child: Text('Book'),
              ),
            ),
          );
        },
      ),
    );
  }
}
