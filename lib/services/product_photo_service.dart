import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../core/constants/product_photo_constants.dart';
import 'image_compressor.dart';
import 'product_photo_uploader.dart';

class ProductPhotoPaths {
  const ProductPhotoPaths({required this.photoPath, required this.thumbPath});
  final String photoPath;
  final String thumbPath;
}

class _CachedSignedUrl {
  _CachedSignedUrl(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Orchestrates turning a freshly-picked photo into the two
/// compressed variants this app stores, uploading them, and later
/// resolving short-lived signed URLs for display — with a small
/// in-memory cache so the same product photo isn't re-signed on every
/// widget rebuild within a session.
///
/// Depends on [ImageCompressor] and [ProductPhotoUploader]
/// abstractions (not flutter_image_compress/Supabase directly) so
/// this orchestration logic can be unit tested with fakes — see
/// test/services/product_photo_service_test.dart.
class ProductPhotoService {
  ProductPhotoService({
    required ImageCompressor compressor,
    required ProductPhotoUploader uploader,
    Uuid? uuid,
  })  : _compressor = compressor,
        _uploader = uploader,
        _uuid = uuid ?? const Uuid();

  final ImageCompressor _compressor;
  final ProductPhotoUploader _uploader;
  final Uuid _uuid;

  final Map<String, _CachedSignedUrl> _signedUrlCache = {};

  /// Compresses [originalBytes] into full + thumb variants and
  /// uploads both under a freshly generated, product-independent
  /// storage path (see migration 0004 — path naming doesn't need to
  /// match the eventual product id, so the photo can be uploaded
  /// before create_product() is even called).
  Future<ProductPhotoPaths> compressAndUpload(Uint8List originalBytes) async {
    final full = await _compressor.compress(
      originalBytes,
      maxDimension: ProductPhotoConstants.fullMaxDimension,
      quality: ProductPhotoConstants.fullQuality,
    );
    final thumb = await _compressor.compress(
      originalBytes,
      maxDimension: ProductPhotoConstants.thumbMaxDimension,
      quality: ProductPhotoConstants.thumbQuality,
    );

    final id = _uuid.v4();
    final photoPath = 'products/$id/photo.jpg';
    final thumbPath = 'products/$id/thumb.jpg';

    await _uploader.upload(photoPath, full);
    await _uploader.upload(thumbPath, thumb);

    return ProductPhotoPaths(photoPath: photoPath, thumbPath: thumbPath);
  }

  /// Resolves a signed URL for [path], reusing a cached one if it
  /// hasn't expired yet. Returns null if [path] is null/empty (no
  /// photo set).
  Future<String?> resolveSignedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;

    final cached = _signedUrlCache[path];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    final url = await _uploader.getSignedUrl(path);
    if (url == null) return null;

    _signedUrlCache[path] = _CachedSignedUrl(
      url,
      DateTime.now().add(
        const Duration(seconds: ProductPhotoConstants.signedUrlExpirySeconds - 60),
      ),
    );
    return url;
  }

  void clearCache() => _signedUrlCache.clear();
}
