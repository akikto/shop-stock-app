import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/products/providers/product_providers.dart';

/// Displays a product photo (or a neutral placeholder if [path] is
/// null) by resolving a short-lived signed URL for the given storage
/// path and caching the actual image bytes on disk keyed by [path]
/// itself — not by the signed URL, which changes every time it's
/// re-signed. This is what keeps repeat views of the same photo from
/// re-downloading it, satisfying the "very little bandwidth" goal.
class ProductPhoto extends ConsumerWidget {
  const ProductPhoto({
    super.key,
    required this.path,
    this.size = 96,
    this.borderRadius = 12,
  });

  final String? path;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(borderRadius);

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedSize = _resolveSize(constraints);

        if (path == null || path!.isEmpty) {
          return _placeholder(context, radius, resolvedSize);
        }

        return ClipRRect(
          borderRadius: radius,
          child: FutureBuilder<String?>(
            future: ref.read(productPhotoServiceProvider).resolveSignedUrl(path),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return SizedBox(
                  width: resolvedSize,
                  height: resolvedSize,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final url = snapshot.data;
              if (url == null) {
                return _placeholder(context, radius, resolvedSize);
              }
              return CachedNetworkImage(
                imageUrl: url,
                cacheKey: path, // stable key even though the signed URL rotates
                width: resolvedSize,
                height: resolvedSize,
                fit: BoxFit.cover,
                placeholder: (context, _) => SizedBox(
                  width: resolvedSize,
                  height: resolvedSize,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, _, __) => _placeholder(context, radius, resolvedSize),
              );
            },
          ),
        );
      },
    );
  }

  double _resolveSize(BoxConstraints constraints) {
    if (size.isFinite) return size;

    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;
    if (maxW.isFinite && maxH.isFinite) {
      return maxW < maxH ? maxW : maxH;
    }
    if (maxW.isFinite) return maxW;
    if (maxH.isFinite) return maxH;
    return 96;
  }

  Widget _placeholder(BuildContext context, BorderRadius radius, double resolvedSize) {
    return Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: resolvedSize * 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
