// state/app_state.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import '../models/overdue_summary.dart';

class AppState extends ChangeNotifier {
  double _amountReceivedThisMonth = 0.0;
  double _amountDue = 0.0;
  double _amountExpectedThisMonth = 0.0;
  Map<String, OverdueSummary> _overdueByCustomer = {};

  bool _initialized = false;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _invoicesSub;
  StreamSubscription? _customersSub;

  double get amountReceivedThisMonth => _amountReceivedThisMonth;
  double get amountDue => _amountDue;
  double get amountExpectedThisMonth => _amountExpectedThisMonth;
  Map<String, OverdueSummary> get overdueByCustomer => _overdueByCustomer;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Initial compute
    recomputeTotals();

    // Listen to realtime changes across key tables to keep totals fresh
    final client = SupabaseService().client;
    _transactionsSub = client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .listen((_) => recomputeTotals());
    _invoicesSub = client
        .from('invoices')
        .stream(primaryKey: ['id'])
        .listen((_) => recomputeTotals());
    _customersSub = client
        .from('customers')
        .stream(primaryKey: ['id'])
        .listen((_) => recomputeTotals());
  }

  Future<void> recomputeTotals() async {
    try {
      final results = await Future.wait([
        SupabaseService().getAmountReceivedThisMonth(),
        SupabaseService().getAmountDue(),
        SupabaseService().getAmountExpectedThisMonth(),
        SupabaseService().getOverdueSummaries(),
      ]);
      _amountReceivedThisMonth = (results[0] as double);
      _amountDue = (results[1] as double);
      _amountExpectedThisMonth = (results[2] as double);
      _overdueByCustomer = results[3] as Map<String, OverdueSummary>;
      notifyListeners();
    } catch (_) {
      // Silently ignore; UI remains with last known values
    }
  }

  void onCustomerUpdated(Customer _customer) {
    // For now, totals do not directly depend on customer fields alone,
    // but updates might cascade via triggers; recompute to be safe.
    recomputeTotals();
  }

  void onCustomerAdded(Customer _customer) {
    recomputeTotals();
  }

  void disposeStreams() {
    _transactionsSub?.cancel();
    _invoicesSub?.cancel();
    _customersSub?.cancel();
  }

  @override
  void dispose() {
    disposeStreams();
    super.dispose();
  }
}
