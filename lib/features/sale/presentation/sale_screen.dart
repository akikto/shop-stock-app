import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/product.dart';
import '../../../repositories/transaction_repository.dart';
import '../../../sync/models/transaction_write_result.dart';
import '../../products/presentation/widgets/product_picker_grid.dart';
import '../../products/providers/product_providers.dart';
import '../../transactions/providers/transaction_providers.dart';

/// Quick Sale: tap a product photo -> set quantity -> confirm.
/// Stock is decremented exclusively via the record_sale() RPC
/// (migration 0008) — this screen never writes current_stock itself.
class SaleScreen extends ConsumerWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sale)),
      body: ProductPickerGrid(
        onProductSelected: (product) => _openSaleSheet(context, ref, product),
      ),
    );
  }

  Future<void> _openSaleSheet(
      BuildContext context, WidgetRef ref, Product product) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SaleSheet(product: product),
    );
  }
}

class _SaleSheet extends ConsumerStatefulWidget {
  const _SaleSheet({required this.product});
  final Product product;

  @override
  ConsumerState<_SaleSheet> createState() => _SaleSheetState();
}

class _SaleSheetState extends ConsumerState<_SaleSheet> {
  int _quantity = 1;
  bool _isSubmitting = false;
  String? _error;

  num get _availableStock => widget.product.currentStock;
  bool get _exceedsStock => _quantity > _availableStock;

  void _increment() => setState(() => _quantity++);
  void _decrement() =>
      setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1);

  Future<void> _confirm() async {
    if (_exceedsStock) {
      setState(() => _error = AppStrings.insufficientStock);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result = await ref.read(transactionRepositoryProvider).recordSale(
            productId: widget.product.id,
            quantity: _quantity,
          );
      await ref.read(productListControllerProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        final message = result == TransactionWriteResult.queuedLocally
            ? AppStrings.savedLocallyWillSync
            : AppStrings.saleSuccessful;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } on TransactionException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.product.salePrice * _quantity;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.product.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.availableStock}: ${widget.product.currentStock}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                  onPressed: _decrement, icon: const Icon(Icons.remove)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_quantity',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              IconButton.filledTonal(
                  onPressed: _increment, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${AppStrings.total}: ৳$total',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _confirm,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(AppStrings.confirmSale),
          ),
        ],
      ),
    );
  }
}
