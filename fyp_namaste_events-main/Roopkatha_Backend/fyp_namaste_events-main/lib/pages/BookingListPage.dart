import 'package:flutter/material.dart';

class BookingListPage extends StatelessWidget {
  const BookingListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Add your booking list items here
          Card(
            child: ListTile(
              title: Text('Booking #1'),
              subtitle: Text('Status: Pending'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Handle booking details navigation
              },
            ),
          ),
        ],
      ),
    );
  }
}