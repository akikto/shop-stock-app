import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/sync/services/connectivity_service.dart';

/// Test double matching the pattern used in widget/sync tests (no platform channel).
class StubConnectivityService extends ConnectivityService {
  StubConnectivityService({required this.online}) : super();

  final bool online;

  @override
  bool get isOnline => online;

  @override
  Future<void> start() async {}
}

void main() {
  test('stub connectivity service exposes configured online state', () {
    expect(StubConnectivityService(online: false).isOnline, isFalse);
    expect(StubConnectivityService(online: true).isOnline, isTrue);
  });
}
