import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/responsive/mobile_frame.dart';

void main() {
  group('MobileFrame', () {
    testWidgets(
        'is a no-op (no extra SizedBox/Material wrapper) on a phone-width viewport',
        (tester) async {
      await tester.binding
          .setSurfaceSize(const Size(390, 844)); // typical phone size
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: MobileFrame(child: Scaffold(body: Text('content'))),
        ),
      );

      expect(find.text('content'), findsOneWidget);
      // No letterbox frame should be introduced at phone width.
      expect(
          find.byWidgetPredicate(
              (w) => w is ColoredBox && w.color == const Color(0xFF10241A)),
          findsNothing);
    });

    testWidgets(
        'letterboxes content into a fixed-width column on a wide (desktop) viewport',
        (tester) async {
      await tester.binding
          .setSurfaceSize(const Size(1400, 900)); // desktop-sized window
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: MobileFrame(child: Scaffold(body: Text('content'))),
        ),
      );

      expect(find.text('content'), findsOneWidget);
      expect(
          find.byWidgetPredicate(
              (w) => w is ColoredBox && w.color == const Color(0xFF10241A)),
          findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.byWidgetPredicate((w) => w is SizedBox && w.width == 480),
      );
      expect(sizedBox.width, 480);
    });

    testWidgets('exactly at the phone/desktop threshold width remains unframed',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: MobileFrame(child: Scaffold(body: Text('content'))),
        ),
      );

      expect(
          find.byWidgetPredicate(
              (w) => w is ColoredBox && w.color == const Color(0xFF10241A)),
          findsNothing);
    });
  });
}
