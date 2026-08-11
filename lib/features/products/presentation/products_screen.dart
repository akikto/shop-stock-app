import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/product_providers.dart';
import 'product_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      ref.read(productListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListControllerProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final canManageProducts = profileAsync.maybeWhen(
      data: (profile) => profile.role.canManageProducts,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.products),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.searchProducts,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onChanged: (value) {
                ref.read(productListControllerProvider.notifier).setSearchQuery(value);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: canManageProducts
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/products/new'),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text(AppStrings.addProduct),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(productListControllerProvider.notifier).refresh(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ProductListState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.products.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(state.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.read(productListControllerProvider.notifier).refresh(),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state.products.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text(AppStrings.noProductsFound)),
        ],
      );
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
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        final product = state.products[index];
        return ProductCard(
          product: product,
          onTap: () => context.push('/products/${product.id}'),
        );
      },
    );
  }
}
