import 'package:flutter/material.dart';

import '../../../../models/activity_action.dart';
import '../../../../models/activity_log.dart';
import '../activity_log_format.dart';

/// One row in the History list with a distinct visual treatment for
/// sale / stock-in / stock-adjustment entries.
class ActivityLogTile extends StatelessWidget {
  const ActivityLogTile({super.key, required this.log});

  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final accent = ActivityAction.accentColor(log.action);
    final isTransaction = ActivityAction.isTransactionAction(log.action);
    final theme = Theme.of(context);

    final detailLines = <String>[
      if (log.displayProductName != null) log.displayProductName!,
      if (ActivityLogFormat.quantityLine(log) case final line?) line,
      if (ActivityLogFormat.saleAmountLine(log) case final line?) line,
      if (ActivityLogFormat.reasonLine(log) case final line?) line,
      if (ActivityLogFormat.actorLine(log) case final line?) line,
      ActivityLogFormat.dateTime(log.createdAt),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: isTransaction ? 1 : 0,
      color: isTransaction
          ? accent.withValues(alpha: 0.06)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTransaction
            ? BorderSide(color: accent.withValues(alpha: 0.35))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(
                ActivityAction.icon(log.action),
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ActivityAction.label(log.action),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isTransaction ? accent : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final line in detailLines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
