enum PendingTransactionType {
  sale,
  stockIn,
  adjustment;

  String get storageValue {
    switch (this) {
      case PendingTransactionType.sale:
        return 'sale';
      case PendingTransactionType.stockIn:
        return 'stock_in';
      case PendingTransactionType.adjustment:
        return 'adjustment';
    }
  }

  static PendingTransactionType fromStorage(String value) {
    switch (value) {
      case 'sale':
        return PendingTransactionType.sale;
      case 'stock_in':
        return PendingTransactionType.stockIn;
      case 'adjustment':
        return PendingTransactionType.adjustment;
      default:
        throw ArgumentError('Unknown pending transaction type: $value');
    }
  }
}
