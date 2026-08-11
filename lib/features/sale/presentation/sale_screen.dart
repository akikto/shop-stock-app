import 'package:flutter/material.dart';

/// Placeholder Quick Sale screen.
/// Phase 0 scope: static UI only. The actual Sale flow
/// (photo -> quantity -> confirm, via secure server-side RPC) is
/// implemented in a later phase, not here.
class SaleScreen extends StatelessWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Quick Sale coming soon.\n\nTap a product photo, set the '
            'quantity, and confirm — stock will update automatically.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
