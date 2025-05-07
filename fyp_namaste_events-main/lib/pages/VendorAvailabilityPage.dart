import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/Api/api_vendor_availability.dart';

class VendorAvailabilityPage extends StatefulWidget {
  final String vendorId;
  final String vendorType;
  final String token;

  const VendorAvailabilityPage({
    Key? key,
    required this.vendorId,
    required this.vendorType,
    required this.token,
  }) : super(key: key);

  @override
  _VendorAvailabilityPageState createState() => _VendorAvailabilityPageState();
}

class _VendorAvailabilityPageState extends State<VendorAvailabilityPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  List<dynamic> _availableSlots = [];
  bool _isLoading = false;
  late String vendorEmail; // Add this line

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    vendorEmail = jwtDecodedToken['email']; // Store email from token
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoading = true);
    try {
      print("Fetching slots for vendor email: $vendorEmail");
      final slots = await ApiVendorAvailability.getAvailableSlots(
        vendorEmail,
        widget.token,
      );

      if (slots != null) {
        setState(() {
          _availableSlots = slots;
        });
        print("Loaded ${slots.length} availability slots");
      } else {
        print("No slots returned from API");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No availability slots found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Error loading slots: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load availability slots: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update the ListView builder to show more slot details

  Future<void> _createAvailabilitySlot() async {
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date range')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare slot data
      final slotData = {
        'vendorEmail': vendorEmail,
        'startDate': DateFormat('yyyy-MM-dd').format(_rangeStart!),
        'endDate': DateFormat('yyyy-MM-dd').format(_rangeEnd!),
        'category': widget.vendorType.toLowerCase() == 'photography'
            ? 'Photography'
            : widget.vendorType.toLowerCase() == 'venue'
                ? 'Venue'
                : 'Decorator',
        'status': 'Available'
      };

      print('Creating slot with data: ${jsonEncode(slotData)}');

      final success = await ApiVendorAvailability.createSlot(
        widget.token,
        slotData,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Availability slot created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadAvailableSlots(); // Refresh the list
        setState(() {
          _rangeStart = null;
          _rangeEnd = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create availability slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error creating slot: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAvailabilitySlot(Map<String, dynamic> slot) async {
    setState(() => _isLoading = true);
    try {
      final updateData = {
        'startDate': _rangeStart != null
            ? DateFormat('yyyy-MM-dd').format(_rangeStart!)
            : slot['startDate'],
        'endDate': _rangeEnd != null
            ? DateFormat('yyyy-MM-dd').format(_rangeEnd!)
            : slot['endDate'],
        'status': slot['status'] == 'Available' ? 'Booked' : 'Available',
        'category': widget.vendorType
      };

      print('Updating slot with data: ${jsonEncode(updateData)}');

      final success = await ApiVendorAvailability.updateSlot(
        widget.token,
        slot['availabilityID'], // Use availabilityID instead of _id
        updateData,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Availability updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _rangeStart = null;
          _rangeEnd = null;
        });
        await _loadAvailableSlots();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating slot: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Remove the standalone ListTile widget and update the ListView.builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Availability'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rangeSelectionMode: RangeSelectionMode.enforced,
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _rangeStart = null;
                  _rangeEnd = null;
                });
              }
            },
            onRangeSelected: (start, end, focusedDay) {
              setState(() {
                _selectedDay = null;
                _rangeStart = start;
                _rangeEnd = end;
                _focusedDay = focusedDay;
              });
              print(
                  'Range selected: ${start?.toString()} to ${end?.toString()}');
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            // Add calendar styling
            calendarStyle: CalendarStyle(
              // rangeHighlightColor: Color.pink[100],
              rangeStartDecoration: BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
              withinRangeTextStyle: const TextStyle(color: Colors.black),
              selectedTextStyle: const TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(height: 20),
          if (_rangeStart != null && _rangeEnd != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Selected Range: ${DateFormat('MMM dd').format(_rangeStart!)} - ${DateFormat('MMM dd').format(_rangeEnd!)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createAvailabilitySlot,
            child: Text('Create Availability Slot'),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _availableSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _availableSlots[index];
                      return ListTile(
                        title: Text(
                          '${DateFormat('MMM dd').format(DateTime.parse(slot['startDate']))} - ${DateFormat('MMM dd').format(DateTime.parse(slot['endDate']))}',
                        ),
                        subtitle: Text('Status: ${slot['status']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_calendar),
                              color: Colors.blue,
                              onPressed: () {
                                if (_rangeStart != null && _rangeEnd != null) {
                                  _updateAvailabilitySlot(slot);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please select new date range first'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                slot['status'] == 'Available'
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                color: slot['status'] == 'Available'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              onPressed: () => _updateAvailabilitySlot(slot),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
