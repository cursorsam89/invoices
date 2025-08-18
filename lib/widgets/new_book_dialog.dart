// widgets/new_book_dialog.dart
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/supabase_service.dart';

class NewBookDialog extends StatefulWidget {
  final Book? initial;
  const NewBookDialog({super.key, this.initial});

  @override
  State<NewBookDialog> createState() => _NewBookDialogState();
}

class _NewBookDialogState extends State<NewBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.initial == null) {
        final userId = SupabaseService().currentUser!.id;
        final created = await SupabaseService().createBook(
          Book(
            id: '',
            userId: userId,
            name: _name.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) Navigator.of(context).pop(created);
      } else {
        final updated = await SupabaseService().updateBook(
          widget.initial!.copyWith(
            name: _name.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          ),
        );
        if (mounted) Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create book: ' + e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initial != null && _name.text.isEmpty && _desc.text.isEmpty) {
      _name.text = widget.initial!.name;
      _desc.text = widget.initial!.description ?? '';
    }
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.book_outlined),
                  SizedBox(width: 8),
                  Text(
                    'Book',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Book name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter book name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.initial == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
