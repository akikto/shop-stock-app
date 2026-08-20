import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_stock_app/core/constants/product_photo_constants.dart';
import 'package:shop_stock_app/services/image_compressor.dart';
import 'package:shop_stock_app/services/product_photo_service.dart';
import 'package:shop_stock_app/services/product_photo_uploader.dart';

class CompressCall {
  CompressCall(this.maxDimension, this.quality);
  final int maxDimension;
  final int quality;
}

/// Records every compress() call instead of doing real image work —
/// this is the honest boundary of what's testable without a device:
/// we verify the *orchestration* (which sizes/qualities get
/// requested, that both variants are produced) rather than actual
/// pixel-level compression, which is delegated to a native platform
/// channel that only runs on-device.
class FakeImageCompressor implements ImageCompressor {
  final List<CompressCall> calls = [];

  @override
  Future<Uint8List> compress(
    Uint8List originalBytes, {
    required int maxDimension,
    required int quality,
  }) async {
    calls.add(CompressCall(maxDimension, quality));
    return Uint8List(maxDimension); // fake: byte length == maxDimension
  }
}

class UploadCall {
  UploadCall(this.path, this.bytes);
  final String path;
  final Uint8List bytes;
}

class FakeProductPhotoUploader implements ProductPhotoUploader {
  final List<UploadCall> uploads = [];
  final Map<String, String> signedUrls = {};

  @override
  Future<void> upload(String path, Uint8List bytes) async {
    uploads.add(UploadCall(path, bytes));
  }

  @override
  Future<String?> getSignedUrl(String? path) async {
    if (path == null) return null;
    return signedUrls[path] ?? 'https://signed.example/$path?token=fake';
  }
}

void main() {
  late FakeImageCompressor compressor;
  late FakeProductPhotoUploader uploader;
  late ProductPhotoService service;

  setUp(() {
    compressor = FakeImageCompressor();
    uploader = FakeProductPhotoUploader();
    service = ProductPhotoService(compressor: compressor, uploader: uploader);
  });

  group('compressAndUpload', () {
    test('produces exactly two compressed variants: full and thumb', () async {
      await service.compressAndUpload(Uint8List.fromList([1, 2, 3]));

      expect(compressor.calls.length, 2);
    });

    test('full variant uses the configured full max dimension and quality', () async {
      await service.compressAndUpload(Uint8List.fromList([1, 2, 3]));

      final fullCall = compressor.calls.firstWhere(
        (c) => c.maxDimension == ProductPhotoConstants.fullMaxDimension,
      );
      expect(fullCall.quality, ProductPhotoConstants.fullQuality);
    });

    test('thumb variant uses the configured thumb max dimension and quality', () async {
      await service.compressAndUpload(Uint8List.fromList([1, 2, 3]));

      final thumbCall = compressor.calls.firstWhere(
        (c) => c.maxDimension == ProductPhotoConstants.thumbMaxDimension,
      );
      expect(thumbCall.quality, ProductPhotoConstants.thumbQuality);
    });

    test('thumb max dimension is smaller than full max dimension (bandwidth goal)', () {
      expect(
        ProductPhotoConstants.thumbMaxDimension,
        lessThan(ProductPhotoConstants.fullMaxDimension),
      );
    });

    test('uploads both variants under the same generated product-independent id', () async {
      final result = await service.compressAndUpload(Uint8List.fromList([1, 2, 3]));

      expect(uploader.uploads.length, 2);
      expect(result.photoPath, contains('products/'));
      expect(result.photoPath, endsWith('/photo.jpg'));
      expect(result.thumbPath, endsWith('/thumb.jpg'));

      final photoId = result.photoPath.split('/')[1];
      final thumbId = result.thumbPath.split('/')[1];
      expect(photoId, thumbId);
    });

    test('two separate uploads generate two different product-independent ids', () async {
      final first = await service.compressAndUpload(Uint8List.fromList([1]));
      final second = await service.compressAndUpload(Uint8List.fromList([2]));

      expect(first.photoPath, isNot(second.photoPath));
    });
  });

  group('resolveSignedUrl', () {
    test('returns null for a null/empty path (no photo set)', () async {
      expect(await service.resolveSignedUrl(null), isNull);
      expect(await service.resolveSignedUrl(''), isNull);
    });

    test('resolves and caches a signed URL, avoiding a second uploader call for the same path', () async {
      const path = 'products/abc/photo.jpg';

      final first = await service.resolveSignedUrl(path);
      uploader.signedUrls[path] = 'https://signed.example/different-token';
      final second = await service.resolveSignedUrl(path);

      expect(first, isNotNull);
      expect(second, first, reason: 'cached value should be reused within its TTL');
    });

    test('clearCache forces a fresh resolution on the next call', () async {
      const path = 'products/abc/photo.jpg';

      final first = await service.resolveSignedUrl(path);
      service.clearCache();
      uploader.signedUrls[path] = 'https://signed.example/rotated-token';
      final second = await service.resolveSignedUrl(path);

      expect(second, isNot(first));
    });
  });
}
