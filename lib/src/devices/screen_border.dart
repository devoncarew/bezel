/// Models the screen corner shape of a device.
///
/// Used by [ScreenClipPainter] to clip the display content to the device's
/// true screen shape. Currently only [CircularBorder] is used; [SquircleBorder]
/// will be added in Step 5.4 once Bézier control points are extracted from the
/// iOS Simulator framebuffer PDFs (see `docs/PLAN.md`).
sealed class ScreenBorder {
  const ScreenBorder();
}

/// Standard circular-arc corner clipping.
///
/// Used by all current device profiles. Android and iPad profiles use measured
/// or community-approximated radii; iOS profiles use Simulator-measured squircle
/// tangent points as a stand-in for the true squircle path (which is larger than
/// the equivalent circular arc — see Step 5.4 in `docs/PLAN.md`).
final class CircularBorder extends ScreenBorder {
  /// Corner radius in logical pixels. A value of 0 means square corners.
  final double radius;

  const CircularBorder(this.radius);
}
