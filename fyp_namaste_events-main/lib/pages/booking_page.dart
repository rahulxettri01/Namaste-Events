// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class BookingPage extends StatefulWidget {
//   const BookingPage({super.key});
//
//   @override
//   _BookingPageState createState() => _BookingPageState();
// }
//
// class _BookingPageState extends State<BookingPage> {
//   DateTime? selectedDate;
//   TimeOfDay? selectedTime;
//   bool isLoading = false;
//   List<String> availableSlots = [];
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         selectedTime = null;  // Reset time when date changes
//       });
//       await _fetchAvailableSlots();
//     }
//   }
//
//   Future<void> _selectTime(BuildContext context) async {
//     if (availableSlots.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No available slots for the selected date')),
//       );
//       return;
//     }
//
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//
//     if (picked != null && picked != selectedTime) {
//       final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
//       if (availableSlots.contains(formattedTime)) {
//         setState(() {
//           selectedTime = picked;
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Selected time slot is not available')),
//         );
//       }
//     }
//   }
//
//   Future<void> _fetchAvailableSlots() async {
//     if (selectedDate == null) return;
//
//     setState(() {
//       isLoading = true;
//     });
//
//     final response = await http.get(
//       Uri.parse('https://your-backend-url.com/available-slots?artistId=123&date=${selectedDate!.toIso8601String().split('T')[0]}'),
//     );
//
//     setState(() {
//       isLoading = false;
//     });
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       setState(() {
//         availableSlots = List<String>.from(data['availableSlots']);
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to fetch available slots')),
//       );
//     }
//   }
//
//   Future<void> _submitBooking() async {
//     if (selectedDate == null || selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please select a date and time')),
//       );
//       return;
//     }
//
//     setState(() {
//       isLoading = true;
//     });
//
//     final response = await http.post(
//       Uri.parse('https://your-backend-url.com/newBooking'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       },
//       body: jsonEncode(<String, dynamic>{
//         'artistId': '123',
//         'customerId': '456',
//         'date': selectedDate!.toIso8601String().split('T')[0],
//         'startTime': '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
//       }),
//     );
//
//     setState(() {
//       isLoading = false;
//     });
//
//     if (response.statusCode == 201) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Booking successful')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to book appointment')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Book Appointment'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Text(
//               'Select Date',
//               style: TextStyle(fontSize: 20),
//             ),
//             SizedBox(height: 8),
//             Row(
//               children: <Widget>[
//                 Expanded(
//                   child: Text(
//                     selectedDate == null
//                         ? 'No date chosen!'
//                         : selectedDate!.toLocal().toString().split(' ')[0],
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _selectDate(context),
//                   child: Text('Choose Date'),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Select Time',
//               style: TextStyle(fontSize: 20),
//             ),
//             SizedBox(height: 8),
//             Row(
//               children: <Widget>[
//                 Expanded(
//                   child: Text(
//                     selectedTime == null
//                         ? 'No time chosen!'
//                         : selectedTime!.format(context),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _selectTime(context),
//                   child: Text('Choose Time'),
//                 ),
//               ],
//             ),
//             SizedBox(height: 40),
//             if (isLoading)
//               Center(child: CircularProgressIndicator())
//             else
//               Center(
//                 child: ElevatedButton(
//                   onPressed: _submitBooking,
//                   child: Text('Submit Booking'),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }