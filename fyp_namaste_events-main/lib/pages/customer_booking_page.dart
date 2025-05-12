import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/Api/api_vendor_availability.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:khalti/khalti.dart' as khalti_core; // Add prefix here
import '../utils/khalti_config.dart'; // Add this import

class CustomerBookingPage extends StatefulWidget {
  final String vendorId;
  final String vendorEmail;
  final String vendorType;
  final String token;
  final String vendorName;
  final String price;

  const CustomerBookingPage({
    Key? key,
    required this.vendorId,
    required this.vendorEmail,
    required this.vendorType,
    required this.token,
    required this.vendorName,
    required this.price,
  }) : super(key: key);

  @override
  _CustomerBookingPageState createState() => _CustomerBookingPageState();
}

class _CustomerBookingPageState extends State<CustomerBookingPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  List<dynamic> _availableSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("price: ${widget.price}");
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    print("datas haita");
    print(widget.vendorEmail);
    print(widget.vendorId);
    print(widget.vendorType);
    print(widget.vendorName);

    setState(() => _isLoading = true);
    try {
      final slots = await ApiVendorAvailability.getAvailableSlots(
        widget.vendorEmail,
        widget.token,
      );

      if (slots != null) {
        setState(() {
          _availableSlots =
              slots.where((slot) => slot['status'] == 'Available').toList();
        });
      }
      print("slots data at the deningining");
      print(slots);
      // slots['vendorId'] = widget.vendorId;
      // slots['vendorEmail'] = widget.vendorEmail;
      // slots['vendorType'] = widget.vendorType;
      // slots['vendorName'] = widget.vendorName;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load available slots: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.vendorName}'),
      ),
      body: SingleChildScrollView(
        // Add this wrapper
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date range available for booking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : Container(
                            // Add Container with fixed height
                            height: 100,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _availableSlots.length,
                              itemBuilder: (context, index) {
                                final slot = _availableSlots[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    '${DateFormat('MMM dd').format(DateTime.parse(slot['startDate']))} - ${DateFormat('MMM dd').format(DateTime.parse(slot['endDate']))}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
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
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _rangeStart = null;
                  _rangeEnd = null;
                });
              },
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _selectedDay = null;
                  _rangeStart = start;
                  _focusedDay = focusedDay;

                  if (start != null && end != null) {
                    // Get the available date range from slots
                    if (_availableSlots.isNotEmpty) {
                      DateTime firstAvailable =
                          DateTime.parse(_availableSlots.first['startDate']);
                      DateTime lastAvailable =
                          DateTime.parse(_availableSlots.last['endDate']);

                      // Validate start date
                      if (start.isBefore(firstAvailable)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Booking is only available from ${DateFormat('MMM dd').format(firstAvailable)}'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        _rangeStart = firstAvailable;
                        return;
                      }

                      // Validate end date
                      if (end.isAfter(lastAvailable)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Booking is only available till ${DateFormat('MMM dd').format(lastAvailable)}'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        _rangeEnd = lastAvailable;
                        return;
                      }

                      // Existing duration validation
                      final daysDifference = end.difference(start).inDays + 1;
                      if (daysDifference < 1) {
                        _rangeEnd = start;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Minimum booking duration is 1 day'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else if (daysDifference > 5) {
                        _rangeEnd = start.add(Duration(days: 4));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Maximum booking duration is 5 days'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else {
                        _rangeEnd = end;
                      }
                    }
                  }
                });
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                rangeHighlightColor: Colors.green.withOpacity(0.2),
                rangeStartDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                withinRangeTextStyle: const TextStyle(color: Colors.black),
              ),
            ),

            // Replace Expanded with Container
            Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Add this
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Selected Date Range',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (_rangeStart != null && _rangeEnd != null)
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${DateFormat('MMM dd').format(_rangeStart!)} - ${DateFormat('MMM dd').format(_rangeEnd!)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => _showBookingDialog(),
                                child: Text('Proceed with Booking'),
                              ),
                            ],
                          ),
                      ],
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

  void _showBookingDialog() {
    final TextEditingController guestsController = TextEditingController();
    int basePrice = int.parse(widget.price);
    int totalPrice = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Booking Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Start Date: ${DateFormat('MMM dd, yyyy').format(_rangeStart!)}'),
                    SizedBox(height: 10),
                    Text(
                        'End Date: ${DateFormat('MMM dd, yyyy').format(_rangeEnd!)}'),
                    SizedBox(height: 10),
                    Text('Base Price: Rs ${basePrice.toString()}'),
                    SizedBox(height: 15),
                    TextField(
                      controller: guestsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Number of Guests (minimum 25)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          int guests = int.tryParse(value) ?? 0;
                          totalPrice = guests * basePrice;
                        });
                      },
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Total Price: Rs ${totalPrice.toString()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final bookingDetails =
                        _processBookingDetails(guestsController.text);
                    if (bookingDetails != null) {
                      Navigator.pop(context);
                      _confirmBooking(bookingDetails);
                    }
                  },
                  child: Text('Proceed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmBooking(Map<String, dynamic> slot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Booking'),
          content: Text('Would you like to book this slot?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processBooking(slot);
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processBooking(Map<String, dynamic> slot) async {
    setState(() => _isLoading = true);
    try {
      final amountInPaisa = (slot['totalPrice'] * 100).toInt();

      final config = KhaltiConfig.getPaymentConfig(
        amount: amountInPaisa,
        productIdentity: 'booking-${DateTime.now().millisecondsSinceEpoch}',
        productName: '${widget.vendorType} Booking - ${widget.vendorName}',
      );

      await KhaltiScope.of(context).pay(
        config: config,
        preferences: KhaltiConfig.paymentPreferences,
        onSuccess: (successModel) async {
          _onPaymentSuccess(successModel, slot);
        },
        onFailure: (failureModel) {
          _onPaymentFailure(failureModel);
        },
        onCancel: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled by user'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      print('Payment Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment initialization failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _onPaymentSuccess(
      PaymentSuccessModel success, Map<String, dynamic> slot) async {
    try {
      // Add payment details to the slot
      slot['paymentDetails'] = {
        'token': success.token,
        'amount': success.amount,
        'mobile': success.mobile,
        'productIdentity': success.productIdentity,
        'productName': success.productName,
        'paymentStatus': 'Completed',
        'transactionDate': DateTime.now().toIso8601String(),
      };

      // Create booking with payment details
      final bookingResponse = await ApiVendorAvailability.createBooking(
        slot,
        widget.token,
      );

      if (bookingResponse['status'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful and booking confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Payment successful but booking failed. Please contact support.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onPaymentFailure(PaymentFailureModel failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${failure.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Map<String, dynamic>? _processBookingDetails(String guestsText) {
    int guests = int.tryParse(guestsText) ?? 0;
    if (guests < 25) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum 25 guests required'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    return {
      'startDate': _rangeStart.toString(),
      'endDate': _rangeEnd.toString(),
      'guests': guests,
      'totalPrice': guests * int.parse(widget.price),
      'vendorId': widget.vendorId,
      'vendorEmail': widget.vendorEmail,
      'eventType': widget.vendorType,
      'vendorName': widget.vendorName,
      'price': widget.price,
    };
  }
}
