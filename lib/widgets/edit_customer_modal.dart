// widgets/edit_customer_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class EditCustomerModal extends StatefulWidget {
  final Customer customer;

  const EditCustomerModal({super.key, required this.customer});

  @override
  State<EditCustomerModal> createState() => _EditCustomerModalState();
}

class _EditCustomerModalState extends State<EditCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;
  late DateTime _startDate;
  late DateTime _endDate;
  late int _repeat;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _amountController = TextEditingController(
      text: widget.customer.amount != null
          ? widget.customer.amount!.toString()
          : '',
    );
    _descriptionController = TextEditingController(
      text: widget.customer.description ?? '',
    );
    _startDate = widget.customer.startDate;
    _endDate = widget.customer.endDate;
    _repeat = widget.customer.repeat;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_endDate.isBefore(_startDate)) {
        throw Exception('End date cannot be before start date');
      }

      final updated = widget.customer.copyWith(
        name: _nameController.text.trim(),
        amount: _amountController.text.trim().isEmpty
            ? null
            : double.parse(_amountController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        repeat: _repeat,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Check if significant changes were made that require invoice regeneration
      final needsInvoiceRegeneration =
          updated.amount != widget.customer.amount ||
          updated.startDate != widget.customer.startDate ||
          updated.repeat != widget.customer.repeat;

      // Update customer first (fast operation)
      final saved = await SupabaseService().updateCustomer(updated);

      if (mounted) {
        // Update UI immediately for better UX
        Provider.of<AppState>(context, listen: false).onCustomerUpdated(saved);

        // Close modal immediately
        Navigator.of(context).pop(saved);

        // Run heavy operations in background if needed
        if (needsInvoiceRegeneration) {
          // Show background processing message
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text(
          //       'Customer updated! Updating invoices in background...',
          //     ),
          //     backgroundColor: Colors.blue,
          //     duration: Duration(seconds: 1),
          //   ),
          // );

          // Run invoice regeneration in background
          _regenerateInvoicesInBackground(saved);
        } else {
          // Show success message for minor changes
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          // Just recompute totals for minor changes
          Provider.of<AppState>(context, listen: false).recomputeTotals();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating customer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Run invoice regeneration in background
  Future<void> _regenerateInvoicesInBackground(Customer customer) async {
    try {
      await SupabaseService().regenerateInvoicesForCustomer(customer);
      await Provider.of<AppState>(context, listen: false).recomputeTotals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Customer and invoices updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Customer updated but invoice update failed: ${e.toString()}',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Recalculate end date based on new start date and current repeat value
        _endDate = _calculateEndDate();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // Calculate end date based on start date and repeat value
  DateTime _calculateEndDate() {
    return DateTime(
      _startDate.year,
      _startDate.month + _repeat,
      _startDate.day,
    );
  }

  // Update end date when repeat changes
  void _onRepeatChanged(int? newRepeat) {
    if (newRepeat != null) {
      setState(() {
        _repeat = newRepeat;
        _endDate = _calculateEndDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Fixed at top
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Customer',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter customer name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Start Date Field
                        InkWell(
                          onTap: _selectStartDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Repeat Field
                        Row(
                          children: [
                            const Icon(Icons.repeat),
                            const SizedBox(width: 8),
                            const Text('Repeat:'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _repeat,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: List.generate(12, (index) => index + 1)
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(
                                          '$value month${value > 1 ? 's' : ''}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _onRepeatChanged,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // End Date Field
                        InkWell(
                          onTap: _selectEndDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              prefixIcon: Icon(Icons.event),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Amount (Optional)',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 1000',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                            hintText: 'Enter any additional details...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Buttons - Fixed at bottom
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
