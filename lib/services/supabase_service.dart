// services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/transaction.dart';

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
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final response = await client
        .from('transactions')
        .select('amount')
        .eq('status', 'active')
        .gte('payment_date', startOfMonth.toIso8601String())
        .lte('payment_date', endOfMonth.toIso8601String());

    double total = 0;
    for (var transaction in response) {
      total += transaction['amount'];
    }
    return total;
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
}
