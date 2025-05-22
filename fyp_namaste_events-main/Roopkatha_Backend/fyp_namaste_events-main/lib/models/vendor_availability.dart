class VendorAvailability {
  final String id;
  final String vendorId;
  final DateTime date;
  final bool isAvailable;
  final String? reason;

  VendorAvailability({
    required this.id,
    required this.vendorId,
    required this.date,
    required this.isAvailable,
    this.reason,
  });

  factory VendorAvailability.fromJson(Map<String, dynamic> json) {
    return VendorAvailability(
      id: json['_id'],
      vendorId: json['vendorId'],
      date: DateTime.parse(json['date']),
      isAvailable: json['isAvailable'],
      reason: json['reason'],
    );
  }
}