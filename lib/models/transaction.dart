enum TransactionStatus { active, cancelled }

class Transaction {
  final String id;
  final String invoiceId;
  final double amount;
  final DateTime paymentDate;
  final TransactionStatus status;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.status,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      invoiceId: json['invoice_id'],
      amount: json['amount'].toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == TransactionStatus.active;
  bool get isCancelled => status == TransactionStatus.cancelled;

  Transaction copyWith({
    String? id,
    String? invoiceId,
    double? amount,
    DateTime? paymentDate,
    TransactionStatus? status,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}