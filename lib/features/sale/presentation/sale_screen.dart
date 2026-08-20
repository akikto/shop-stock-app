import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../products/providers/product_providers.dart';
import '../../products/presentation/widgets/product_picker_grid.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../../repositories/transaction_repository.dart';

class SaleScreen extends ConsumerStatefulWidget {
  const SaleScreen({super.key});

  @override
  ConsumerState<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends ConsumerState<SaleScreen> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  bool _isSubmitting = false;
  String? _feedbackMessage;
  bool _isError = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() async {
    return ref.read(productRepositoryProvider).fetchProducts(activeOnly: true);
  }

  Future<void> _submitSale() async {
    if (_selectedProduct == null) {
      setState(() {
        _feedbackMessage = AppStrings.selectProductFirst;
        _isError = true;
      });
      return;
    }

    final quantity = num.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      setState(() {
        _feedbackMessage = AppStrings.quantityMustBePositive;
        _isError = true;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
    });

    try {
      await ref.read(transactionRepositoryProvider).recordSale(
            productId: _selectedProduct!.id,
            quantity: quantity,
          );
      if (mounted) {
        setState(() {
          _feedbackMessage = AppStrings.saleSuccess;
          _isError = false;
          _selectedProduct = null;
          _quantityController.text = '1';
        });
      }
    } on TransactionException catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = e.message;
          _isError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = AppStrings.somethingWentWrong;
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.quickSale)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.selectProduct,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Product>>(
                future: _loadProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: LoadingIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 200,
                      child: ErrorView(
                        message: AppStrings.somethingWentWrong,
                        onRetry: () => setState(() {}),
                      ),
                    );
                  }
                  final products = snapshot.data ?? [];
                  return ProductPickerGrid(
                    products: products,
                    selectedProductId: _selectedProduct?.id,
                    onProductSelected: (p) => setState(() {
                      _selectedProduct = p;
                      _feedbackMessage = null;
                    }),
                  );
                },
              ),
              if (_selectedProduct != null) ...[
                const SizedBox(height: 16),
                _SelectedProductInfo(product: _selectedProduct!),
                const SizedBox(height: 16),
                Text(
                  AppStrings.quantity,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.enterQuantity,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _quantityController.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SaleTotal(
                  product: _selectedProduct!,
                  quantity: num.tryParse(_quantityController.text.trim()) ?? 0,
                ),
                const SizedBox(height: 16),
              ],
              if (_feedbackMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isError
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _feedbackMessage!,
                    style: TextStyle(
                      color: _isError
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitSale,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSubmitting
                    ? AppStrings.confirm
                    : AppStrings.confirmSale),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedProductInfo extends StatelessWidget {
  const _SelectedProductInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.currentStock}: ${product.currentStock}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: product.isLowStock
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${AppStrings.salePrice}: ৳${product.salePrice}',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _SaleTotal extends StatelessWidget {
  const _SaleTotal({required this.product, required this.quantity});

  final Product product;
  final num quantity;

  @override
  Widget build(BuildContext context) {
    final total = product.salePrice * quantity;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.saleTotal,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '৳$total',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
