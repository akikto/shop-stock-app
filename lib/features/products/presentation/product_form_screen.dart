import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/validation/product_validator.dart';
import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/product_providers.dart';
import 'widgets/photo_picker_field.dart';

/// Router-facing wrapper for the /products/:id/edit route: loads the
/// product first (the detail screen may not always be the entry
/// point, e.g. a future deep link), then renders [ProductFormScreen]
/// pre-filled once it's available.
class ProductEditScreen extends ConsumerWidget {
  const ProductEditScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return productAsync.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editProduct)),
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.editProduct)),
            body: const ErrorView(message: AppStrings.noProductsFound),
          );
        }
        return ProductFormScreen(existingProduct: product);
      },
    );
  }
}

/// Combined Add/Edit Product screen. In edit mode, [existingProduct]
/// is supplied (already loaded by the detail screen) so the form opens
/// pre-filled without an extra network round trip.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.existingProduct});

  final Product? existingProduct;

  bool get isEditing => existingProduct != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _nameController = TextEditingController(text: widget.existingProduct?.name ?? '');
  late final _companyController = TextEditingController(text: widget.existingProduct?.company ?? '');
  late final _categoryController = TextEditingController(text: widget.existingProduct?.category ?? '');
  late final _packSizeController = TextEditingController(text: widget.existingProduct?.packSize ?? '');
  late final _mrpController = TextEditingController(text: widget.existingProduct?.mrp?.toString() ?? '');
  late final _purchasePriceController =
      TextEditingController(text: widget.existingProduct?.purchasePrice?.toString() ?? '');
  late final _salePriceController =
      TextEditingController(text: widget.existingProduct?.salePrice.toString() ?? '');
  late final _lowStockLimitController =
      TextEditingController(text: widget.existingProduct?.lowStockLimit.toString() ?? '');

  Uint8List? _newPhotoBytes;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _categoryController.dispose();
    _packSizeController.dispose();
    _mrpController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _lowStockLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      String? photoUrl = widget.existingProduct?.photoUrl;
      String? photoThumbUrl = widget.existingProduct?.photoThumbUrl;

      if (_newPhotoBytes != null) {
        final photoService = ref.read(productPhotoServiceProvider);
        final paths = await photoService.compressAndUpload(_newPhotoBytes!);
        photoUrl = paths.photoPath;
        photoThumbUrl = paths.thumbPath;
      }

      final repo = ref.read(productRepositoryProvider);
      final name = _nameController.text.trim();
      final company = _emptyToNull(_companyController.text);
      final category = _emptyToNull(_categoryController.text);
      final packSize = _emptyToNull(_packSizeController.text);
      final mrp = _parseOrNull(_mrpController.text);
      final purchasePrice = _parseOrNull(_purchasePriceController.text);
      final salePrice = num.parse(_salePriceController.text.trim());
      final lowStockLimit = _parseOrNull(_lowStockLimitController.text) ?? 0;

      if (widget.isEditing) {
        await repo.updateProduct(
          id: widget.existingProduct!.id,
          name: name,
          photoUrl: photoUrl,
          photoThumbUrl: photoThumbUrl,
          company: company,
          category: category,
          packSize: packSize,
          mrp: mrp,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          lowStockLimit: lowStockLimit,
        );
        ref.invalidate(productDetailProvider(widget.existingProduct!.id));
      } else {
        await repo.createProduct(
          name: name,
          photoUrl: photoUrl,
          photoThumbUrl: photoThumbUrl,
          company: company,
          category: category,
          packSize: packSize,
          mrp: mrp,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          lowStockLimit: lowStockLimit,
        );
      }

      await ref.read(productListControllerProvider.notifier).refresh();

      if (mounted) context.pop();
    } on ProductException catch (e) {
      setState(() => _submitError = e.message);
    } catch (e) {
      setState(() => _submitError = AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  num? _parseOrNull(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return num.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? AppStrings.editProduct : AppStrings.addProduct)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PhotoPickerField(
              existingPhotoPath: widget.existingProduct?.photoThumbUrl,
              onPhotoPicked: (bytes) => setState(() => _newPhotoBytes = bytes),
            ),
            const SizedBox(height: 20),
            if (_submitError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_submitError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 16),
            ],
            _field(
              controller: _nameController,
              label: AppStrings.productName,
              validator: ProductValidator.validateName,
              textCapitalization: TextCapitalization.words,
            ),
            _field(controller: _companyController, label: AppStrings.company, textCapitalization: TextCapitalization.words),
            _field(controller: _categoryController, label: AppStrings.category, textCapitalization: TextCapitalization.words),
            _field(controller: _packSizeController, label: AppStrings.packSize),
            _field(
              controller: _mrpController,
              label: AppStrings.mrp,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: ProductValidator.validateOptionalPrice,
            ),
            _field(
              controller: _purchasePriceController,
              label: AppStrings.purchasePrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: ProductValidator.validateOptionalPrice,
            ),
            _field(
              controller: _salePriceController,
              label: AppStrings.salePrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: ProductValidator.validateRequiredPrice,
            ),
            _field(
              controller: _lowStockLimitController,
              label: AppStrings.lowStockLimit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: ProductValidator.validateLowStockLimit,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEditing ? AppStrings.update : AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator,
      ),
    );
  }
}
