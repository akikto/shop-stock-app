import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/product_photo_constants.dart';

/// Abstraction over "put these bytes at this path in the product
/// photo bucket". Separated from ProductPhotoService for the same
/// reason as ImageCompressor: it lets upload orchestration be tested
/// with a fake, without a real Supabase Storage connection.
abstract class ProductPhotoUploader {
  Future<void> upload(String path, Uint8List bytes);

  /// Resolves a short-lived signed URL for a private object. Returns
  /// null if [path] is null (i.e. the product has no photo).
  Future<String?> getSignedUrl(String? path);
}

class SupabaseProductPhotoUploader implements ProductPhotoUploader {
  SupabaseProductPhotoUploader(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upload(String path, Uint8List bytes) {
    return _client.storage.from(ProductPhotoConstants.storageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
  }

  @override
  Future<String?> getSignedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    return _client.storage.from(ProductPhotoConstants.storageBucket).createSignedUrl(
          path,
          ProductPhotoConstants.signedUrlExpirySeconds,
        );
  }
}
