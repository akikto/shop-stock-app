import 'package:flutter/material.dart';

/// Placeholder Stock screen (Stock In + Adjustment entry point).
/// Phase 0 scope: static UI only. Actual stock-changing operations are
/// implemented in a later phase via secure server-side RPC functions.
class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Quick Stock In & Adjustment coming soon.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
