// screens/cashbook_view_screen.dart
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/cash_entry.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/cash_entry_dialog.dart';

class CashbookViewScreen extends StatefulWidget {
  final Book book;
  const CashbookViewScreen({super.key, required this.book});

  @override
  State<CashbookViewScreen> createState() => _CashbookViewScreenState();
}

class _CashbookViewScreenState extends State<CashbookViewScreen> {
  List<CashEntry> _entries = [];
  bool _loading = true;

  double get _totalIn => _entries
      .where((e) => e.type == CashEntryType.inFlow)
      .fold(0.0, (s, e) => s + e.amount);
  double get _totalOut => _entries
      .where((e) => e.type == CashEntryType.outFlow)
      .fold(0.0, (s, e) => s + e.amount);
  // Net is computed inside the totals card; keep local helpers for clarity.

  @override
  void initState() {
    super.initState();
    _load();
    SupabaseService().streamEntries(widget.book.id).listen((entries) {
      if (!mounted) return;
      setState(() {
        _entries = entries;
      });
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final entries = await SupabaseService().getEntries(widget.book.id);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addEntry(CashEntryType type) async {
    final created = await showDialog<CashEntry>(
      context: context,
      builder: (_) => CashEntryDialog(bookId: widget.book.id, type: type),
    );
    if (created != null) {
      setState(() {
        _entries = [created, ..._entries.where((e) => e.id != created.id)];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar placeholder (non-functional for now)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by remark or amount',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                    enabled: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TotalsCard(totalIn: _totalIn, totalOut: _totalOut),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('No entries yet'))
                      : Builder(
                          builder: (context) {
                            final List<Object> items = [];
                            DateTime? last;
                            for (final e in _entries) {
                              final d = DateTime(
                                e.entryDate.year,
                                e.entryDate.month,
                                e.entryDate.day,
                              );
                              if (last == null ||
                                  d.difference(last).inDays != 0) {
                                items.add(d);
                                last = d;
                              }
                              items.add(e);
                            }
                            return ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                if (item is DateTime) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Center(
                                      child: Text(
                                        DateFormatter.formatLongDate(item),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final e = item as CashEntry;
                                final isIn = e.type == CashEntryType.inFlow;
                                final color = isIn
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444);
                                final amountText = DateFormatter.formatCurrency(
                                  e.amount,
                                );
                                return Column(
                                  children: [
                                    Dismissible(
                                      key: ValueKey('entry-' + e.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        color: const Color(0xFFDC2626),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: const Icon(
                                          Icons.cancel,
                                          color: Colors.white,
                                        ),
                                      ),
                                      confirmDismiss: (_) async {
                                        return await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Cancel Entry',
                                                ),
                                                content: const Text(
                                                  'Do you want to cancel (delete) this entry?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(false),
                                                    child: const Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(true),
                                                    child: const Text(
                                                      'Yes, cancel',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ) ??
                                            false;
                                      },
                                      onDismissed: (_) async {
                                        try {
                                          await SupabaseService().deleteEntry(
                                            e.id,
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Entry cancelled'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (err) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to cancel: ' +
                                                    err.toString(),
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Cash',
                                            style: TextStyle(
                                              color: Color(0xFF0369A1),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          DateFormatter.formatTime(e.createdAt),
                                          style: const TextStyle(
                                            color: Color(0xFF7C3AED),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle:
                                            (e.note != null &&
                                                e.note!.trim().isNotEmpty)
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  e.note!.trim(),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              )
                                            : null,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              amountText,
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              tooltip: 'Cancel entry',
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Color(0xFFDC2626),
                                              ),
                                              onPressed: () async {
                                                final ok =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text(
                                                          'Cancel Entry',
                                                        ),
                                                        content: const Text(
                                                          'Do you want to cancel (delete) this entry?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  ctx,
                                                                ).pop(false),
                                                            child: const Text(
                                                              'No',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  ctx,
                                                                ).pop(true),
                                                            child: const Text(
                                                              'Yes, cancel',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ) ??
                                                    false;
                                                if (!ok) return;
                                                try {
                                                  await SupabaseService()
                                                      .deleteEntry(e.id);
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Entry cancelled',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                } catch (err) {
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to cancel: ' +
                                                            err.toString(),
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addEntry(CashEntryType.inFlow),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('CASH IN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addEntry(CashEntryType.outFlow),
                  icon: const Icon(Icons.remove, color: Colors.white),
                  label: const Text('CASH OUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final double totalIn;
  final double totalOut;
  const _TotalsCard({required this.totalIn, required this.totalOut});

  @override
  Widget build(BuildContext context) {
    final net = totalIn - totalOut;
    final netText =
        (net == 0
                ? '0'
                : (net > 0 ? '' : '-') +
                      DateFormatter.formatCurrency(net.abs()))
            .toString();
    final Color netColor = net > 0
        ? const Color(0xFF10B981)
        : (net < 0 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6));
    return Container(
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Net Balance',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  netText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: netColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(child: Text('Total In (+)')),
                      Text(
                        DateFormatter.formatCurrency(totalIn),
                        style: const TextStyle(color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(child: Text('Total Out (-)')),
                      Text(
                        DateFormatter.formatCurrency(totalOut),
                        style: const TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
