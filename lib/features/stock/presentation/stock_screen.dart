import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/product.dart';
import '../../../repositories/transaction_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/presentation/widgets/product_picker_grid.dart';
import '../../products/providers/product_providers.dart';
import '../../transactions/providers/transaction_providers.dart';

enum _StockMode { stockIn, adjustment }

/// Quick Stock In (all roles) and Stock Adjustment (Manager/Owner
/// only): tap a product photo -> set quantity (+ reason for
/// adjustment) -> confirm. Stock only ever changes via
/// record_stock_in()/record_adjustment() (migration 0008).
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  _StockMode _mode = _StockMode.stockIn;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final canAdjust = profileAsync.maybeWhen(data: (p) => p.role.canAdjustStock, orElse: () => false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.stockIn),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<_StockMode>(
              segments: [
                const ButtonSegment(value: _StockMode.stockIn, label: Text(AppStrings.stockIn)),
                ButtonSegment(
                  value: _StockMode.adjustment,
                  label: const Text(AppStrings.stockAdjustment),
                  enabled: canAdjust,
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() => _mode = selection.first),
            ),
          ),
        ),
      ),
      body: ProductPickerGrid(
        onProductSelected: (product) => _openSheet(context, product),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, Product product) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _mode == _StockMode.stockIn
          ? _StockInSheet(product: product)
          : _AdjustmentSheet(product: product),
    );
  }
}

class _StockInSheet extends ConsumerStatefulWidget {
  const _StockInSheet({required this.product});
  final Product product;

  @override
  ConsumerState<_StockInSheet> createState() => _StockInSheetState();
}

class _StockInSheetState extends ConsumerState<_StockInSheet> {
  int _quantity = 1;
  bool _isSubmitting = false;
  String? _error;

  void _increment() => setState(() => _quantity++);
  void _decrement() => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1);

  Future<void> _confirm() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(transactionRepositoryProvider).recordStockIn(
            productId: widget.product.id,
            quantity: _quantity,
          );
      await ref.read(productListControllerProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.stockAddedSuccessfully)),
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
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.product.name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('${AppStrings.currentStock}: ${widget.product.currentStock}',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(onPressed: _decrement, icon: const Icon(Icons.remove)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_quantity', style: Theme.of(context).textTheme.headlineMedium),
              ),
              IconButton.filledTonal(onPressed: _increment, icon: const Icon(Icons.add)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _confirm,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(AppStrings.addStock),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentSheet extends ConsumerStatefulWidget {
  const _AdjustmentSheet({required this.product});
  final Product product;

  @override
  ConsumerState<_AdjustmentSheet> createState() => _AdjustmentSheetState();
}

class _AdjustmentSheetState extends ConsumerState<_AdjustmentSheet> {
  int _quantity = 1;
  bool _isIncrease = true;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _increment() => setState(() => _quantity++);
  void _decrement() => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1);

  Future<void> _confirm() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = AppStrings.reasonRequired);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final change = _isIncrease ? _quantity : -_quantity;
    try {
      await ref.read(transactionRepositoryProvider).recordAdjustment(
            productId: widget.product.id,
            quantityChange: change,
            reason: reason,
          );
      await ref.read(productListControllerProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.stockAdjustedSuccessfully)),
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
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.product.name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('${AppStrings.currentStock}: ${widget.product.currentStock}',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text(AppStrings.increaseStock), icon: Icon(Icons.add)),
              ButtonSegment(value: false, label: Text(AppStrings.decreaseStock), icon: Icon(Icons.remove)),
            ],
            selected: {_isIncrease},
            onSelectionChanged: (s) => setState(() => _isIncrease = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(onPressed: _decrement, icon: const Icon(Icons.remove)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_quantity', style: Theme.of(context).textTheme.headlineMedium),
              ),
              IconButton.filledTonal(onPressed: _increment, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: AppStrings.reason, border: OutlineInputBorder()),
            maxLines: 2,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _confirm,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(AppStrings.adjustStock),
          ),
        ],
      ),
    );
  }
}
