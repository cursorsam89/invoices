class Customer {
  final String id;
  final String userId;
  final String name;
  final double? amount;
  final String? description;
  final int repeat;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.userId,
    required this.name,
    this.amount,
    this.description,
    required this.repeat,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      amount: json['amount']?.toDouble(),
      description: json['description'],
      repeat: json['repeat'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'description': description,
      'repeat': repeat,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? description,
    int? repeat,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      repeat: repeat ?? this.repeat,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}