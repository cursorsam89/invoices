import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
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
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return User(
      id: user.id,
      email: user.email ?? '',
      createdAt: user.createdAt,
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
    final response = await client
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();

    return Customer.fromJson(response);
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
        .map((response) => response.map((json) => Customer.fromJson(json)).toList());
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
    final response = await client
        .from('invoices')
        .insert(invoice.toJson())
        .select()
        .single();

    return Invoice.fromJson(response);
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
        .map((response) => response.map((json) => Invoice.fromJson(json)).toList());
  }

  // Transaction methods
  Future<List<Transaction>> getTransactionsByInvoice(String invoiceId) async {
    final response = await client
        .from('transactions')
        .select()
        .eq('invoice_id', invoiceId)
        .order('payment_date', ascending: false);

    return (response as List).map((json) => Transaction.fromJson(json)).toList();
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    final response = await client
        .from('transactions')
        .insert(transaction.toJson())
        .select()
        .single();

    return Transaction.fromJson(response);
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
        .map((response) => response.map((json) => Transaction.fromJson(json)).toList());
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
    final response = await client
        .from('customers')
        .select('''
          *,
          invoices!inner(
            id,
            due_date,
            amount,
            paid_amount
          )
        ''')
        .eq('user_id', currentUser!.id)
        .lt('invoices.due_date', DateTime.now().toIso8601String())
        .lt('invoices.amount', 'invoices.paid_amount');

    return (response as List).map((json) => Customer.fromJson(json)).toList();
  }
}