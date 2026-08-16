/// One row from `get_product_sales_report()`.
class ProductSalesRow {
  const ProductSalesRow({
    required this.productId,
    required this.productName,
    required this.saleCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  final String productId;
  final String productName;
  final int saleCount;
  final num totalQuantity;
  final num totalAmount;

  factory ProductSalesRow.fromJson(Map<String, dynamic> json) {
    return ProductSalesRow(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? 'Unknown',
      saleCount: (json['sale_count'] as num?)?.toInt() ?? 0,
      totalQuantity: json['total_quantity'] as num? ?? 0,
      totalAmount: json['total_amount'] as num? ?? 0,
    );
  }
}
