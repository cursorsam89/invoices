// services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/transaction.dart';
import '../models/overdue_summary.dart';
import '../models/book.dart';
import '../models/cash_entry.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(email: email, password: password);
    try {
      await _ensureUserRecord();
    } catch (e) {
      print('[signUp] ensureUserRecord error: ' + e.toString());
    }
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    try {
      await _ensureUserRecord();
    } catch (e) {
      print('[signIn] ensureUserRecord error: ' + e.toString());
    }
    return response;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  app_models.User? get currentUser {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return app_models.User(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Customer methods
  Future<List<Customer>> getCustomers() async {
    final response = await client
        .from('customers')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Customer.fromJson(json)).toList();
  }

  // Cashbook methods
  Future<List<Book>> getBooks() async {
    final response = await client
        .from('books')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Book.fromJson(json)).toList();
  }

  Stream<List<Book>> streamBooks() {
    return client
        .from('books')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false)
        .map(
          (response) => response.map((json) => Book.fromJson(json)).toList(),
        );
  }

  Future<Book> createBook(Book book) async {
    // Safety: ensure a corresponding row exists in users table for FK and RLS alignment
    try {
      await _ensureUserRecord();
    } catch (e) {
      print('[createBook] ensureUserRecord error: ' + e.toString());
    }
    final insertData = {
      'user_id': book.userId,
      'name': book.name,
      if (book.description != null) 'description': book.description,
    };
    print('[createBook] insert payload: ' + insertData.toString());
    final response = await client
        .from('books')
        .insert(insertData)
        .select()
        .single();
    return Book.fromJson(response);
  }

  Future<void> deleteBook(String bookId) async {
    await client.from('books').delete().eq('id', bookId);
  }

  Future<Book> updateBook(Book book) async {
    final updateData = <String, dynamic>{
      'name': book.name,
      'description': book.description,
    };
    final response = await client
        .from('books')
        .update(updateData)
        .eq('id', book.id)
        .select()
        .maybeSingle();
    if (response == null) {
      throw Exception('Update failed: row not found or blocked by RLS');
    }
    return Book.fromJson(response);
  }

  Future<List<CashEntry>> getEntries(String bookId) async {
    final response = await client
        .from('cash_entries')
        .select()
        .eq('book_id', bookId)
        .order('entry_date', ascending: false);
    return (response as List).map((json) => CashEntry.fromJson(json)).toList();
  }

  Stream<List<CashEntry>> streamEntries(String bookId) {
    return client
        .from('cash_entries')
        .stream(primaryKey: ['id'])
        .eq('book_id', bookId)
        .order('entry_date', ascending: false)
        .map(
          (response) =>
              response.map((json) => CashEntry.fromJson(json)).toList(),
        );
  }

  Future<CashEntry> createEntry(CashEntry entry) async {
    final insertData = {
      'book_id': entry.bookId,
      'type': entry.type == CashEntryType.inFlow ? 'in' : 'out',
      'amount': entry.amount,
      if (entry.note != null) 'note': entry.note,
      'entry_date': entry.entryDate.toIso8601String(),
    };
    final response = await client
        .from('cash_entries')
        .insert(insertData)
        .select()
        .single();
    return CashEntry.fromJson(response);
  }

  Future<void> deleteEntry(String entryId) async {
    await client.from('cash_entries').delete().eq('id', entryId);
  }

  Future<Customer> createCustomer(Customer customer) async {
    // Safety: ensure a corresponding row exists in users table for FK
    try {
      await _ensureUserRecord();
    } catch (e) {
      print('[createCustomer] ensureUserRecord error: ' + e.toString());
    }
    final Map<String, dynamic> insertData = {
      'user_id': customer.userId,
      'name': customer.name,
      if (customer.amount != null) 'amount': customer.amount,
      if (customer.description != null) 'description': customer.description,
      'repeat': customer.repeat,
      'start_date': customer.startDate.toIso8601String(),
      'end_date': customer.endDate.toIso8601String(),
    };

    try {
      print('[createCustomer] insert payload: ' + insertData.toString());
      final response = await client
          .from('customers')
          .insert(insertData)
          .select()
          .single();
      print('[createCustomer] response: ' + response.toString());
      return Customer.fromJson(response);
    } catch (e, st) {
      print('[createCustomer] error: ' + e.toString());
      print(st);
      rethrow;
    }
  }

  Future<void> _ensureUserRecord() async {
    final authUser = client.auth.currentUser;
    if (authUser == null) return;
    final payload = {'id': authUser.id, 'email': authUser.email};
    try {
      print('[ensureUserRecord] upsert payload: ' + payload.toString());
      await client.from('users').upsert(payload, onConflict: 'id');
    } catch (e) {
      print('[ensureUserRecord] upsert error: ' + e.toString());
      rethrow;
    }
  }

  Future<Customer> updateCustomer(Customer customer) async {
    final response = await client
        .from('customers')
        .update(customer.toJson())
        .eq('id', customer.id)
        .select()
        .single();

    return Customer.fromJson(response);
  }

  /// Regenerate or adjust invoices when a customer's schedule/amount changes.
  ///
  /// Rules:
  /// - If no invoices have payments yet (paid_amount == 0 for all), delete and fully regenerate.
  /// - If some invoices have payments, keep those; delete unpaid ones and create
  ///   new invoices to reach the new repeat count. New invoices use the new
  ///   start date cadence and current amount/description.
  /// - If amount is null or <= 0, delete unpaid invoices and do not create new ones.
  Future<void> regenerateInvoicesForCustomer(Customer customer) async {
    // Fetch existing invoices
    final existing = await getInvoicesByCustomer(customer.id);

    // If amount is not set, remove all unpaid invoices and stop
    final bool hasValidAmount = (customer.amount ?? 0) > 0;

    // Helpers
    Future<void> _deleteInvoices(List<Invoice> invoices) async {
      for (final inv in invoices) {
        await deleteInvoice(inv.id);
      }
    }

    Future<void> _updateInvoiceFields(Invoice invoice, DateTime dueDate) async {
      final updated = invoice.copyWith(
        dueDate: dueDate,
        amount: customer.amount ?? invoice.amount,
        description: customer.description,
        status: InvoiceStatus.pending,
      );
      await updateInvoice(updated);
    }

    List<DateTime> _buildDueDates() {
      final List<DateTime> dueDates = [];
      for (int i = 0; i < customer.repeat; i++) {
        dueDates.add(
          DateTime(
            customer.startDate.year,
            customer.startDate.month + i,
            customer.startDate.day,
          ),
        );
      }
      return dueDates;
    }

    if (!hasValidAmount) {
      // Remove all unpaid invoices
      final unpaid = existing.where((e) => (e.paidAmount <= 0)).toList();
      await _deleteInvoices(unpaid);
      return;
    }

    // Sort existing by due date to align with schedule
    existing.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final targetDueDates = _buildDueDates();

    final paid = existing.where((e) => e.paidAmount > 0).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final unpaid = existing.where((e) => e.paidAmount <= 0).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (paid.isEmpty) {
      // Align all existing unpaid to the target schedule by updating in place
      final int common = existing.length < targetDueDates.length
          ? existing.length
          : targetDueDates.length;
      for (int i = 0; i < common; i++) {
        await _updateInvoiceFields(existing[i], targetDueDates[i]);
      }
      // If we have more existing than target, delete the extras
      if (existing.length > targetDueDates.length) {
        final extra = existing.sublist(targetDueDates.length);
        await _deleteInvoices(extra);
      }
      // If we need more, create the remainder
      if (targetDueDates.length > existing.length) {
        final toCreate = targetDueDates.sublist(existing.length);
        for (final due in toCreate) {
          final invoice = Invoice(
            id: '',
            customerId: customer.id,
            dueDate: due,
            amount: customer.amount!,
            status: InvoiceStatus.pending,
            paidAmount: 0,
            description: customer.description,
            createdAt: DateTime.now(),
          );
          await createInvoice(invoice);
        }
      }
      return;
    }

    // Mixed case: keep paid invoices as-is; align unpaid ones after paid slots
    final int startIndex = paid.length;
    final remainingTargets = targetDueDates.skip(startIndex).toList();

    // Update unpaid invoices to match remaining schedule
    final int commonUnpaid = unpaid.length < remainingTargets.length
        ? unpaid.length
        : remainingTargets.length;
    for (int i = 0; i < commonUnpaid; i++) {
      await _updateInvoiceFields(unpaid[i], remainingTargets[i]);
    }

    // Delete extra unpaid invoices if fewer are needed
    if (unpaid.length > remainingTargets.length) {
      final extra = unpaid.sublist(remainingTargets.length);
      await _deleteInvoices(extra);
    }

    // Create additional invoices if more are needed
    if (remainingTargets.length > unpaid.length) {
      final toCreate = remainingTargets.sublist(unpaid.length);
      for (final due in toCreate) {
        final invoice = Invoice(
          id: '',
          customerId: customer.id,
          dueDate: due,
          amount: customer.amount!,
          status: InvoiceStatus.pending,
          paidAmount: 0,
          description: customer.description,
          createdAt: DateTime.now(),
        );
        await createInvoice(invoice);
      }
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    await client.from('customers').delete().eq('id', customerId);
  }

  Stream<List<Customer>> streamCustomers() {
    return client
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false)
        .map(
          (response) =>
              response.map((json) => Customer.fromJson(json)).toList(),
        );
  }

  // Invoice methods
  Future<List<Invoice>> getInvoicesByCustomer(String customerId) async {
    final response = await client
        .from('invoices')
        .select()
        .eq('customer_id', customerId)
        .order('due_date', ascending: true);

    return (response as List).map((json) => Invoice.fromJson(json)).toList();
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    final Map<String, dynamic> insertData = {
      'customer_id': invoice.customerId,
      'due_date': invoice.dueDate.toIso8601String(),
      'amount': invoice.amount,
      'status': invoice.status.toString().split('.').last,
      'paid_amount': invoice.paidAmount,
      if (invoice.description != null) 'description': invoice.description,
    };

    try {
      print('[createInvoice] insert payload: ' + insertData.toString());
      final response = await client
          .from('invoices')
          .insert(insertData)
          .select()
          .single();
      print('[createInvoice] response: ' + response.toString());
      return Invoice.fromJson(response);
    } catch (e, st) {
      print('[createInvoice] error: ' + e.toString());
      print(st);
      rethrow;
    }
  }

  Future<Invoice> updateInvoice(Invoice invoice) async {
    final response = await client
        .from('invoices')
        .update(invoice.toJson())
        .eq('id', invoice.id)
        .select()
        .single();

    return Invoice.fromJson(response);
  }

  /// Recalculate an invoice's paid amount from active transactions and update it.
  Future<Invoice> recalcInvoiceFromTransactions(String invoiceId) async {
    // Fetch current invoice
    final invoiceResp = await client
        .from('invoices')
        .select()
        .eq('id', invoiceId)
        .single();
    final current = Invoice.fromJson(invoiceResp);

    // Sum active transactions
    final txs = await client
        .from('transactions')
        .select('amount, status')
        .eq('invoice_id', invoiceId);
    double paid = 0;
    for (final t in txs as List) {
      if ((t['status'] as String) == 'active') {
        final dynamic amt = t['amount'];
        paid += amt is num
            ? amt.toDouble()
            : double.tryParse(amt.toString()) ?? 0;
      }
    }

    final double newTotal = paid > current.amount ? paid : current.amount;
    final updated = current.copyWith(
      paidAmount: paid,
      amount: newTotal,
      status: paid >= newTotal ? InvoiceStatus.paid : InvoiceStatus.pending,
    );
    return await updateInvoice(updated);
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await client.from('invoices').delete().eq('id', invoiceId);
  }

  Stream<List<Invoice>> streamInvoicesByCustomer(String customerId) {
    return client
        .from('invoices')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('due_date', ascending: true)
        .map(
          (response) => response.map((json) => Invoice.fromJson(json)).toList(),
        );
  }

  // Transaction methods
  Future<List<Transaction>> getTransactionsByInvoice(String invoiceId) async {
    final response = await client
        .from('transactions')
        .select()
        .eq('invoice_id', invoiceId)
        .order('payment_date', ascending: false);

    return (response as List)
        .map((json) => Transaction.fromJson(json))
        .toList();
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    final Map<String, dynamic> insertData = {
      'invoice_id': transaction.invoiceId,
      'amount': transaction.amount,
      'payment_date': transaction.paymentDate.toIso8601String(),
      'status': transaction.status.toString().split('.').last,
    };

    try {
      print('[createTransaction] insert payload: ' + insertData.toString());
      final response = await client
          .from('transactions')
          .insert(insertData)
          .select()
          .single();
      print('[createTransaction] response: ' + response.toString());
      return Transaction.fromJson(response);
    } catch (e, st) {
      print('[createTransaction] error: ' + e.toString());
      print(st);
      rethrow;
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final response = await client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id)
        .select()
        .single();

    return Transaction.fromJson(response);
  }

  Stream<List<Transaction>> streamTransactionsByInvoice(String invoiceId) {
    return client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('invoice_id', invoiceId)
        .order('payment_date', ascending: false)
        .map(
          (response) =>
              response.map((json) => Transaction.fromJson(json)).toList(),
        );
  }

  // Dashboard calculations
  Future<double> getAmountReceivedThisMonth() async {
    final now = DateTime.now();
    final String startDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
    final DateTime nextMonthBase = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final String nextMonthDate =
        '${nextMonthBase.year.toString().padLeft(4, '0')}-${nextMonthBase.month.toString().padLeft(2, '0')}-${nextMonthBase.day.toString().padLeft(2, '0')}';

    // Constrain to the current user's invoices explicitly to avoid any policy quirks
    final customerIdsResp = await client
        .from('customers')
        .select('id')
        .eq('user_id', currentUser!.id);
    final customerIds = (customerIdsResp as List)
        .map((e) => e['id'] as String)
        .toList();
    if (customerIds.isEmpty) return 0.0;

    final invoiceIdsResp = await client
        .from('invoices')
        .select('id, customer_id')
        .inFilter('customer_id', customerIds);
    final invoiceIds = (invoiceIdsResp as List)
        .map((e) => e['id'] as String)
        .toList();
    if (invoiceIds.isEmpty) return 0.0;

    final response = await client
        .from('transactions')
        .select('amount')
        .inFilter('invoice_id', invoiceIds)
        .eq('status', 'active')
        .gte('payment_date', startDate)
        .lt('payment_date', nextMonthDate);

    double total = 0.0;
    for (final tx in response as List) {
      final dynamic amt = tx['amount'];
      total += amt is num
          ? amt.toDouble()
          : double.tryParse(amt.toString()) ?? 0.0;
    }
    return total;
  }

  /// Get monthly collection history for the past 12 months
  Future<Map<String, double>> getMonthlyCollectionHistory() async {
    final now = DateTime.now();
    final Map<String, double> monthlyData = {};

    // Get user's customer IDs
    final customerIdsResp = await client
        .from('customers')
        .select('id')
        .eq('user_id', currentUser!.id);
    final customerIds = (customerIdsResp as List)
        .map((e) => e['id'] as String)
        .toList();
    if (customerIds.isEmpty) return monthlyData;

    // Get user's invoice IDs
    final invoiceIdsResp = await client
        .from('invoices')
        .select('id, customer_id')
        .inFilter('customer_id', customerIds);
    final invoiceIds = (invoiceIdsResp as List)
        .map((e) => e['id'] as String)
        .toList();
    if (invoiceIds.isEmpty) return monthlyData;

    // Get all transactions for the past 12 months
    final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);
    final startDate =
        '${twelveMonthsAgo.year.toString().padLeft(4, '0')}-${twelveMonthsAgo.month.toString().padLeft(2, '0')}-01';
    final endDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('transactions')
        .select('amount, payment_date')
        .inFilter('invoice_id', invoiceIds)
        .eq('status', 'active')
        .gte('payment_date', startDate)
        .lte('payment_date', endDate);

    // Group transactions by month
    for (final tx in response as List) {
      final paymentDate = DateTime.parse(tx['payment_date'] as String);
      final monthKey =
          '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}';
      final amount = tx['amount'] is num
          ? (tx['amount'] as num).toDouble()
          : double.tryParse(tx['amount'].toString()) ?? 0.0;

      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0.0) + amount;
    }

    return monthlyData;
  }

  Future<double> getAmountDue() async {
    final response = await client
        .from('invoices')
        .select('amount, paid_amount')
        .lt('due_date', DateTime.now().toIso8601String());

    double total = 0;
    for (var invoice in response) {
      final remaining = invoice['amount'] - invoice['paid_amount'];
      if (remaining > 0) {
        total += remaining;
      }
    }
    return total;
  }

  Future<double> getAmountExpectedThisMonth() async {
    final now = DateTime.now();
    final String startDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
    final DateTime nextMonthBase = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    final String nextMonthDate =
        '${nextMonthBase.year.toString().padLeft(4, '0')}-${nextMonthBase.month.toString().padLeft(2, '0')}-${nextMonthBase.day.toString().padLeft(2, '0')}';

    // Constrain to the current user's invoices explicitly to avoid any policy quirks
    final customerIdsResp = await client
        .from('customers')
        .select('id')
        .eq('user_id', currentUser!.id);
    final customerIds = (customerIdsResp as List)
        .map((e) => e['id'] as String)
        .toList();
    if (customerIds.isEmpty) return 0.0;

    final response = await client
        .from('invoices')
        .select('amount, due_date')
        .inFilter('customer_id', customerIds)
        .gte('due_date', startDate)
        .lt('due_date', nextMonthDate);

    double total = 0.0;
    for (final invoice in response as List) {
      final dynamic amt = invoice['amount'];
      total += amt is num
          ? amt.toDouble()
          : double.tryParse(amt.toString()) ?? 0.0;
    }
    return total;
  }

  Future<List<Customer>> getOverdueCustomers() async {
    final nowIso = DateTime.now().toIso8601String();

    // Step 1: Find customer_ids that have at least one overdue invoice with remaining > 0
    final invoices = await client
        .from('invoices')
        .select('customer_id, amount, paid_amount, due_date')
        .lt('due_date', nowIso);

    final Set<String> overdueCustomerIds = {};
    for (final invoice in invoices as List) {
      final dynamic amountRaw = invoice['amount'];
      final dynamic paidRaw = invoice['paid_amount'];
      final double amount = amountRaw is num
          ? amountRaw.toDouble()
          : (amountRaw is String ? double.tryParse(amountRaw) ?? 0 : 0);
      final double paid = paidRaw is num
          ? paidRaw.toDouble()
          : (paidRaw is String ? double.tryParse(paidRaw) ?? 0 : 0);
      if (amount - paid > 0) {
        overdueCustomerIds.add(invoice['customer_id'] as String);
      }
    }

    if (overdueCustomerIds.isEmpty) {
      return [];
    }

    // Step 2: Fetch those customers for the current user
    final customersResponse = await client
        .from('customers')
        .select()
        .eq('user_id', currentUser!.id)
        .inFilter('id', overdueCustomerIds.toList())
        .order('created_at', ascending: false);

    return (customersResponse as List)
        .map((json) => Customer.fromJson(json))
        .toList();
  }

  Future<Map<String, OverdueSummary>> getOverdueSummaries() async {
    // Fetch all customers for current user to scope invoice query
    final customersResp = await client
        .from('customers')
        .select('id')
        .eq('user_id', currentUser!.id);
    final customerIds = (customersResp as List)
        .map((e) => e['id'] as String)
        .toList();
    if (customerIds.isEmpty) return {};

    // Fetch overdue invoices for these customers
    final nowIso = DateTime.now().toIso8601String();
    final invoicesResp = await client
        .from('invoices')
        .select('customer_id, amount, paid_amount, due_date')
        .inFilter('customer_id', customerIds)
        .lt('due_date', nowIso);

    // Group invoices by customer_id for proper calculation
    final Map<String, List<Map<String, dynamic>>> invoicesByCustomer = {};
    for (final inv in invoicesResp as List) {
      final String cid = inv['customer_id'] as String;
      invoicesByCustomer.putIfAbsent(cid, () => []).add(inv);
    }

    final Map<String, OverdueSummary> result = {};

    for (final entry in invoicesByCustomer.entries) {
      final String customerId = entry.key;
      final List<Map<String, dynamic>> customerInvoices = entry.value;

      double totalOverdueAmount = 0.0;
      int maxOverdueDays = 0; // Track the most recent overdue invoice's days

      for (final inv in customerInvoices) {
        final dynamic amountRaw = inv['amount'];
        final dynamic paidRaw = inv['paid_amount'];
        final double amount = amountRaw is num
            ? amountRaw.toDouble()
            : (amountRaw is String ? double.tryParse(amountRaw) ?? 0 : 0);
        final double paid = paidRaw is num
            ? paidRaw.toDouble()
            : (paidRaw is String ? double.tryParse(paidRaw) ?? 0 : 0);
        final double remaining = amount - paid;

        if (remaining > 0) {
          totalOverdueAmount += remaining;

          // Calculate overdue days for this invoice
          final int days = DateTime.now()
              .difference(DateTime.parse(inv['due_date'] as String))
              .inDays;

          // Keep track of the maximum overdue days (most recent overdue invoice)
          if (days > maxOverdueDays) {
            maxOverdueDays = days;
          }
        }
      }

      // Only add to result if there are overdue amounts
      if (totalOverdueAmount > 0) {
        result[customerId] = OverdueSummary(
          totalOverdueAmount: totalOverdueAmount,
          totalOverdueDays: maxOverdueDays,
        );
      }
    }

    return result;
  }
}
