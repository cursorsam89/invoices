// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/customer_card.dart';
import '../widgets/add_customer_modal.dart';
import '../widgets/edit_customer_modal.dart';
import 'customer_details_screen.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

enum CustomerFilter { all, overdue }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  CustomerFilter _currentFilter = CustomerFilter.all;
  // Cached datasets
  List<Customer> _allCustomers = [];
  List<Customer> _overdueCustomers = [];

  // Currently active working set (source for filtering)
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  double _amountReceived = 0;
  double _amountDue = 0;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadData();
    _setupStreams();
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupStreams() {
    SupabaseService().streamCustomers().listen((customers) async {
      _allCustomers = customers;
      if (_currentFilter == CustomerFilter.all) {
        if (!mounted) return;
        setState(() {
          _customers = _allCustomers;
          _filterCustomers();
        });
      }
      // Let app state recompute totals when customers change
      if (mounted) {
        Provider.of<AppState>(context, listen: false).recomputeTotals();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        SupabaseService().getAmountReceivedThisMonth(),
        SupabaseService().getAmountDue(),
        SupabaseService().getCustomers(),
      ]);

      final double amountReceived = results[0] as double;
      final double amountDue = results[1] as double;
      final List<Customer> customers = results[2] as List<Customer>;

      setState(() {
        _amountReceived = amountReceived;
        _amountDue = amountDue;
        _allCustomers = customers;
        _customers = _allCustomers;
        _filterCustomers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error loading data: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _filterCustomers() {
    String searchQuery = _searchController.text.toLowerCase();

    List<Customer> filtered = _customers.where((customer) {
      bool matchesSearch = customer.name.toLowerCase().contains(searchQuery);

      if (_currentFilter == CustomerFilter.overdue) {
        // For overdue filter, we need to check if customer has overdue invoices
        // This is a simplified check - in a real app, you'd want to join with invoices
        return matchesSearch;
      }

      return matchesSearch;
    }).toList();

    setState(() {
      _filteredCustomers = filtered;
    });
  }

  void _onSearchChanged(String value) {
    _filterCustomers();
  }

  void _onFilterChanged(CustomerFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    if (filter == CustomerFilter.overdue) {
      if (_overdueCustomers.isEmpty) {
        _refreshOverdue();
      } else {
        setState(() {
          _customers = _overdueCustomers;
          _filterCustomers();
        });
      }
    } else {
      setState(() {
        _customers = _allCustomers;
        _filterCustomers();
      });
    }
  }

  Future<void> _refreshOverdue() async {
    try {
      final overdue = await SupabaseService().getOverdueCustomers();
      if (!mounted) return;
      setState(() {
        _overdueCustomers = overdue;
        _customers = _overdueCustomers;
        _filterCustomers();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error loading overdue customers: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _showAddCustomerModal() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => const AddCustomerModal(),
    );

    if (result != null && mounted) {
      // Optimistic update so UI reflects immediately even if realtime stream is not active
      setState(() {
        _allCustomers = [
          result,
          ..._allCustomers.where((c) => c.id != result.id),
        ];
        if (_currentFilter == CustomerFilter.all) {
          _customers = _allCustomers;
        }
        _filterCustomers();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Customer added successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This will also delete all related invoices and transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService().deleteCustomer(customer.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Customer deleted successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Error deleting customer: ${e.toString()}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Business Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF6366F1)),
              onPressed: () async {
                await SupabaseService().signOut();
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadData();
                  if (mounted) {
                    Provider.of<AppState>(
                      context,
                      listen: false,
                    ).recomputeTotals();
                  }
                },
                color: const Color(0xFF6366F1),
                child: CustomScrollView(
                  slivers: [
                    // Header Cards
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Stats Cards
                            Row(
                              children: [
                                Expanded(
                                  child: Consumer<AppState>(
                                    builder: (context, state, _) =>
                                        _buildDashboardCard(
                                          'Amount Received',
                                          DateFormatter.formatCurrency(
                                            state.amountReceivedThisMonth,
                                          ),
                                          Icons.trending_up,
                                          const Color(0xFF10B981),
                                          const Color(0xFFD1FAE5),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Consumer<AppState>(
                                    builder: (context, state, _) =>
                                        _buildDashboardCard(
                                          'Amount Due',
                                          DateFormatter.formatCurrency(
                                            state.amountDue,
                                          ),
                                          Icons.trending_down,
                                          const Color(0xFFEF4444),
                                          const Color(0xFFFEE2E2),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Search Bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'Search customers...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.search,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Filter Tabs
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilterChip(
                                    'All Customers',
                                    CustomerFilter.all,
                                    Icons.people,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFilterChip(
                                    'Overdue',
                                    CustomerFilter.overdue,
                                    Icons.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Customer List
                    _filteredCustomers.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _customers.isEmpty
                                        ? 'No customers yet'
                                        : 'No customers found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: const Color(0xFF374151),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _customers.isEmpty
                                        ? 'Start by adding your first customer'
                                        : 'Try adjusting your search or filters',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF6B7280),
                                        ),
                                  ),
                                  if (_customers.isEmpty) ...[
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _showAddCustomerModal,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Customer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF6366F1,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final customer = _filteredCustomers[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: CustomerCard(
                                    customer: customer,
                                    onEdit: () async {
                                      final updated =
                                          await showDialog<Customer>(
                                            context: context,
                                            builder: (context) =>
                                                EditCustomerModal(
                                                  customer: customer,
                                                ),
                                          );
                                      if (updated != null && mounted) {
                                        setState(() {
                                          _allCustomers = [
                                            updated,
                                            ..._allCustomers.where(
                                              (c) => c.id != updated.id,
                                            ),
                                          ];
                                          if (_currentFilter ==
                                              CustomerFilter.all) {
                                            _customers = _allCustomers;
                                          }
                                          _filterCustomers();
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Customer updated successfully!',
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    onDelete: () => _deleteCustomer(customer),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CustomerDetailsScreen(
                                                customer: customer,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }, childCount: _filteredCustomers.length),
                            ),
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddCustomerModal,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String amount,
    IconData icon,
    Color color,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CustomerFilter filter, IconData icon) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
