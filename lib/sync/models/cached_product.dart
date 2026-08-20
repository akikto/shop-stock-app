import '../../models/product.dart';

/// Local snapshot of product fields needed for offline Sale/Stock pickers.
class CachedProduct {
  const CachedProduct({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.currentStock,
    required this.lowStockLimit,
    required this.isActive,
    required this.updatedAt,
    this.photoThumbUrl,
    this.company,
    this.category,
  });

  final String id;
  final String name;
  final num salePrice;
  final num currentStock;
  final num lowStockLimit;
  final bool isActive;
  final String? photoThumbUrl;
  final String? company;
  final String? category;
  final DateTime updatedAt;

  /// Maps to [Product] for reuse of existing picker/card UI.
  Product toProduct() {
    return Product(
      id: id,
      name: name,
      salePrice: salePrice,
      currentStock: currentStock,
      lowStockLimit: lowStockLimit,
      isActive: isActive,
      photoThumbUrl: photoThumbUrl,
      company: company,
      category: category,
      createdBy: 'local-cache',
      createdAt: updatedAt,
      updatedAt: updatedAt,
    );
  }
}
