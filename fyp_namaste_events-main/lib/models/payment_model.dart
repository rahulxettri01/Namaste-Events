class PaymentSuccessModel {
  final String pidx;
  final String transactionId;
  final int amount;
  final String mobile;
  final String status;
  final String message;

  PaymentSuccessModel({
    required this.pidx,
    required this.transactionId,
    required this.amount,
    required this.mobile,
    required this.status,
    this.message = '',
  });

  factory PaymentSuccessModel.fromJson(Map<String, dynamic> json) {
    return PaymentSuccessModel(
      pidx: json['pidx'],
      transactionId: json['transaction_id'],
      amount: json['amount'],
      mobile: json['mobile'],
      status: json['status'],
      message: json['message'] ?? '',
    );
  }
}

class PaymentFailureModel {
  final String message;
  final String? errorCode;
  final String? pidx;

  PaymentFailureModel({
    required this.message,
    this.errorCode,
    this.pidx,
  });
}
