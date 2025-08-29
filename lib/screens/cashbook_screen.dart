// screens/cashbook_screen.dart
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/cash_entry.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/new_book_dialog.dart';
import 'cashbook_view_screen.dart';

class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  List<Book> _books = [];
  List<Book> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    SupabaseService().streamBooks().listen((books) {
      if (!mounted) return;
      setState(() {
        _books = books;
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final books = await SupabaseService().getBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _applyFilter();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addBook() async {
    final created = await showDialog<Book>(
      context: context,
      builder: (ctx) => const NewBookDialog(),
    );
    if (created != null) {
      setState(() {
        _books = [created, ..._books.where((b) => b.id != created.id)];
        _applyFilter();
      });
      _showSnack(
        const Icon(Icons.check_circle, color: Colors.white),
        'Book added successfully!',
        Colors.green,
      );
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = _books;
    } else {
      _filtered = _books
          .where((b) => b.name.toLowerCase().contains(q))
          .toList(growable: false);
    }
  }

  void _showSnack(Icon icon, String message, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashbook'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Search bar (styled similar to Home screen)
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
                      onChanged: (_) => setState(_applyFilter),
                      decoration: InputDecoration(
                        hintText: 'Search books...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
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
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 60),
                        const Text('No books found'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _addBook,
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Book'),
                        ),
                      ],
                    )
                  else
                    ..._filtered.map(
                      (book) => _BookCard(
                        child: _BookListTile(
                          book: book,
                          onEdited: (updated) {
                            final idx = _books.indexWhere(
                              (b) => b.id == updated.id,
                            );
                            if (idx != -1) {
                              setState(() {
                                _books[idx] = updated;
                                _applyFilter();
                              });
                              _showSnack(
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                'Book updated',
                                Colors.green,
                              );
                            }
                          },
                          onDeleted: () {
                            setState(() {
                              _books = _books
                                  .where((b) => b.id != book.id)
                                  .toList();
                              _applyFilter();
                            });
                            _showSnack(
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              'Book deleted',
                              Colors.green,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Widget child;
  const _BookCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: child,
    );
  }
}

class _BookListTile extends StatelessWidget {
  final Book book;
  final ValueChanged<Book> onEdited;
  final VoidCallback onDeleted;
  const _BookListTile({
    required this.book,
    required this.onEdited,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CashEntry>>(
      stream: SupabaseService().streamEntries(book.id),
      builder: (context, snapshot) {
        double totalIn = 0;
        double totalOut = 0;
        if (snapshot.hasData) {
          final entries = snapshot.data!;
          for (final e in entries) {
            if (e.type == CashEntryType.inFlow) {
              totalIn += e.amount;
            } else {
              totalOut += e.amount;
            }
          }
        }
        final net = totalIn - totalOut;
        final netText =
            (net >= 0 ? '+' : '-') + DateFormatter.formatCurrency(net.abs());
        final Color netColor = net > 0
            ? const Color(0xFF10B981)
            : (net < 0 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6));
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          title: Text(
            book.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Created ' + DateFormatter.formatDisplayDate(book.createdAt),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Net Balance',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    netText,
                    style: TextStyle(
                      color: netColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                tooltip: 'Edit book',
                onPressed: () async {
                  final updated = await showDialog<Book>(
                    context: context,
                    builder: (_) => NewBookDialog(initial: book),
                  );
                  if (updated != null && context.mounted) {
                    onEdited(updated);
                  }
                },
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.08),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                tooltip: 'Delete book',
                onPressed: () async {
                  final confirm =
                      await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Book'),
                          content: Text(
                            'Delete "' +
                                book.name +
                                '"? This will remove all its entries.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirm) {
                    try {
                      await SupabaseService().deleteBook(book.id);
                      if (context.mounted) {
                        onDeleted();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete: ' + e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CashbookViewScreen(book: book)),
            );
          },
        );
      },
    );
  }
}
