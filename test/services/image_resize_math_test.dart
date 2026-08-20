import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/services/image_resize_math.dart';

void main() {
  group('computeTargetDimensions', () {
    test('does not upscale an image already smaller than maxDimension', () {
      final result = computeTargetDimensions(
        originalWidth: 200,
        originalHeight: 150,
        maxDimension: 1024,
      );
      expect(result, const TargetDimensions(200, 150));
    });

    test('downscales a landscape image to fit maxDimension on the long side',
        () {
      final result = computeTargetDimensions(
        originalWidth: 4000,
        originalHeight: 2000,
        maxDimension: 1000,
      );
      expect(result.width, 1000);
      expect(result.height, 500);
    });

    test('downscales a portrait image to fit maxDimension on the long side',
        () {
      final result = computeTargetDimensions(
        originalWidth: 2000,
        originalHeight: 4000,
        maxDimension: 1000,
      );
      expect(result.width, 500);
      expect(result.height, 1000);
    });

    test('handles a perfectly square image', () {
      final result = computeTargetDimensions(
        originalWidth: 3000,
        originalHeight: 3000,
        maxDimension: 300,
      );
      expect(result, const TargetDimensions(300, 300));
    });

    test('leaves dimensions unchanged when exactly at maxDimension', () {
      final result = computeTargetDimensions(
        originalWidth: 1024,
        originalHeight: 768,
        maxDimension: 1024,
      );
      expect(result, const TargetDimensions(1024, 768));
    });

    test(
        'thumb sizing produces a much smaller result than full sizing for the same photo',
        () {
      const originalWidth = 4032;
      const originalHeight = 3024;

      final full = computeTargetDimensions(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        maxDimension: 1024,
      );
      final thumb = computeTargetDimensions(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        maxDimension: 300,
      );

      expect(thumb.width, lessThan(full.width));
      expect(thumb.height, lessThan(full.height));
    });

    test('throws for non-positive inputs', () {
      expect(
        () => computeTargetDimensions(
            originalWidth: 0, originalHeight: 100, maxDimension: 100),
        throwsArgumentError,
      );
      expect(
        () => computeTargetDimensions(
            originalWidth: 100, originalHeight: -5, maxDimension: 100),
        throwsArgumentError,
      );
      expect(
        () => computeTargetDimensions(
            originalWidth: 100, originalHeight: 100, maxDimension: 0),
        throwsArgumentError,
      );
    });
  });
}
