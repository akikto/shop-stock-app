import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';

/// Placeholder History / Audit Trail screen.
/// Phase 0 scope: static UI only. Will read from the (currently empty)
/// activity_logs table once transactions exist in a later phase.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.history)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'History / Audit Trail coming soon.\n\nEvery sale, stock '
            'entry, and adjustment will appear here permanently.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
