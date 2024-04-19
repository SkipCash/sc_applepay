class PaymentResponse {
  final String paymentId;
  final bool isSuccess;
  final String token;
  final int returnCode;
  final String errorMessage;

  PaymentResponse({
    required this.paymentId,
    required this.isSuccess,
    required this.token,
    required this.returnCode,
    required this.errorMessage,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      paymentId: json['paymentId'],
      isSuccess: json['isSuccess'],
      token: json['token'],
      returnCode: json['returnCode'],
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'isSuccess': isSuccess,
      'token': token,
      'returnCode': returnCode,
      'errorMessage': errorMessage,
    };
  }
}
