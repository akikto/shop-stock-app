import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/product.dart';
import '../../../models/user_role.dart';
import '../../../repositories/transaction_repository.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/presentation/widgets/product_picker_grid.dart';
import '../../products/providers/product_providers.dart';
import '../../transactions/providers/transaction_providers.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  _StockMode _mode = _StockMode.stockIn;
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _feedbackMessage;
  bool _isError = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() async {
    return ref.read(productRepositoryProvider).fetchProducts(activeOnly: true);
  }

  void _resetSelection() {
    setState(() {
      _selectedProduct = null;
      _quantityController.text = '1';
      _reasonController.clear();
      _feedbackMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_selectedProduct == null) {
      setState(() {
        _feedbackMessage = AppStrings.selectProductFirst;
        _isError = true;
      });
      return;
    }

    final quantity = num.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity == 0) {
      setState(() {
        _feedbackMessage = _mode == _StockMode.adjustment
            ? AppStrings.quantityChangeZero
            : AppStrings.quantityMustBePositive;
        _isError = true;
      });
      return;
    }
    if (_mode == _StockMode.stockIn && quantity <= 0) {
      setState(() {
        _feedbackMessage = AppStrings.quantityMustBePositive;
        _isError = true;
      });
      return;
    }

    if (_mode == _StockMode.adjustment) {
      final reason = _reasonController.text.trim();
      if (reason.isEmpty) {
        setState(() {
          _feedbackMessage = AppStrings.reasonRequired;
          _isError = true;
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
    });

    try {
      final repo = ref.read(transactionRepositoryProvider);
      if (_mode == _StockMode.stockIn) {
        await repo.recordStockIn(
          productId: _selectedProduct!.id,
          quantity: quantity,
        );
      } else {
        await repo.recordAdjustment(
          productId: _selectedProduct!.id,
          quantityChange: quantity,
          reason: _reasonController.text.trim(),
        );
      }
      if (mounted) {
        setState(() {
          _feedbackMessage = _mode == _StockMode.stockIn
              ? AppStrings.stockInSuccess
              : AppStrings.adjustmentSuccess;
          _isError = false;
          _selectedProduct = null;
          _quantityController.text = '1';
          _reasonController.clear();
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
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );
    final canAdjust = profile?.role.canAdjustStock ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.stockInTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_StockMode>(
                segments: [
                  ButtonSegment(
                    value: _StockMode.stockIn,
                    label: Text(AppStrings.stockInTitle),
                    icon: const Icon(Icons.add_box_outlined),
                  ),
                  ButtonSegment(
                    value: _StockMode.adjustment,
                    enabled: canAdjust,
                    label: Text(AppStrings.stockAdjustment),
                    icon: const Icon(Icons.tune),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _mode = selection.first;
                    _resetSelection();
                  });
                },
              ),
              if (_mode == _StockMode.adjustment && !canAdjust) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.onlyManagerCanAdjust,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProduct!.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppStrings.currentStock}: ${_selectedProduct!.currentStock}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _mode == _StockMode.adjustment
                      ? AppStrings.adjustmentQuantity
                      : AppStrings.quantity,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: _mode == _StockMode.adjustment,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.enterQuantity,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_mode == _StockMode.adjustment) ...[
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.adjustmentReason,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: AppStrings.enterReason,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
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
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_mode == _StockMode.stockIn
                        ? Icons.add
                        : Icons.tune),
                label: Text(_isSubmitting
                    ? AppStrings.confirm
                    : _mode == _StockMode.stockIn
                        ? AppStrings.stockInTitle
                        : AppStrings.stockAdjustment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StockMode { stockIn, adjustment }
