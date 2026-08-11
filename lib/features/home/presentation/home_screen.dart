import 'package:flutter/material.dart';

/// Placeholder Home/Dashboard screen.
/// Phase 0 scope: static UI only. KPIs, low-stock alerts, and
/// role-aware content are added in a later phase.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Dashboard coming soon.\n\nThis screen will show daily sales, '
            'low-stock alerts, and quick actions.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
