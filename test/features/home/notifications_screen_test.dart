import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';
import 'package:shop_stock_app/features/home/presentation/notifications_screen.dart';
import 'package:shop_stock_app/features/home/providers/notification_providers.dart';
import 'package:shop_stock_app/models/app_notification.dart';
import 'package:shop_stock_app/repositories/notification_repository.dart';

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository(this.initial);

  final List<AppNotification> initial;
  bool failLoadMore = false;

  @override
  Future<List<AppNotification>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    if (offset == 0) return initial;
    if (failLoadMore) {
      throw NotificationException(AppStrings.notificationRefreshFailed);
    }
    return [];
  }

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}

AppNotification _notification(String id, {bool read = false}) =>
    AppNotification(
      id: id,
      type: 'sale',
      message: 'Sale message $id',
      read: read,
      createdAt: DateTime.utc(2026, 1, 1, 12),
    );

Future<void> _settleNotificationList(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration.zero);
  await tester.pump();
}

void main() {
  testWidgets('NotificationsScreen shows Bengali empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(
            _FakeNotificationRepository([]),
          ),
          notificationRealtimeProvider.overrideWith((ref) {}),
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );

    await _settleNotificationList(tester);

    expect(find.text(AppStrings.noNotifications), findsOneWidget);
  });

  testWidgets('NotificationsScreen lists notifications and load-more footer',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(
            _FakeNotificationRepository([_notification('n1')]),
          ),
          notificationRealtimeProvider.overrideWith((ref) {}),
          unreadNotificationCountProvider.overrideWith((ref) async => 1),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );

    await _settleNotificationList(tester);

    expect(find.text('Sale message n1'), findsOneWidget);
    expect(find.text(AppStrings.noMoreNotifications), findsOneWidget);
  });
}
