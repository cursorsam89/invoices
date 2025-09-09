// widgets/customer_card.dart
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../utils/date_formatter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/overdue_summary.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  // Helper function to get the first character for the avatar
  String _getAvatarText(String name) {
    if (name.isEmpty) return '?';

    // Get the first grapheme cluster (handles multi-byte emojis properly)
    final firstGrapheme = name.characters.first;

    // Check if the first character is a letter (A-Z, a-z)
    final firstChar = firstGrapheme[0];
    final firstCharCode = firstChar.codeUnitAt(0);

    // Check if it's a letter (A-Z or a-z)
    if ((firstCharCode >= 65 && firstCharCode <= 90) || // A-Z
        (firstCharCode >= 97 && firstCharCode <= 122)) {
      // a-z
      return firstChar.toUpperCase();
    }

    // For any non-letter character (emojis, numbers, symbols, etc.), return '#'
    return '#';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, OverdueSummary> overdueMap = context
        .watch<AppState>()
        .overdueByCustomer;
    final OverdueSummary? summary = overdueMap[customer.id];
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Customer Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getAvatarText(customer.name),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Customer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row with name, class badge, and action buttons
                      Row(
                        children: [
                          // Customer name
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Class badge right after name
                          if (customer.studentClass != null &&
                              customer.studentClass!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.school,
                                    size: 12,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    customer.studentClass!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Spacer to push action buttons to the right
                          const Spacer(),
                          // Action buttons on the right
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                            onPressed: onEdit,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                            onPressed: onDelete,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ],
                      ),
                      // Second row - Date, Amount, and Days badges in one row
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Date badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatDisplayDate(
                                    customer.startDate,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Amount badge - placed next to date badge
                          if (customer.amount != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormatter.formatCurrency(customer.amount!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ],
                          // Spacer to push days badge to the right edge
                          const Spacer(),
                          // Days badge - positioned at extreme right edge
                          if (summary != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 12,
                                    color: Color(0xFFFB923C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${summary.totalOverdueDays} days',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFB923C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // Description row with OD badge at extreme right edge
                      if (customer.description != null &&
                          customer.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Description text that can wrap
                            Expanded(
                              child: Text(
                                customer.description!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // OD badge positioned at extreme right edge
                            if (summary != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 12,
                                      color: Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'OD: ' +
                                          DateFormatter.formatCurrency(
                                            summary.totalOverdueAmount,
                                          ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else if (summary != null) ...[
                        // If no description but has overdue, show OD badge at right edge
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'OD: ' +
                                      DateFormatter.formatCurrency(
                                        summary.totalOverdueAmount,
                                      ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
