import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'image_resize_math.dart';

/// Abstraction over "shrink and compress these image bytes". Kept as
/// an interface — rather than calling flutter_image_compress directly
/// from ProductPhotoService — purely so the upload/orchestration logic
/// in ProductPhotoService can be unit tested with a fake, since the
/// real plugin is a platform channel that only works on-device.
abstract class ImageCompressor {
  Future<Uint8List> compress(
    Uint8List originalBytes, {
    required int maxDimension,
    required int quality,
  });
}

/// Real implementation used by the app. Decodes the image to find its
/// true pixel dimensions, computes the target size with the same pure
/// math that's unit tested in image_resize_math.dart, then asks the
/// native plugin to resize+re-encode to that exact target — so the
/// resize strategy is deterministic and explicit rather than left
/// entirely to the plugin's own heuristics.
class FlutterImageCompressor implements ImageCompressor {
  @override
  Future<Uint8List> compress(
    Uint8List originalBytes, {
    required int maxDimension,
    required int quality,
  }) async {
    final codec = await ui.instantiateImageCodec(originalBytes);
    final frame = await codec.getNextFrame();
    final target = computeTargetDimensions(
      originalWidth: frame.image.width,
      originalHeight: frame.image.height,
      maxDimension: maxDimension,
    );
    frame.image.dispose();

    final compressed = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: target.width,
      minHeight: target.height,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    return Uint8List.fromList(compressed);
  }
}
