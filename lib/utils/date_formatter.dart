import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDisplayDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatStorageDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date.toUtc());
  }

  static DateTime parseStorageDate(String dateString) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateString, true).toLocal();
  }

  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  static String getOverdueText(int days) {
    if (days == 1) return 'Overdue: 1 day';
    return 'Overdue: $days days';
  }

  static String getStatusText(DateTime dueDate, double paidAmount, double totalAmount) {
    if (paidAmount >= totalAmount) {
      return 'PAID';
    } else if (dueDate.isBefore(DateTime.now())) {
      final days = DateTime.now().difference(dueDate).inDays;
      return getOverdueText(days);
    } else {
      return 'UPCOMING';
    }
  }
}