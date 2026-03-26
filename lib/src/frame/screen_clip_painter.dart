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

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Offset.zero & size;
    final radius = Radius.circular(profile.screenCornerRadius);
    final screenRRect = RRect.fromRectAndRadius(screenRect, radius);

    // 1. Clip to rounded screen corners.
    canvas.clipRRect(screenRRect);

    // 2. Fill with black — this becomes the background behind app content and
    //    also the fill colour visible in the cutout region after step 3.
    canvas.drawRect(screenRect, Paint()..color = _kScreenColor);

    // 3. For non-NoCutout devices, further restrict the clip so that app
    //    content cannot paint inside the camera housing area. The black fill
    //    from step 2 remains visible there.
    final cutout = profile.cutoutForOrientation(orientation);
    if (cutout is! NoCutout) {
      final screenPath = Path()..addRRect(screenRRect);
      final cutoutPath = _buildCutoutPath(cutout, screenRect);
      canvas.clipPath(
        Path.combine(PathOperation.difference, screenPath, cutoutPath),
      );
    }
  }

  Path _buildCutoutPath(ScreenCutout cutout, Rect screenRect) {
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
