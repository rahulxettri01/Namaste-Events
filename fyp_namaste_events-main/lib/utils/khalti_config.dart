import 'package:khalti_flutter/khalti_flutter.dart';

class KhaltiConfig {
  static const String publicKey = "97c940a50b15464787682f4624ee4313";

  static PaymentConfig getPaymentConfig({
    required int amount,
    required String productIdentity,
    required String productName,
    // String? mobile,
  }) {
    // Validate mobile number format if provided
    // if (mobile != null && !RegExp(r'(^[9][678][0-9]{8}$)').hasMatch(mobile)) {
    //   throw ArgumentError(
    //       'Invalid mobile number format. Must start with 96, 97, or 98 and be 10 digits long');
    // }

    return PaymentConfig(
      amount: amount,
      productIdentity: productIdentity,
      productName: productName,
      // productUrl: 'https://namaste-events.com',
      // mobile: mobile,

      mobileReadOnly: false,
      additionalData: {
        'merchant_name': 'Namaste Events',
        'transaction_date': DateTime.now().toIso8601String(),
      },
    );
  }

  static List<PaymentPreference> get paymentPreferences => const [
        PaymentPreference.khalti,
        PaymentPreference.eBanking,
        PaymentPreference.mobileBanking,
      ];
}
