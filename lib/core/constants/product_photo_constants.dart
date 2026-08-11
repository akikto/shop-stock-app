/// Product photo sizing/compression constants.
///
/// Two variants are produced for every product photo:
///   - a "full" version for the product detail screen
///   - a much smaller "thumb" version for the photo-first product
///     grid, where dozens of photos may be visible/scrolling at once
///
/// Values chosen to keep both bandwidth and on-device storage low on
/// low-end Android phones, per the app's mobile-first requirement.
class ProductPhotoConstants {
  const ProductPhotoConstants._();

  static const String storageBucket = 'product-photos';

  static const int fullMaxDimension = 1024;
  static const int fullQuality = 75;

  static const int thumbMaxDimension = 300;
  static const int thumbQuality = 70;

  /// How long a signed URL for a product photo stays valid before the
  /// app must request a new one.
  static const int signedUrlExpirySeconds = 3600;
}
