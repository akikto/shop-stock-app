import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/product_photo.dart';

/// Photo-first product card. Deliberately built so the photo is the
/// dominant, tappable element — this is the shape that future
/// Sale/Stock screens (Phase 2+) will reuse for "tap the photo to
/// select this product", per the app's core interaction model. No
/// Sale/Stock action is wired up here yet.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: product.isActive ? 1.0 : 0.55,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      ProductPhoto(
                          path: product.photoThumbUrl,
                          size: double.infinity,
                          borderRadius: 10),
                      if (!product.isActive)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppStrings.inactive,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (product.company != null && product.company!.isNotEmpty)
                  Text(
                    product.company!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '৳${product.salePrice}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    _StockBadge(product: product),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = product.isLowStock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLow
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${product.currentStock}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isLow
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        semanticsLabel: isLow
            ? '${AppStrings.lowStock}: ${product.currentStock}'
            : '${AppStrings.currentStock}: ${product.currentStock}',
      ),
    );
  }
}
