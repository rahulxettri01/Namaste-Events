import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KhaltiWebView extends StatefulWidget {
  final String paymentUrl;
  final String pidx;
  final Function(Map<String, dynamic>) onPaymentComplete;

  const KhaltiWebView({
    Key? key,
    required this.paymentUrl,
    required this.pidx,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  _KhaltiWebViewState createState() => _KhaltiWebViewState();
}

class _KhaltiWebViewState extends State<KhaltiWebView> {
  bool isLoading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaymentChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('Received payment data: ${message.message}');
          try {
            print("in the in in in");
            final paymentData = jsonDecode(message.message);

            print('Decoded payment data: $paymentData');
            print(paymentData);
            if (paymentData['success'] == true &&
                paymentData['status'] == 'completed') {
              Navigator.pop(context);

              widget.onPaymentComplete({
                'success': true,
                'pidx': paymentData['pidx'],
                'transactionId': paymentData['transactionId'],
                'status': 'Completed',
                'amount': paymentData['amount'],
                'mobile': paymentData['mobile'],
                'paymentMethod': paymentData['paymentMethod']
              });
            } else if (paymentData['status'] == 'Cancelled') {
              Navigator.pop(context);
              widget.onPaymentComplete({
                'success': false,
                'status': 'Cancelled',
                'message': 'Payment cancelled by user'
              });
            } else {
              Navigator.pop(context);
              widget.onPaymentComplete({
                'success': false,
                'status': 'Failed',
                'message': paymentData['message'] ?? 'Payment failed'
              });
            }
          } catch (e) {
            print('Error processing payment data: $e');
            print(e);
            Navigator.pop(context);
            widget.onPaymentComplete({
              'success': false,
              'status': 'Failed',
              'message': 'Error processing payment data'
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
            if (url.contains('api/payment/khalti-callback')) {
              final uri = Uri.parse(url);
              final queryParams = uri.queryParameters;

              Navigator.pop(context);
              widget.onPaymentComplete({
                'success': true,
                'pidx': queryParams['pidx'] ?? '',
                'transactionId': queryParams['transaction_id'] ?? '',
                'status': 'Completed',
                'amount': queryParams['amount'] ?? '0',
                'mobile': queryParams['mobile'] ?? '',
                'paymentMethod': queryParams['payment_method'] ?? ''
              });
            }

            _controller.runJavaScript('''
              window.addEventListener('message', function(event) {
                console.log('Payment event received:', event.data);
                PaymentChannel.postMessage(JSON.stringify(event.data));
              });
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Khalti Payment'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
            widget.onPaymentComplete({
              'success': true,
              'status': 'Cancelled',
              'message': 'Payment cancelled by user'
            });
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
