import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../services/supabase_service.dart';

class ProductException implements Exception {
  ProductException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sole point of contact with product data. Abstract so tests can
/// depend on this interface rather than a concrete Supabase
/// implementation — see test/features/sale for a fake.
abstract class ProductRepository {
  /// [activeOnly] defaults to true (normal Sale/Stock/Products browsing).
  /// Pass false to include deactivated products too — needed so a
  /// Manager/Owner can find and reactivate one (Phase 3).
  /// [category], if non-null and non-empty, filters to that exact
  /// category — Phase 3's "product filtering" requirement.
  Future<List<Product>> fetchProducts({
    String search = '',
    bool activeOnly = true,
    String? category,
    int limit = 20,
    int offset = 0,
  });

  Future<Product?> fetchProductById(String id);

  /// Returns the distinct, non-null category values currently in use
  /// — powers the filter dropdown without hardcoding a category list.
  Future<List<String>> fetchDistinctCategories();

  /// Creates a product via the create_product() RPC. current_stock is
  /// never a parameter here — it isn't accepted by the server function
  /// either, see migrations 0006/0009.
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
    DateTime? expiryDate,
    String? composition,
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
    DateTime? expiryDate,
    String? composition,
  });

  Future<Product> deactivateProduct(String id);

  /// Reactivates a previously-deactivated product (migration 0009).
  Future<Product> activateProduct(String id);

  /// Manager/Owner low-stock alert list (migration 0012).
  Future<List<Product>> fetchLowStockProducts();
}

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<Product>> fetchProducts({
    String search = '',
    bool activeOnly = true,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('products').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      final trimmed = search.trim();
      if (trimmed.isNotEmpty) {
        query = query.ilike('name', '%$trimmed%');
      }

      final rows = await query.order('name').range(offset, offset + limit - 1);
      return (rows as List)
          .map((row) => Product.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ProductException(
          'Could not load products. Please check your connection.');
    }
  }

  @override
  Future<Product?> fetchProductById(String id) async {
    try {
      final row =
          await _client.from('products').select().eq('id', id).maybeSingle();
      if (row == null) return null;
      return Product.fromJson(row);
    } catch (e) {
      throw ProductException('Could not load this product.');
    }
  }

  @override
  Future<List<String>> fetchDistinctCategories() async {
    try {
      final rows = await _client
          .from('products')
          .select('category')
          .not('category', 'is', null);
      final categories = (rows as List)
          .map((row) => (row as Map<String, dynamic>)['category'] as String?)
          .whereType<String>()
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return categories;
    } catch (e) {
      // Category list is a filter-UI nicety — fail soft to an empty
      // list rather than breaking the Products screen over it.
      return [];
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
    DateTime? expiryDate,
    String? composition,
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
        'p_expiry_date': expiryDate?.toIso8601String().split('T').first,
        'p_composition': composition,
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
    DateTime? expiryDate,
    String? composition,
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
        'p_expiry_date': expiryDate?.toIso8601String().split('T').first,
        'p_composition': composition,
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
      throw ProductException(
          'Could not deactivate the product. Please try again.');
    }
  }

  @override
  Future<Product> activateProduct(String id) async {
    try {
      final row = await _client.rpc('activate_product', params: {'p_id': id});
      return Product.fromJson(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ProductException(_mapRpcError(e));
    } catch (e) {
      throw ProductException(
          'Could not activate the product. Please try again.');
    }
  }

  @override
  Future<List<Product>> fetchLowStockProducts() async {
    try {
      final result = await _client.rpc('list_low_stock_products');
      return (result as List)
          .map((row) => Product.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ProductException(
          e.message.isNotEmpty ? e.message : 'Could not load low-stock products.');
    } catch (_) {
      throw ProductException('Could not load low-stock products.');
    }
  }

  String _mapRpcError(PostgrestException e) {
    if (e.message.isNotEmpty) return e.message;
    return 'Something went wrong. Please try again.';
  }
}
