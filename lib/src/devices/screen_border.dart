/// Models the screen corner shape of a device.
///
/// Used by [ScreenClipPainter] to clip the display content to the device's
/// true screen shape.
sealed class ScreenBorder {
  const ScreenBorder();
}

/// Standard circular-arc corner clipping.
///
/// Used for Android and iPad profiles with measured or community-approximated
/// radii. A radius of 0 means square corners.
final class CircularBorder extends ScreenBorder {
  /// Corner radius in logical pixels. A value of 0 means square corners.
  final double radius;

  const CircularBorder(this.radius);
}

/// Squircle (continuous-curvature) corner clipping for iPhone displays.
///
/// Apple uses superellipse curves rather than circular arcs for iPhone screen
/// corners. This class stores the exact Bézier control points extracted from
/// the iOS Simulator framebuffer PDFs (`tool/extract_simdevicetype.dart`).
///
/// ## Coordinate convention
///
/// [segments] describes the top-right corner in Flutter logical points with
/// the corner position (logW, 0) as the origin. The path goes from
/// (−[topTangentLength], 0) on the top edge to (0, [sideTangentLength]) on
/// the right edge. Each segment is 6 doubles: cp1x, cp1y, cp2x, cp2y, x, y.
///
/// The painter reflects and rotates this one corner to build all four corners
/// of the full screen clip path. See [ScreenClipPainter] for details.
final class SquircleBorder extends ScreenBorder {
  /// Distance from the top-right corner to the tangent point on the top edge
  /// (logical pixels, portrait). Equals screenWidth − tangentX.
  final double topTangentLength;

  /// Cubic Bézier segments for the top-right corner, as a list of lists of 6
  /// doubles. Each group of 6 is: cp1x, cp1y, cp2x, cp2y, x, y, all relative to
  /// the corner position (logW, 0) in logical pixels.
  ///
  /// The path begins at (−[topTangentLength], 0) and ends at
  /// (0, [sideTangentLength]).
  final List<List<double>> segments;

  const SquircleBorder({
    required this.topTangentLength,
    required this.segments,
  });

  /// Distance from the top-right corner to the tangent point on the right
  /// edge (logical pixels, portrait). Derived from the last y value in
  /// [segments].
  double get sideTangentLength {
    final last = segments[segments.length - 1];
    return last[last.length - 1];
  }
}
