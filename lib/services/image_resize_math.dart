/// Pure aspect-ratio-preserving downscale math, isolated from the
/// native image codec/compression plugin so the *sizing strategy*
/// itself can be unit tested without needing a real Flutter engine or
/// device. See lib/services/image_compressor.dart for where this
/// feeds into the actual compression call.
class TargetDimensions {
  const TargetDimensions(this.width, this.height);
  final int width, height;

  @override
  bool operator ==(Object other) =>
      other is TargetDimensions &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'TargetDimensions($width x $height)';
}

/// Computes the largest size that fits within [maxDimension] on its
/// longest side while preserving the original aspect ratio. If the
/// image is already smaller than [maxDimension] on both sides, the
/// original size is returned unchanged — this app never upscales a
/// photo, only shrinks it.
TargetDimensions computeTargetDimensions({
  required int originalWidth,
  required int originalHeight,
  required int maxDimension,
}) {
  if (originalWidth <= 0 || originalHeight <= 0 || maxDimension <= 0) {
    throw ArgumentError(
        'Width, height, and maxDimension must all be positive.');
  }

  final longestSide =
      originalWidth >= originalHeight ? originalWidth : originalHeight;
  if (longestSide <= maxDimension) {
    return TargetDimensions(originalWidth, originalHeight);
  }

  final scale = maxDimension / longestSide;
  final width = (originalWidth * scale).round().clamp(1, maxDimension);
  final height = (originalHeight * scale).round().clamp(1, maxDimension);
  return TargetDimensions(width, height);
}
