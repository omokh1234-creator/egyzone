class PaymentMethod {
  final dynamic methodId;
  final String name;

  PaymentMethod({this.methodId, required this.name});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      methodId: json['methodId'],
      name: json['name'] as String? ?? '',
    );
  }
}

class Payment {
  final dynamic paymentId;
  final dynamic orderId;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paidAt;
  final dynamic methodId;
  final PaymentMethod? method;

  Payment({
    this.paymentId,
    this.orderId,
    this.paymentMethod,
    this.paymentStatus,
    this.paidAt,
    this.methodId,
    this.method,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['paymentId'],
      orderId: json['orderId'],
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      paidAt: json['paidAt'] as String?,
      methodId: json['methodId'],
      method: json['method'] != null
          ? PaymentMethod.fromJson(json['method'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaymentRequestDto {
  final dynamic orderId;
  final dynamic methodId;
  final String? cardNumber;

  PaymentRequestDto({
    required this.orderId,
    required this.methodId,
    this.cardNumber,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'methodId': methodId,
        if (cardNumber != null && cardNumber!.isNotEmpty)
          'cardNumber': cardNumber,
      };
}
