import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/transaction_repository.dart';
import '../../../sync/providers/sync_providers.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return ref.watch(offlineAwareTransactionRepositoryProvider);
});
