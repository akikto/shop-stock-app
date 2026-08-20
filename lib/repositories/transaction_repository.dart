import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/sale_record.dart';
import '../models/stock_adjustment.dart';
import '../models/stock_entry.dart';
import '../services/supabase_service.dart';

class TransactionException implements Exception {
  TransactionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sole point of contact for sale/stock-in/adjustment operations. Each
/// method calls a SECURITY DEFINER RPC (migration 0007) that atomically
/// updates current_stock and writes the transaction + activity log row.
/// current_stock is never written directly by the client.
abstract class TransactionRepository {
  Future<SaleRecord> recordSale({
    required String productId,
    required num quantity,
  });

  Future<StockEntry> recordStockIn({
    required String productId,
    required num quantity,
  });

  Future<StockAdjustment> recordAdjustment({
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
  Future<SaleRecord> recordSale({
    required String productId,
    required num quantity,
  }) async {
    try {
      final row = await _client.rpc('record_sale', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_device_txn_id': _uuid.v4(),
      });
      return SaleRecord.fromJson(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw TransactionException(_mapRpcError(e));
    } catch (e) {
      throw TransactionException('Could not record the sale. Please try again.');
    }
  }

  @override
  Future<StockEntry> recordStockIn({
    required String productId,
    required num quantity,
  }) async {
    try {
      final row = await _client.rpc('record_stock_in', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_device_txn_id': _uuid.v4(),
      });
      return StockEntry.fromJson(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw TransactionException(_mapRpcError(e));
    } catch (e) {
      throw TransactionException('Could not record stock in. Please try again.');
    }
  }

  @override
  Future<StockAdjustment> recordAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
  }) async {
    try {
      final row = await _client.rpc('record_adjustment', params: {
        'p_product_id': productId,
        'p_quantity_change': quantityChange,
        'p_reason': reason,
        'p_device_txn_id': _uuid.v4(),
      });
      return StockAdjustment.fromJson(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw TransactionException(_mapRpcError(e));
    } catch (e) {
      throw TransactionException('Could not record the adjustment. Please try again.');
    }
  }

  String _mapRpcError(PostgrestException e) {
    if (e.message.isNotEmpty) return e.message;
    return 'Something went wrong. Please try again.';
  }
}
