import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/dashboard_providers.dart';
import '../../products/presentation/product_detail_screen.dart';

/// Manager/Owner list of products at or below their low-stock limit.
class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.lowStockProducts)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(lowStockProductsProvider),
        child: productsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(lowStockProductsProvider),
          ),
          data: (products) {
            if (products.isEmpty) {
              return const ListView(
                children: [
                  SizedBox(height: 120),
                  Center(child: Text(AppStrings.noLowStockProducts)),
                ],
              );
            }
            return ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _LowStockTile(product: products[index]),
            );
          },
        ),
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.warning_amber, color: Colors.red.shade700),
      title: Text(product.name),
      subtitle: Text(
        '${AppStrings.currentStock}: ${product.currentStock} / ${AppStrings.lowStockLimit}: ${product.lowStockLimit}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
    );
  }
}
