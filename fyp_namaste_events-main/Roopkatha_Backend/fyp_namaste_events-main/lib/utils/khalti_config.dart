import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/home_page.dart';

class KhaltiConfig {
  static const String publicKey = "97c940a50b15464787682f4624ee4313";

  static khaltiScope(token) {
    return KhaltiScope(
      publicKey: publicKey,
      enabledDebugging: true,
      builder: (context, navigatorKey) {
        return MaterialApp(
          // navigatorKey: navigatorKey,
          home: HomePage(token: token),
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ne', 'NP'),
          ],
          localizationsDelegates: const [
            KhaltiLocalizations.delegate,
          ],
        );
      },
    );
  }

  static PaymentConfig getPaymentConfig({
    required int amount,
    required String productIdentity,
    required String productName,
  }) {
    return PaymentConfig(
      amount: amount,
      productIdentity: productIdentity,
      productName: productName,
      // productUrl: 'http://localhost:2000', // Development URL
      additionalData: {
        // 'vendor_name': productName,
        'merchant_name': 'Namaste Events',
        'transaction_date': DateTime.now().toIso8601String(),
      },
      // mobile: '',
    );
  }

  static List<PaymentPreference> get paymentPreferences => [
        PaymentPreference.khalti,
        PaymentPreference.eBanking,
        PaymentPreference.mobileBanking,
      ];
}
