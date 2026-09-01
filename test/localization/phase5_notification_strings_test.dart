import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/localization/app_strings.dart';

bool _containsBengali(String value) {
  return value.runes.any((rune) => rune >= 0x0980 && rune <= 0x09FF);
}

void main() {
  group('Phase 5 notification AppStrings', () {
    final keys = <String, String>{
      'loadingNotifications': AppStrings.loadingNotifications,
      'notificationsLoadFailed': AppStrings.notificationsLoadFailed,
      'unreadCountLoadFailed': AppStrings.unreadCountLoadFailed,
      'notificationUpdateFailed': AppStrings.notificationUpdateFailed,
      'notificationsUpdateFailed': AppStrings.notificationsUpdateFailed,
      'notificationRefreshFailed': AppStrings.notificationRefreshFailed,
      'loadMoreNotifications': AppStrings.loadMoreNotifications,
      'noMoreNotifications': AppStrings.noMoreNotifications,
      'markAsRead': AppStrings.markAsRead,
      'markAllRead': AppStrings.markAllRead,
      'viewNotifications': AppStrings.viewNotifications,
    };

    for (final entry in keys.entries) {
      test('${entry.key} is non-empty Bengali', () {
        expect(entry.value.trim(), isNotEmpty);
        expect(_containsBengali(entry.value), isTrue,
            reason: '${entry.key} should use Bengali script');
      });
    }
  });
}
