import '../localization/app_strings.dart';

/// Client-side mirror of the validation rules enforced server-side by
/// create_product()/update_product() (see
/// supabase/migrations/0006_product_management_rpc.sql). This exists
/// purely for fast, friendly form feedback — the server-side checks
/// are the actual security boundary and must never be assumed
/// satisfied just because this class approved the input.
///
/// Pure functions, no Flutter/Supabase dependency, so they're cheap to
/// unit test directly.
class ProductValidator {
  const ProductValidator._();

  /// Returns an error message, or null if valid.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.nameRequired;
    }
    return null;
  }

  /// Validates a required, non-negative price field (Sale Price).
  static String? validateRequiredPrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.priceInvalid;
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return AppStrings.priceInvalid;
    }
    if (parsed < 0) {
      return AppStrings.priceNegative;
    }
    return null;
  }

  /// Validates an optional, non-negative price field (MRP, Purchase
  /// Price) — empty is allowed, but if present it must be a valid,
  /// non-negative number.
  static String? validateOptionalPrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return AppStrings.priceInvalid;
    }
    if (parsed < 0) {
      return AppStrings.priceNegative;
    }
    return null;
  }

  /// Validates the low-stock limit: required, non-negative.
  static String? validateLowStockLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // defaults to 0 server-side
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return AppStrings.priceInvalid;
    }
    if (parsed < 0) {
      return AppStrings.lowStockNegative;
    }
    return null;
  }

  /// True if the whole set of fields would pass validation. Useful
  /// for enabling/disabling the Save button reactively.
  static bool isFormValid({
    required String? name,
    required String? salePrice,
    required String? mrp,
    required String? purchasePrice,
    required String? lowStockLimit,
  }) {
    return validateName(name) == null &&
        validateRequiredPrice(salePrice) == null &&
        validateOptionalPrice(mrp) == null &&
        validateOptionalPrice(purchasePrice) == null &&
        validateLowStockLimit(lowStockLimit) == null;
  }
}
