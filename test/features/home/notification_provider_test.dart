import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/features/home/providers/notification_providers.dart';
import 'package:shop_stock_app/models/app_notification.dart';
import 'package:shop_stock_app/repositories/notification_repository.dart';

class _PagedNotificationRepository implements NotificationRepository {
  _PagedNotificationRepository();

  int unreadCount = 0;

  @override
  Future<List<AppNotification>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    if (offset == 0) {
      return List.generate(
        limit,
        (i) => AppNotification(
          id: 'n$i',
          type: 'sale',
          message: 'Msg $i',
          read: false,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }
    if (offset == limit) {
      return [
        AppNotification(
          id: 'extra',
          type: 'sale',
          message: 'Extra',
          read: false,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      ];
    }
    return [];
  }

  @override
  Future<int> fetchUnreadCount() async => unreadCount;

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}

void main() {
  test('notification page size constant matches repository default', () {
    expect(notificationPageSize, 50);
  });

  test('paged repository contract supports hasMore detection', () async {
    final repo = _PagedNotificationRepository();
    final first = await repo.fetchNotifications(limit: notificationPageSize);
    final second = await repo.fetchNotifications(
      limit: notificationPageSize,
      offset: notificationPageSize,
    );

    expect(first.length, notificationPageSize);
    expect(second, hasLength(1));
    expect(first.length == notificationPageSize, isTrue);
  });
}
