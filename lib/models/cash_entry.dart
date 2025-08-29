// models/cash_entry.dart
enum CashEntryType { inFlow, outFlow }

class CashEntry {
  final String id;
  final String bookId;
  final CashEntryType type;
  final double amount;
  final String? note;
  final DateTime entryDate;
  final DateTime createdAt;

  CashEntry({
    required this.id,
    required this.bookId,
    required this.type,
    required this.amount,
    this.note,
    required this.entryDate,
    required this.createdAt,
  });

  factory CashEntry.fromJson(Map<String, dynamic> json) {
    return CashEntry(
      id: json['id'],
      bookId: json['book_id'],
      type: (json['type'] as String) == 'in'
          ? CashEntryType.inFlow
          : CashEntryType.outFlow,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount'].toString()) ?? 0,
      note: json['note'],
      entryDate: DateTime.parse(json['entry_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'type': type == CashEntryType.inFlow ? 'in' : 'out',
      'amount': amount,
      'note': note,
      'entry_date': entryDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
