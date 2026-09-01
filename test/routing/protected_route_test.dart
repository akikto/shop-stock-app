import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/core/routing/app_router.dart';
import 'package:shop_stock_app/features/auth/providers/auth_provider.dart';
import 'package:shop_stock_app/features/home/providers/dashboard_providers.dart';
import 'package:shop_stock_app/features/home/providers/fcm_providers.dart';
import 'package:shop_stock_app/features/home/providers/notification_providers.dart';
import 'package:shop_stock_app/features/history/providers/history_providers.dart';
import 'package:shop_stock_app/features/products/providers/product_providers.dart';
import 'package:shop_stock_app/features/transactions/providers/transaction_providers.dart';
import 'package:shop_stock_app/models/activity_log.dart';
import 'package:shop_stock_app/models/app_notification.dart';
import 'package:shop_stock_app/models/dashboard_stats.dart';
import 'package:shop_stock_app/models/product.dart';
import 'package:shop_stock_app/models/product_sales_row.dart';
import 'package:shop_stock_app/models/profile.dart';
import 'package:shop_stock_app/models/staff_sales_row.dart';
import 'package:shop_stock_app/models/stock_movement_row.dart';
import 'package:shop_stock_app/models/user_role.dart';
import 'package:shop_stock_app/repositories/activity_log_repository.dart';
import 'package:shop_stock_app/repositories/notification_repository.dart';
import 'package:shop_stock_app/repositories/product_repository.dart';
import 'package:shop_stock_app/repositories/reports_repository.dart';
import 'package:shop_stock_app/repositories/transaction_repository.dart';
import 'package:shop_stock_app/sync/models/transaction_write_result.dart';
import 'package:shop_stock_app/services/image_compressor.dart';
import 'package:shop_stock_app/services/product_photo_service.dart';
import 'package:shop_stock_app/services/product_photo_uploader.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../auth/fake_auth_repository.dart';

