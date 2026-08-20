import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../sync/models/pending_transaction_status.dart';
import '../../../sync/models/pending_transaction_type.dart';
import '../../../sync/providers/sync_providers.dart';

class PendingTransactionsScreen extends ConsumerWidget {
  const PendingTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingTransactionsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.pendingTransactions)),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text(AppStrings.transactionSynced));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final title = item.productName ?? item.productId;
              final detail = _detailFor(
                  item.type, item.quantity, item.quantityChange, item.reason);
              final statusLabel = item.status == PendingTransactionStatus.failed
                  ? AppStrings.syncFailed
                  : AppStrings.pendingSync;

              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(
                      '$statusLabel\n$detail${item.lastError != null ? '\n${item.lastError}' : ''}'),
                  isThreeLine: true,
                  trailing: item.status == PendingTransactionStatus.failed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: AppStrings.retryFailedTransaction,
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                await ref
                                    .read(syncEngineProvider)
                                    .retryFailed(item.localId);
                                ref.invalidate(pendingTransactionsListProvider);
                                ref.invalidate(pendingTransactionCountProvider);
                              },
                            ),
                            IconButton(
                              tooltip: AppStrings.deleteFailedTransaction,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(pendingTransactionRepositoryProvider)
                                    .deleteFailed(item.localId);
                                ref.invalidate(pendingTransactionsListProvider);
                                ref.invalidate(pendingTransactionCountProvider);
                              },
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _detailFor(
    PendingTransactionType type,
    num? quantity,
    num? quantityChange,
    String? reason,
  ) {
    switch (type) {
      case PendingTransactionType.sale:
        return '${AppStrings.sale}: $quantity';
      case PendingTransactionType.stockIn:
        return '${AppStrings.stockIn}: $quantity';
      case PendingTransactionType.adjustment:
        return '${AppStrings.stockAdjustment}: $quantityChange — $reason';
    }
  }
}
