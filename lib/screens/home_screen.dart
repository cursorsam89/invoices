// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/customer_card.dart';
import '../widgets/add_customer_modal.dart';
import '../widgets/edit_customer_modal.dart';
import 'customer_details_screen.dart';
import 'monthly_collection_history_screen.dart';
import 'transaction_history_screen.dart';
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
  bool _isSearchExpanded = false;
  bool _isClassFilterExpanded = false;
  String? _selectedClassFilter;
  bool _showFloatingActionButton = true;
  late ScrollController _scrollController;
  // Cached datasets
  List<Customer> _allCustomers = [];
  List<Customer> _overdueCustomers = [];

  // Currently active working set (source for filtering)
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;

  // List of available classes
  final List<String> _availableClasses = [
    'LKG',
    'UKG',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.offset;
          final isAtBottom =
              currentScroll >= maxScroll - 150 ||
              (maxScroll > 0 && currentScroll >= maxScroll * 0.95);

          // Update FAB visibility
          if (isAtBottom && _showFloatingActionButton) {
            setState(() {
              _showFloatingActionButton = false;
            });
          } else if (!isAtBottom && !_showFloatingActionButton) {
            setState(() {
              _showFloatingActionButton = true;
            });
          }
        }
      });
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
    _scrollController.dispose();
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
        SupabaseService().getCustomers(),
        SupabaseService().getOverdueCustomers(),
      ]);

      final customers = results[0];
      final overdueCustomers = results[1];

      setState(() {
        _allCustomers = customers;
        _overdueCustomers = overdueCustomers;
        // Fix: maintain correct filter after refresh
        if (_currentFilter == CustomerFilter.overdue) {
          _customers = _overdueCustomers;
        } else {
          _customers = _allCustomers;
        }
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
                Expanded(child: Text('Error loading data:  e.toString()}')),
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
      bool matchesClass =
          _selectedClassFilter == null ||
          customer.studentClass == _selectedClassFilter;

      if (_currentFilter == CustomerFilter.overdue) {
        // For overdue filter, we need to check if customer has overdue invoices
        // This is a simplified check - in a real app, you'd want to join with invoices
        return matchesSearch && matchesClass;
      }

      return matchesSearch && matchesClass;
    }).toList();

    // Sort customers by class and then by name
    filtered.sort((a, b) {
      // First, sort by class (null classes go to bottom)
      if (a.studentClass == null && b.studentClass == null) {
        // Both have no class, sort by name
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else if (a.studentClass == null) {
        // a has no class, b has class - a goes to bottom
        return 1;
      } else if (b.studentClass == null) {
        // b has no class, a has class - b goes to bottom
        return -1;
      } else {
        // Both have classes, sort by class first
        int classComparison = _compareClasses(a.studentClass!, b.studentClass!);
        if (classComparison != 0) {
          return classComparison;
        }
        // Same class, sort by name
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    setState(() {
      _filteredCustomers = filtered;
    });
  }

  int _compareClasses(String classA, String classB) {
    // Define class order
    const classOrder = [
      'LKG',
      'UKG',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
    ];

    int indexA = classOrder.indexOf(classA);
    int indexB = classOrder.indexOf(classB);

    // If both classes are in the predefined order, compare by index
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }

    // If only one is in the predefined order, it comes first
    if (indexA != -1) return -1;
    if (indexB != -1) return 1;

    // If neither is in the predefined order, compare alphabetically
    return classA.compareTo(classB);
  }

  void _onSearchChanged(String value) {
    _filterCustomers();
  }

  void _toggleSearchExpansion() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        // Close class filter when search opens
        _isClassFilterExpanded = false;
        _selectedClassFilter = null;
      } else {
        _searchController.clear();
      }
      _filterCustomers();
    });
  }

  void _toggleClassFilterExpansion() {
    setState(() {
      _isClassFilterExpanded = !_isClassFilterExpanded;
      if (_isClassFilterExpanded) {
        // Close search when class filter opens
        _isSearchExpanded = false;
        _searchController.clear();
      } else {
        _selectedClassFilter = null;
      }
      _filterCustomers();
    });
  }

  void _onClassFilterChanged(String? selectedClass) {
    setState(() {
      _selectedClassFilter = selectedClass;
      _filterCustomers();
    });
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
        if (_currentFilter == CustomerFilter.overdue) {
          _customers = _overdueCustomers;
          _filterCustomers();
        }
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
          'DASH-BOARD',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
              child: Column(
                children: [
                  // Fixed header/content
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Dashboard cards - uniform layout
                        Row(
                          children: [
                            Expanded(
                              child: Consumer<AppState>(
                                builder: (context, state, _) => _buildDashboardCard(
                                  DateFormatter.formatCurrency(
                                    state.amountReceivedThisMonth,
                                  ),
                                  Icons.trending_up,
                                  const Color(0xFF10B981),
                                  const Color(0xFFD1FAE5),
                                  assetIconPath: 'assets/receive.png',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MonthlyCollectionHistoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Consumer<AppState>(
                                builder: (context, state, _) =>
                                    _buildDashboardCard(
                                      DateFormatter.formatCurrency(
                                        state.amountExpectedThisMonth,
                                      ),
                                      Icons.account_balance_wallet,
                                      const Color(0xFF8B5CF6),
                                      const Color(0xFFEDE9FE),
                                      assetIconPath: 'assets/wallet.png',
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TransactionHistoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Consumer<AppState>(
                                builder: (context, state, _) =>
                                    _buildDashboardCard(
                                      DateFormatter.formatCurrency(
                                        state.amountDue,
                                      ),
                                      Icons.trending_down,
                                      const Color(0xFFEF4444),
                                      const Color(0xFFFEE2E2),
                                      assetIconPath: 'assets/due.png',
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Search bar and filter cards in one horizontal row
                        Row(
                          children: [
                            // Expandable search bar
                            if (_isSearchExpanded)
                              Expanded(
                                flex: 3,
                                child: Container(
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
                                    autofocus: true,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.search,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        onPressed: _toggleSearchExpansion,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              // Search icon button
                              GestureDetector(
                                onTap: _toggleSearchExpansion,
                                child: Container(
                                  width: 48,
                                  height: 48,
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
                                  child: Container(
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
                                ),
                              ),
                            const SizedBox(width: 8),
                            // Class filter icon
                            if (_isClassFilterExpanded)
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 48,
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: PopupMenuButton<String>(
                                          initialValue: _selectedClassFilter,
                                          onSelected: _onClassFilterChanged,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _selectedClassFilter != null
                                                      ? '${_selectedClassFilter!} (${_allCustomers.where((c) => c.studentClass == _selectedClassFilter).length})'
                                                      : 'Class',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF6366F1),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Color(0xFF6366F1),
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                          itemBuilder: (BuildContext context) {
                                            return _availableClasses.map((
                                              String classValue,
                                            ) {
                                              // Calculate count of students in this class
                                              final classCount = _allCustomers
                                                  .where(
                                                    (c) =>
                                                        c.studentClass ==
                                                        classValue,
                                                  )
                                                  .length;

                                              return PopupMenuItem<String>(
                                                value: classValue,
                                                child: Text(
                                                  '$classValue ($classCount)',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              );
                                            }).toList();
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Color(0xFF9CA3AF),
                                          size: 14,
                                        ),
                                        onPressed: _toggleClassFilterExpansion,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              // Class filter icon button
                              GestureDetector(
                                onTap: _toggleClassFilterExpansion,
                                child: Container(
                                  width: 48,
                                  height: 48,
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
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.school,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            // All filter card - responsive size
                            Expanded(
                              flex: _isSearchExpanded || _isClassFilterExpanded
                                  ? 1
                                  : 2,
                              child: _buildFilterChip(
                                'All',
                                CustomerFilter.all,
                                Icons.people,
                                _allCustomers.length,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Overdue filter card - responsive size
                            Expanded(
                              flex: _isSearchExpanded || _isClassFilterExpanded
                                  ? 1
                                  : 2,
                              child: _buildFilterChip(
                                'OD',
                                CustomerFilter.overdue,
                                Icons.warning,
                                _overdueCustomers.length,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scrollable customer list only
                  Expanded(
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
                      child: _filteredCustomers.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildGroupedCustomerList(),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(
          0,
          _showFloatingActionButton
              ? 0
              : 100, // Move button down when at bottom
          0,
        ),
        child: Container(
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
            onPressed: _showFloatingActionButton ? _showAddCustomerModal : null,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    String amount,
    IconData icon,
    Color color,
    Color backgroundColor, {
    String? assetIconPath,
    VoidCallback? onTap,
  }) {
    // Fixed height for uniform card sizes
    const double cardHeight = 100.0;
    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
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
      height: cardHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          assetIconPath != null
              ? Image.asset(
                  assetIconPath,
                  height: 36,
                  width: 36,
                  fit: BoxFit.contain,
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
          const SizedBox(height: 8),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(minHeight: 24, maxHeight: 32),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }

    return cardContent;
  }

  Widget _buildGroupedCustomerList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: CustomerCard(
        customer: customer,
        onEdit: () async {
          final updated = await showDialog<Customer>(
            context: context,
            builder: (context) => EditCustomerModal(customer: customer),
          );
          if (updated != null && mounted) {
            setState(() {
              _allCustomers = [
                updated,
                ..._allCustomers.where((c) => c.id != updated.id),
              ];
              if (_currentFilter == CustomerFilter.all) {
                _customers = _allCustomers;
              }
              _filterCustomers();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Customer updated successfully!'),
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
        },
        onDelete: () => _deleteCustomer(customer),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerDetailsScreen(customer: customer),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    CustomerFilter filter,
    IconData icon,
    int count,
  ) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        height: 48, // Fixed height for consistent touch targets
        padding: EdgeInsets.symmetric(
          horizontal: _isSearchExpanded ? 6 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: _isSearchExpanded ? 14 : 16,
              color: isSelected ? Colors.white : const Color(0xFF6366F1),
            ),
            SizedBox(width: _isSearchExpanded ? 2 : 4),
            Flexible(
              child: Text(
                '$label ($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                  fontSize: _isSearchExpanded ? 10 : 12,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
