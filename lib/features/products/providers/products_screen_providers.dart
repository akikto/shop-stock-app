import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';
import 'product_providers.dart';

const int _pageSize = 20;

class ProductsScreenState {
  const ProductsScreenState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.searchQuery = '',
    this.activeOnly = true,
    this.category,
    this.categories = const [],
  });

  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String searchQuery;
  final bool activeOnly;
  final String? category;
  final List<String> categories;

  ProductsScreenState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    String? searchQuery,
    bool? activeOnly,
    String? category,
    bool clearCategory = false,
    List<String>? categories,
  }) {
    return ProductsScreenState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      activeOnly: activeOnly ?? this.activeOnly,
      category: clearCategory ? null : (category ?? this.category),
      categories: categories ?? this.categories,
    );
  }
}

/// Drives the Products tab specifically: search, category filter, an
/// active/inactive toggle (needed so a Manager/Owner can find and
/// reactivate a deactivated product — Phase 3), and pagination.
///
/// Deliberately separate from [ProductListController]
/// (product_providers.dart), which Sale/Stock's product picker reuses
/// and which must always stay active-only — sharing one controller
/// between "browse everything, including inactive" and "pick a
/// product to sell/stock" would let a toggle here leak into Sale/Stock.
class ProductsScreenController extends StateNotifier<ProductsScreenState> {
  ProductsScreenController(this._repo) : super(const ProductsScreenState()) {
    _loadCategories();
    loadFirstPage();
  }

  final ProductRepository _repo;

  Future<void> _loadCategories() async {
    final categories = await _repo.fetchDistinctCategories();
    state = state.copyWith(categories: categories);
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final products = await _repo.fetchProducts(
        search: state.searchQuery,
        activeOnly: state.activeOnly,
        category: state.category,
        offset: 0,
        limit: _pageSize,
      );
      state = state.copyWith(
          products: products,
          isLoading: false,
          hasMore: products.length == _pageSize);
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
        activeOnly: state.activeOnly,
        category: state.category,
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

  Future<void> setActiveOnly(bool activeOnly) async {
    if (activeOnly == state.activeOnly) return;
    state = state.copyWith(activeOnly: activeOnly);
    await loadFirstPage();
  }

  Future<void> setCategory(String? category) async {
    if (category == state.category) return;
    state = state.copyWith(category: category, clearCategory: category == null);
    await loadFirstPage();
  }

  Future<void> refresh() async {
    await _loadCategories();
    await loadFirstPage();
  }
}

final productsScreenControllerProvider =
    StateNotifierProvider<ProductsScreenController, ProductsScreenState>((ref) {
  return ProductsScreenController(ref.watch(productRepositoryProvider));
});
