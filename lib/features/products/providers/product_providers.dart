import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';
import '../../../services/image_compressor.dart';
import '../../../services/product_photo_service.dart';
import '../../../services/product_photo_uploader.dart';
import '../../../services/supabase_service.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository();
});

final productPhotoServiceProvider = Provider<ProductPhotoService>((ref) {
  return ProductPhotoService(
    compressor: FlutterImageCompressor(),
    uploader: SupabaseProductPhotoUploader(SupabaseService.client),
  );
});

/// A single product, refetched by id — used by the detail screen so it
/// reflects edits made on the edit screen when the user navigates back.
final productDetailProvider =
    FutureProvider.autoDispose.family<Product?, String>((ref, id) async {
  return ref.watch(productRepositoryProvider).fetchProductById(id);
});

const int _pageSize = 20;

class ProductListState {
  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.searchQuery = '',
  });

  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String searchQuery;

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    String? searchQuery,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Drives the product list screen: initial load, pull-to-refresh,
/// lazy-loading the next page on scroll, and re-querying on search.
class ProductListController extends StateNotifier<ProductListState> {
  ProductListController(this._repo) : super(const ProductListState()) {
    loadFirstPage();
  }

  final ProductRepository _repo;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final products = await _repo.fetchProducts(
        search: state.searchQuery,
        offset: 0,
        limit: _pageSize,
      );
      state = state.copyWith(
        products: products,
        isLoading: false,
        hasMore: products.length == _pageSize,
      );
    } on ProductException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final more = await _repo.fetchProducts(
        search: state.searchQuery,
        offset: state.products.length,
        limit: _pageSize,
      );
      state = state.copyWith(
        products: [...state.products, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      );
    } on ProductException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.message);
    }
  }

  Future<void> setSearchQuery(String query) async {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    await loadFirstPage();
  }

  Future<void> refresh() => loadFirstPage();
}

final productListControllerProvider =
    StateNotifierProvider<ProductListController, ProductListState>((ref) {
  return ProductListController(ref.watch(productRepositoryProvider));
});
