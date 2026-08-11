import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/product_photo.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/product_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final profileAsync = ref.watch(currentProfileProvider);
    final canManage = profileAsync.maybeWhen(
      data: (p) => p.role.canManageProducts,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.productDetails)),
      body: productAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) {
          if (product == null) {
            return const ErrorView(message: AppStrings.noProductsFound);
          }
          return _DetailBody(product: product, canManage: canManage);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.product, required this.canManage});

  final Product product;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: ProductPhoto(path: product.photoUrl ?? product.photoThumbUrl, size: 200, borderRadius: 16)),
        const SizedBox(height: 20),
        Text(product.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        if (!product.isActive)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppStrings.inactive,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ),
        const SizedBox(height: 12),
        _row(context, AppStrings.company, product.company),
        _row(context, AppStrings.category, product.category),
        _row(context, AppStrings.packSize, product.packSize),
        _row(context, AppStrings.mrp, product.mrp?.toString()),
        _row(context, AppStrings.purchasePrice, product.purchasePrice?.toString()),
        _row(context, AppStrings.salePrice, '৳${product.salePrice}'),
        _row(context, AppStrings.currentStock, '${product.currentStock}'),
        _row(context, AppStrings.lowStockLimit, '${product.lowStockLimit}'),
        _row(context, AppStrings.active, product.isActive ? AppStrings.active : AppStrings.inactive),
        _row(context, AppStrings.createdAt, _formatDate(product.createdAt)),
        _row(context, AppStrings.updatedAt, _formatDate(product.updatedAt)),
        if (canManage) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/products/${product.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text(AppStrings.edit),
          ),
          const SizedBox(height: 12),
          if (product.isActive)
            OutlinedButton.icon(
              onPressed: () => _confirmDeactivate(context, ref),
              icon: const Icon(Icons.block),
              label: const Text(AppStrings.deactivate),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
        // Deliberately no stock-editing control here — current_stock
        // is read-only display only, per spec. Stock In/Adjustment
        // screens are a later phase.
      ],
    );
  }

  Widget _row(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deactivate),
        content: const Text(AppStrings.areYouSure),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text(AppStrings.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text(AppStrings.confirm)),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(productRepositoryProvider).deactivateProduct(product.id);
      ref.invalidate(productDetailProvider(product.id));
      ref.read(productListControllerProvider.notifier).refresh();
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
