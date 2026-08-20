import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../models/product.dart';

/// Compact product grid for the Sale and Stock screens. Shows active
/// products with their current stock, and calls back when one is tapped.
class ProductPickerGrid extends StatelessWidget {
  const ProductPickerGrid({
    super.key,
    required this.products,
    required this.selectedProductId,
    this.onProductSelected,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  final List<Product> products;
  final String? selectedProductId;
  final ValueChanged<Product>? onProductSelected;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.somethingWentWrong),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(AppStrings.retry)),
            ],
          ],
        ),
      );
    }
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppStrings.noProductsFound,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isSelected = product.id == selectedProductId;
        return _ProductPickerCard(
          product: product,
          isSelected: isSelected,
          onTap: () => onProductSelected?.call(product),
        );
      },
    );
  }
}

class _ProductPickerCard extends StatelessWidget {
  const _ProductPickerCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final Product product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2.5 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.inventory_2_outlined, size: 32),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    '${AppStrings.currentStock}: ${product.currentStock}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: product.isLowStock
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
