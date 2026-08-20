import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../models/product.dart';
import '../../providers/product_providers.dart';
import '../product_card.dart';

/// Search + photo-grid product picker. Tapping a product card calls
/// [onProductSelected]. Reuses the exact same [productListControllerProvider]
/// and [ProductCard] as the Products tab, so behavior (search, lazy
/// pagination, low-stock badge) stays consistent everywhere a product
/// needs to be picked.
class ProductPickerGrid extends ConsumerStatefulWidget {
  const ProductPickerGrid({super.key, required this.onProductSelected});

  final ValueChanged<Product> onProductSelected;

  @override
  ConsumerState<ProductPickerGrid> createState() => _ProductPickerGridState();
}

class _ProductPickerGridState extends ConsumerState<ProductPickerGrid> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(productListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListControllerProvider);

    return Column(
      children: [
        if (state.usingCachedData)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              AppStrings.staleCachedData,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: AppStrings.searchProducts,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
            ),
            onChanged: (value) {
              ref
                  .read(productListControllerProvider.notifier)
                  .setSearchQuery(value);
            },
          ),
        ),
        Expanded(child: _buildBody(state)),
      ],
    );
  }

  Widget _buildBody(ProductListState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(productListControllerProvider.notifier).refresh(),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.products.isEmpty) {
      return const Center(child: Text(AppStrings.noProductsFound));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: state.products.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.products.length) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }
        final product = state.products[index];
        return ProductCard(
          product: product,
          onTap: () => widget.onProductSelected(product),
        );
      },
    );
  }
}
