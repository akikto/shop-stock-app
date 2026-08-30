import 'package:flutter/material.dart';

import '../core/localization/app_strings.dart';

/// Known values of the Postgres `activity_action` enum.
class ActivityAction {
  const ActivityAction._();

  static const sale = 'sale';
  static const stockIn = 'stock_in';
  static const stockAdjustment = 'stock_adjustment';
  static const productCreated = 'product_created';
  static const productUpdated = 'product_updated';
  static const priceUpdated = 'price_updated';
  static const productDeactivated = 'product_deactivated';
  static const productActivated = 'product_activated';
  static const userCreated = 'user_created';
  static const userRoleChanged = 'user_role_changed';
  static const userDeactivated = 'user_deactivated';

  static const transactionActions = {sale, stockIn, stockAdjustment};

  static String label(String action) {
    switch (action) {
      case sale:
        return AppStrings.actionSale;
      case stockIn:
        return AppStrings.actionStockIn;
      case stockAdjustment:
        return AppStrings.actionStockAdjustment;
      case productCreated:
        return AppStrings.actionProductCreated;
      case productUpdated:
        return AppStrings.actionProductUpdated;
      case priceUpdated:
        return AppStrings.actionPriceUpdated;
      case productDeactivated:
        return AppStrings.actionProductDeactivated;
      case productActivated:
        return AppStrings.actionProductActivated;
      case userCreated:
        return AppStrings.actionUserCreated;
      case userRoleChanged:
        return AppStrings.actionUserRoleChanged;
      case userDeactivated:
        return AppStrings.actionUserDeactivated;
      default:
        return action;
    }
  }

  static IconData icon(String action) {
    switch (action) {
      case sale:
        return Icons.point_of_sale;
      case stockIn:
        return Icons.add_box;
      case stockAdjustment:
        return Icons.tune;
      case productCreated:
        return Icons.fiber_new;
      case productUpdated:
      case priceUpdated:
        return Icons.edit;
      case productDeactivated:
        return Icons.block;
      case productActivated:
        return Icons.check_circle_outline;
      case userCreated:
        return Icons.person_add;
      case userRoleChanged:
        return Icons.manage_accounts;
      case userDeactivated:
        return Icons.person_off;
      default:
        return Icons.history;
    }
  }

  /// Distinct accent colors for the three core stock/transaction types.
  static Color accentColor(String action) {
    switch (action) {
      case sale:
        return Colors.green;
      case stockIn:
        return Colors.blue;
      case stockAdjustment:
        return Colors.orange;
      case productCreated:
      case productActivated:
        return Colors.teal;
      case productDeactivated:
        return Colors.red;
      case userCreated:
      case userRoleChanged:
      case userDeactivated:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  static bool isTransactionAction(String action) =>
      transactionActions.contains(action);
}
