import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/features/settings/presentation/pending_transactions_screen.dart';
import 'package:shop_stock_app/sync/models/pending_transaction.dart';
import 'package:shop_stock_app/sync/models/pending_transaction_status.dart';
import 'package:shop_stock_app/sync/models/pending_transaction_type.dart';
import 'package:shop_stock_app/sync/providers/sync_providers.dart';
import 'package:shop_stock_app/sync/sync_bootstrap.dart';

void main() {
  testWidgets('pending transactions screen lists failed items', (tester) async {
    SyncBootstrap.isInitialized = true;
    final items = [
      PendingTransaction(
        localId: 1,
        deviceTxnId: 'txn-1',
        type: PendingTransactionType.sale,
        productId: 'p1',
        quantity: 2,
        createdAt: DateTime.utc(2026, 1, 1),
        status: PendingTransactionStatus.failed,
        attemptCount: 1,
        lastError: 'Insufficient stock',
        productName: 'Paracetamol',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingTransactionsListProvider.overrideWith((ref) async => items),
        ],
        child: const MaterialApp(home: PendingTransactionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.pendingTransactions), findsOneWidget);
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.textContaining(AppStrings.syncFailed), findsOneWidget);
    SyncBootstrap.isInitialized = false;
  });
}
