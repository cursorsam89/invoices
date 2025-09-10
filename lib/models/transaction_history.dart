class TransactionHistory {
  final String id;
  final String customerId;
  final String customerName;
  final String invoiceId;
  final double amount;
  final DateTime paymentDate;
  final DateTime createdAt;

  TransactionHistory({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
  });

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    return TransactionHistory(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'] ?? '',
      invoiceId: json['invoice_id'],
      amount: json['amount'].toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TransactionHistory copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? invoiceId,
    double? amount,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) {
    return TransactionHistory(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
