import 'package:flutter/rendering.dart';

import '../devices/device_profile.dart';
import '../devices/screen_cutout.dart';

// Screen background color (visible before the child paints).
const _kScreenColor = Color(0xFF000000);

/// Clips a [CustomPaint] canvas to the device screen shape and fills cut-out
/// regions with black so that app content is physically absent there.
///
/// The painter fills the entire painter bounds. The canvas is first clipped
/// to the rounded-corner screen shape (using [DeviceProfile.screenCornerRadius]),
/// then the cutout region is subtracted, leaving only the usable screen area
/// exposed to child widgets.
///
/// [ScreenClipWidget] uses this painter and positions its child to fill the
/// same full bounds.
class ScreenClipPainter extends CustomPainter {
  const ScreenClipPainter({required this.profile, required this.orientation});

  /// The device whose screen geometry to use for clipping.
  final DeviceProfile profile;

  /// The current screen orientation.
  final DeviceOrientation orientation;

  /// Returns the rect (in painter-local coordinates) within which app content
  /// renders, given [painterSize], [profile], and [orientation].
  ///
  /// With no bezels, this is always the full [painterSize] bounds.
  static Rect screenRectForSize(
    Size painterSize,
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) {
    return Offset.zero & painterSize;
  }

  /// Returns the clip path for [size], [profile], and [orientation].
  ///
  /// The path is the intersection of the rounded screen rect and the inverse
  /// of the cutout region — i.e. the area where app content should be visible.
  /// Used by [ScreenClipWidget] to clip the child widget tree.
  static Path buildClipPath(
    Size size,
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) {
    final screenRect = Offset.zero & size;
    final radius = Radius.circular(profile.screenCornerRadius);
    final screenRRect = RRect.fromRectAndRadius(screenRect, radius);
    final screenPath = Path()..addRRect(screenRRect);

    final cutout = profile.cutoutForOrientation(orientation);
    if (cutout is NoCutout) return screenPath;

    final cutoutPath = _buildCutoutPath(cutout, screenRect);
    return Path.combine(PathOperation.difference, screenPath, cutoutPath);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Offset.zero & size;
    final radius = Radius.circular(profile.screenCornerRadius);
    final screenRRect = RRect.fromRectAndRadius(screenRect, radius);

    // Clip to rounded screen corners, then fill with black. This black fill
    // is visible in the cutout region (and as a backing colour) because the
    // child's ClipPath — applied by ScreenClipWidget — subtracts the cutout
    // area from the child, letting this fill show through.
    canvas.clipRRect(screenRRect);
    canvas.drawRect(screenRect, Paint()..color = _kScreenColor);
  }

  static Path _buildCutoutPath(ScreenCutout cutout, Rect screenRect) {
    return switch (cutout) {
      NoCutout() => Path(),
      NotchCutout(:final size, :final topOffset) =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              screenRect.left + (screenRect.width - size.width) / 2,
              screenRect.top + topOffset,
              size.width,
              size.height,
            ),
            const Radius.circular(4),
          ),
        ),
      DynamicIslandCutout(:final size, :final topOffset) =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              screenRect.left + (screenRect.width - size.width) / 2,
              screenRect.top + topOffset,
              size.width,
              size.height,
            ),
            // Pill shape — fully rounded on the short axis.
            Radius.circular(size.height / 2),
          ),
        ),
      PunchHoleCutout(:final diameter, :final topOffset, :final centerX) =>
        Path()..addOval(
          Rect.fromCenter(
            center: Offset(
              centerX != null
                  ? screenRect.left + centerX
                  : screenRect.center.dx,
              screenRect.top + topOffset,
            ),
            width: diameter,
            height: diameter,
          ),
        ),
      SideCutout(:final size, :final centerOffset, :final edgeOffset) =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              screenRect.left + edgeOffset,
              screenRect.top + centerOffset - size.height / 2,
              size.width,
              size.height,
            ),
            const Radius.circular(4),
          ),
        ),
    };
  }

  @override
  bool shouldRepaint(ScreenClipPainter oldDelegate) =>
      oldDelegate.profile != profile || oldDelegate.orientation != orientation;
}
