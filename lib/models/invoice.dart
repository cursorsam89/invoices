enum InvoiceStatus { pending, paid, overdue }

class Invoice {
  final String id;
  final String customerId;
  final DateTime dueDate;
  final double amount;
  final InvoiceStatus status;
  final double paidAmount;
  final String? description;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.customerId,
    required this.dueDate,
    required this.amount,
    required this.status,
    required this.paidAmount,
    this.description,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      customerId: json['customer_id'],
      dueDate: DateTime.parse(json['due_date']),
      amount: json['amount'].toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvoiceStatus.pending,
      ),
      paidAmount: json['paid_amount'].toDouble(),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'due_date': dueDate.toIso8601String(),
      'amount': amount,
      'status': status.toString().split('.').last,
      'paid_amount': paidAmount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get remainingAmount => amount - paidAmount;
  bool get isFullyPaid => paidAmount >= amount;
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && !isFullyPaid;
  int get overdueDays => isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

  Invoice copyWith({
    String? id,
    String? customerId,
    DateTime? dueDate,
    double? amount,
    InvoiceStatus? status,
    double? paidAmount,
    String? description,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}