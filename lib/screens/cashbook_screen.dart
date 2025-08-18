// screens/cashbook_screen.dart
import 'package:flutter/material.dart';

class CashbookScreen extends StatelessWidget {
  const CashbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashbook'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('To be implemented', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
