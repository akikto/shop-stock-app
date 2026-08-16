/// One row from `get_staff_sales_report()`.
class StaffSalesRow {
  const StaffSalesRow({
    required this.userId,
    required this.userName,
    required this.saleCount,
    required this.totalAmount,
  });

  final String userId;
  final String userName;
  final int saleCount;
  final num totalAmount;

  factory StaffSalesRow.fromJson(Map<String, dynamic> json) {
    return StaffSalesRow(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown',
      saleCount: (json['sale_count'] as num?)?.toInt() ?? 0,
      totalAmount: json['total_amount'] as num? ?? 0,
    );
  }
}
