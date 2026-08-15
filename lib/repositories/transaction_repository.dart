import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../services/supabase_service.dart';

class TransactionException implements Exception {
  TransactionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sole point of contact for recording sales, stock-in, and stock
/// adjustments. Every method calls a SECURITY DEFINER RPC — there is
/// no direct client write to `products.current_stock` anywhere in
/// this class, matching migration 0008.
abstract class TransactionRepository {
  /// Records a sale of [quantity] units of [productId]. Stock is
  /// decremented atomically server-side; throws [TransactionException]
  /// with a user-readable message if stock is insufficient.
  Future<void> recordSale({required String productId, required num quantity});

  /// Records [quantity] units added to [productId]'s stock.
  Future<void> recordStockIn({required String productId, required num quantity});

  /// Adjusts [productId]'s stock by [quantityChange] (positive or
  /// negative), with a mandatory [reason]. Manager/Owner only — the
  /// server enforces this regardless of what the client sends.
  Future<void> recordAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
  });
}

class SupabaseTransactionRepository implements TransactionRepository {
  SupabaseTransactionRepository({SupabaseClient? client, Uuid? uuid})
      : _client = client ?? SupabaseService.client,
        _uuid = uuid ?? const Uuid();

  final SupabaseClient _client;
  final Uuid _uuid;

  @override
  Future<void> recordSale({required String productId, required num quantity}) async {
    try {
      await _client.rpc('record_sale', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_device_txn_id': _uuid.v4(),
      });
    } on PostgrestException catch (e) {
      throw TransactionException(_mapError(e));
    } catch (e) {
      throw TransactionException('Could not complete the sale. Please try again.');
    }
  }

  @override
  Future<void> recordStockIn({required String productId, required num quantity}) async {
    try {
      await _client.rpc('record_stock_in', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_device_txn_id': _uuid.v4(),
      });
    } on PostgrestException catch (e) {
      throw TransactionException(_mapError(e));
    } catch (e) {
      throw TransactionException('Could not add stock. Please try again.');
    }
  }

  @override
  Future<void> recordAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
  }) async {
    try {
      await _client.rpc('record_adjustment', params: {
        'p_product_id': productId,
        'p_quantity_change': quantityChange,
        'p_reason': reason,
        'p_device_txn_id': _uuid.v4(),
      });
    } on PostgrestException catch (e) {
      throw TransactionException(_mapError(e));
    } catch (e) {
      throw TransactionException('Could not adjust stock. Please try again.');
    }
  }

  String _mapError(PostgrestException e) {
    if (e.message.isNotEmpty) return e.message;
    return 'Something went wrong. Please try again.';
  }
}
