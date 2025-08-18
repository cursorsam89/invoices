// models/book.dart
class Book {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime createdAt;

  Book({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Book copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
