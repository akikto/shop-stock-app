import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../services/supabase_service.dart';

class ProductException implements Exception {
  ProductException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sole point of contact with product data. Abstract so tests (and
/// future Sale/Stock screens) can depend on this interface rather than
/// a concrete Supabase implementation — see test/products for a fake.
abstract class ProductRepository {
  Future<List<Product>> fetchProducts({
    String search = '',
    bool activeOnly = true,
    int limit = 20,
    int offset = 0,
  });

  Future<Product?> fetchProductById(String id);

  /// Creates a product via the create_product() RPC. current_stock is
  /// never a parameter here — it isn't accepted by the server function
  /// either, see migration 0006.
  Future<Product> createProduct({
    required String name,
    String? photoUrl,
    String? photoThumbUrl,
    String? company,
    String? category,
    String? packSize,
    num? mrp,
    num? purchasePrice,
    required num salePrice,
    num lowStockLimit = 0,
  });

  Future<Product> updateProduct({
    required String id,
    required String name,
    String? photoUrl,
    String? photoThumbUrl,
    String? company,
    String? category,
    String? packSize,
    num? mrp,
    num? purchasePrice,
    required num salePrice,
    num lowStockLimit = 0,
  });

  Future<Product> deactivateProduct(String id);
}

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<Product>> fetchProducts({
    String search = '',
    bool activeOnly = true,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('products').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final trimmed = search.trim();
      if (trimmed.isNotEmpty) {
        query = query.ilike('name', '%$trimmed%');
      }

      final rows = await query.order('name').range(offset, offset + limit - 1);
      return (rows as List).map((row) => Product.fromJson(row as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ProductException('Could not load products. Please check your connection.');
    }
  }

  @override
  Future<Product?> fetchProductById(String id) async {
    try {
      final row = await _client.from('products').select().eq('id', id).maybeSingle();
      if (row == null) return null;
      return Product.fromJson(row);
    } catch (e) {
      throw ProductException('Could not load this product.');
    }
  }

  @override
  Future<Product> createProduct({
    required String name,
    String? photoUrl,
    String? photoThumbUrl,
    String? company,
    String? category,
    String? packSize,
    num? mrp,
    num? purchasePrice,
    required num salePrice,
    num lowStockLimit = 0,
  }) async {
    try {
      final row = await _client.rpc('create_product', params: {
        'p_name': name,
        'p_photo_url': photoUrl,
        'p_photo_thumb_url': photoThumbUrl,
        'p_company': company,
        'p_category': category,
        'p_pack_size': packSize,
        'p_mrp': mrp,
        'p_purchase_price': purchasePrice,
        'p_sale_price': salePrice,
        'p_low_stock_limit': lowStockLimit,
      });
      return Product.fromJson(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ProductException(_mapRpcError(e));
    } catch (e) {
      throw ProductException('Could not create the product. Please try again.');
    }
  }

  @override
  Future<Product> updateProduct({
    required String id,
    required String name,
    String? photoUrl,
    String? photoThumbUrl,
    String? company,
    String? category,
    String? packSize,
    num? mrp,
    num? purchasePrice,
    required num salePrice,
    num lowStockLimit = 0,
  }) async {
    try {
      final row = await _client.rpc('update_product', params: {
        'p_id': id,
        'p_name': name,
        'p_photo_url': photoUrl,
        'p_photo_thumb_url': photoThumbUrl,
        'p_company': company,
        'p_category': category,
        'p_pack_size': packSize,
        'p_mrp': mrp,
        'p_purchase_price': purchasePrice,
        'p_sale_price': salePrice,
        'p_low_stock_limit': lowStockLimit,
      });
      return Product.fromJson(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ProductException(_mapRpcError(e));
    } catch (e) {
      throw ProductException('Could not update the product. Please try again.');
    }
  }

  @override
  Future<Product> deactivateProduct(String id) async {
    try {
      final row = await _client.rpc('deactivate_product', params: {'p_id': id});
      return Product.fromJson(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ProductException(_mapRpcError(e));
    } catch (e) {
      throw ProductException('Could not deactivate the product. Please try again.');
    }
  }

  String _mapRpcError(PostgrestException e) {
    // The RPC functions raise plain, already-user-readable messages
    // (see migration 0006) — surface them directly rather than a
    // generic wrapper, but fall back safely if something unexpected
    // comes back.
    if (e.message.isNotEmpty) return e.message;
    return 'Something went wrong. Please try again.';
  }
}