class _EmptyProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts({
    String search = '',
    bool activeOnly = true,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async =>
      [];

  @override
  Future<List<String>> fetchDistinctCategories() async => [];

  @override
  Future<Product?> fetchProductById(String id) async => null;

  @override
  Future<Product> createProduct({
    required String name,
    String? photoUrl,
    String? photoThumbUrl,
    String? company,
    String? category,
    String? packSize,
    num? mrp,
    num? purchasePrice,
    required num salePrice,
    num lowStockLimit = 0,
    DateTime? expiryDate,
    String? composition,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Product> updateProduct({
    required String id,
    required String name,
    String? photoUrl,
    String? photoThumbUrl,
    String? company,
    String? category,
    String? packSize,
    num? mrp,
    num? purchasePrice,
    required num salePrice,
    num lowStockLimit = 0,
    DateTime? expiryDate,
    String? composition,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Product> deactivateProduct(String id) async =>
      throw UnimplementedError();

  @override
  Future<Product> activateProduct(String id) async =>
      throw UnimplementedError();

  @override
  Future<List<Product>> fetchLowStockProducts() async => [];

  @override
  Future<int> countActiveProducts() async => 0;
}

class _EmptyReportsRepository implements ReportsRepository {
  @override
  Future<DashboardStats> fetchDashboardStats(
          {required DateTime from, required DateTime to}) async =>
      const DashboardStats(
        roleScope: 'self',
        saleCount: 0,
        totalSalesAmount: 0,
        stockInCount: 0,
        adjustmentCount: 0,
        lowStockCount: 0,
      );

  @override
  Future<List<StaffSalesRow>> fetchStaffSalesReport(
          {required DateTime from, required DateTime to}) async =>
      [];

  @override
  Future<List<ProductSalesRow>> fetchProductSalesReport(
          {required DateTime from, required DateTime to}) async =>
      [];

  @override
  Future<List<StockMovementRow>> fetchStockMovementReport(
          {required DateTime from, required DateTime to}) async =>
      [];
}

class _EmptyNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async =>
      [];

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}

class _EmptyActivityLogRepository implements ActivityLogRepository {
  @override
  Future<List<ActivityLog>> fetchActivityLogs(
          {int limit = 20, int offset = 0}) async =>
      [];
}

class _NoOpTransactionRepository implements TransactionRepository {
  @override
  Future<TransactionWriteResult> recordSale({
    required String productId,
    required num quantity,
    String? deviceTxnId,
  }) async =>
      TransactionWriteResult.synced;

  @override
  Future<TransactionWriteResult> recordStockIn({
    required String productId,
    required num quantity,
    String? deviceTxnId,
  }) async =>
      TransactionWriteResult.synced;

  @override
  Future<TransactionWriteResult> recordAdjustment({
    required String productId,
    required num quantityChange,
    required String reason,
    String? deviceTxnId,
  }) async =>
      TransactionWriteResult.synced;
}

class _NoOpImageCompressor implements ImageCompressor {
  @override
  Future<Uint8List> compress(
    Uint8List originalBytes, {
    required int maxDimension,
    required int quality,
  }) async =>
      Uint8List(0);
}

class _NoOpProductPhotoUploader implements ProductPhotoUploader {
  @override
  Future<void> upload(String path, Uint8List bytes) async {}

  @override
  Future<String?> getSignedUrl(String? path) async => null;
}

/// AppShell's IndexedStack builds every tab screen, so routing tests
/// must stub every repository those screens touch — not just auth.
List<Override> _shellTestOverrides(FakeAuthRepository fake) {
  return [
    authRepositoryProvider.overrideWithValue(fake),
    productRepositoryProvider.overrideWithValue(_EmptyProductRepository()),
    productPhotoServiceProvider.overrideWithValue(
      ProductPhotoService(
        compressor: _NoOpImageCompressor(),
        uploader: _NoOpProductPhotoUploader(),
      ),
    ),
    reportsRepositoryProvider.overrideWithValue(_EmptyReportsRepository()),
    notificationRepositoryProvider
        .overrideWithValue(_EmptyNotificationRepository()),
    activityLogRepositoryProvider
        .overrideWithValue(_EmptyActivityLogRepository()),
    transactionRepositoryProvider
        .overrideWithValue(_NoOpTransactionRepository()),
    notificationRealtimeProvider.overrideWith((ref) {}),
    productRealtimeProvider.overrideWith((ref) {}),
    fcmRegistrationProvider.overrideWith((ref) {}),
  ];
}

Widget _appWithRouter(FakeAuthRepository fake) {
  return ProviderScope(
    overrides: _shellTestOverrides(fake),
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

/// pumpAndSettle never completes when the protected shell is visible:
/// IndexedStack keeps every tab's CircularProgressIndicator animating.
Future<void> _settleProtectedShell(
    WidgetTester tester, FakeAuthRepository fake) async {
  await tester.pumpWidget(_appWithRouter(fake));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('protected route redirects', () {
    testWidgets(
        'unauthenticated user is redirected to Login and never sees the app shell',
        (tester) async {
      final fake = FakeAuthRepository(signedIn: false);
      addTearDown(fake.dispose);

      await tester.pumpWidget(_appWithRouter(fake));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.login), findsOneWidget);
      // Bottom navigation (protected shell) must not be present.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets(
        'authenticated user with an active profile reaches the protected shell',
        (tester) async {
      final fake = FakeAuthRepository(
        signedIn: true,
        profile: Profile(
          id: 'user-1',
          name: 'Staff Member',
          role: UserRole.staff,
          isActive: true,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      addTearDown(fake.dispose);

      await _settleProtectedShell(tester, fake);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text(AppStrings.login), findsNothing);
    });

    testWidgets(
        'authenticated but deactivated account is blocked from the shell with a clear message',
        (tester) async {
      final fake = FakeAuthRepository(
        signedIn: true,
        profile: Profile(
          id: 'user-2',
          name: 'Disabled Staff',
          role: UserRole.staff,
          isActive: false,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      addTearDown(fake.dispose);

      await tester.pumpWidget(_appWithRouter(fake));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(
          find.textContaining(AppStrings.accountDeactivated), findsOneWidget);
    });
  });
}
