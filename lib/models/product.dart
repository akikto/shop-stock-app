/// Maps to a row in the `products` table.
///
/// `photoUrl`/`photoThumbUrl` hold Supabase Storage *paths*
/// (e.g. `products/<uuid>/photo.jpg`), not ready-to-use URLs — the
/// bucket is private, so a signed URL is resolved on demand by
/// [ProductPhotoService]. See migration 0004 for why the bucket is
/// private.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.currentStock,
    required this.lowStockLimit,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.photoThumbUrl,
    this.company,
    this.category,
    this.packSize,
    this.mrp,
    this.purchasePrice,
    this.expiryDate,
    this.composition,
  });

  final String id;
  final String name;
  final String? photoUrl;
  final String? photoThumbUrl;
  final String? company;
  final String? category;
  final String? packSize;
  final num? mrp;
  final num? purchasePrice;
  final num salePrice;
  final num currentStock;
  final num lowStockLimit;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiryDate;
  final String? composition;

  bool get isLowStock => currentStock <= lowStockLimit;

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  /// Within 30 days of expiry, but not yet expired — informational
  /// only, no automated alerting exists yet (see migration 0009).
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.isBefore(DateTime.now().add(const Duration(days: 30)));

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      photoThumbUrl: json['photo_thumb_url'] as String?,
      company: json['company'] as String?,
      category: json['category'] as String?,
      packSize: json['pack_size'] as String?,
      mrp: json['mrp'] as num?,
      purchasePrice: json['purchase_price'] as num?,
      salePrice: json['sale_price'] as num,
      currentStock: json['current_stock'] as num,
      lowStockLimit: json['low_stock_limit'] as num,
      isActive: json['is_active'] as bool,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      composition: json['composition'] as String?,
    );
  }
}
