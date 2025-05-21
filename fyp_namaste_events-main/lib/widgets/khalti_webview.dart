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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('payment/callback')) {
              // Extract data from URL
              final uri = Uri.parse(request.url);
              final queryParams = uri.queryParameters;

              // Close WebView and return data
              Navigator.pop(context);
              widget.onPaymentComplete({
                'status': queryParams['status'],
                'token': queryParams['token'],
                'amount': int.tryParse(queryParams['amount'] ?? '0'),
                'mobile': queryParams['mobile'],
                'productIdentity': queryParams['productIdentity'],
                'productName': queryParams['productName'],
                'message': queryParams['message'],
              });
              return NavigationDecision.prevent;
            }
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
          onPressed: () => Navigator.pop(context),
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
