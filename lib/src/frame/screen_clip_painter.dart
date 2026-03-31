import 'dart:math' show pi;

import 'package:flutter/rendering.dart';

import '../devices/device_profile.dart';
import '../devices/screen_border.dart';
import '../devices/screen_cutout.dart';

// Screen background color (visible before the child paints).
const _kScreenColor = Color(0xFF000000);

/// Clips a [CustomPaint] canvas to the device screen shape and fills cut-out
/// regions with black so that app content is physically absent there.
///
/// The painter fills the entire painter bounds. The canvas is first clipped
/// to the screen corner shape (circular arc or squircle depending on the
/// profile's [ScreenBorder]), then the cutout region is subtracted, leaving
/// only the usable screen area exposed to child widgets.
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
  /// The path is the intersection of the screen shape and the inverse of the
  /// cutout region — i.e. the area where app content should be visible.
  /// Used by [ScreenClipWidget] to clip the child widget tree.
  static Path buildClipPath(
    Size size,
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) {
    final screenPath = _buildScreenPath(size, profile.screenBorder);
    final cutout = profile.cutout;
    if (cutout is NoCutout) return screenPath;

    final cutoutPath = _buildOrientedCutoutPath(
      cutout,
      size,
      profile.logicalSize,
      orientation,
    );
    return Path.combine(PathOperation.difference, screenPath, cutoutPath);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final screenPath = _buildScreenPath(size, profile.screenBorder);

    // Clip to the screen shape, then fill with black. This black fill is
    // visible in the cutout region because the child's ClipPath (applied by
    // ScreenClipWidget) subtracts the cutout area, letting this fill show.
    canvas.clipPath(screenPath);
    canvas.drawRect(Offset.zero & size, Paint()..color = _kScreenColor);
  }

  @override
  bool shouldRepaint(ScreenClipPainter oldDelegate) =>
      oldDelegate.profile != profile || oldDelegate.orientation != orientation;
}

// ── Cutout path (portrait + landscape transform) ─────────────────────────────

/// Builds the cutout clip path for the given [orientation].
///
/// In portrait, delegates directly to [ScreenCutout.buildPath]. In landscape,
/// builds the portrait path and applies a clockwise 90-degree rotation
/// transform: `(x, y) -> (y, portraitWidth - x)`. This maps the portrait top
/// edge onto the landscape left edge, preserving the full cutout geometry
/// (Bezier curves, teardrop ears, etc.) without any lossy conversion.
Path _buildOrientedCutoutPath(
  ScreenCutout cutout,
  Size screenSize,
  Size portraitLogicalSize,
  DeviceOrientation orientation,
) {
  if (orientation == DeviceOrientation.portrait) {
    return cutout.buildPath(Offset.zero & screenSize);
  }

  // Build the path in portrait coordinates, then rotate to landscape.
  final portraitPath = cutout.buildPath(Offset.zero & portraitLogicalSize);
  final w = portraitLogicalSize.width;

  // Clockwise 90-degree rotation: (x, y) -> (y, w - x).
  //
  // Matrix4 operations compose right-to-left: first rotateZ (CW 90), then
  // translate by (0, w) to shift coordinates back into positive space.
  //
  // rotateZ(-pi/2): (x, y) -> (y, -x)
  // translate(0, w): (y, -x) -> (y, w - x)
  final matrix = Matrix4.identity()
    ..translateByDouble(0.0, w, 0.0, 1.0)
    ..rotateZ(-pi / 2);

  return portraitPath.transform(matrix.storage);
}

// ── Screen shape path ─────────────────────────────────────────────────────────

/// Builds the screen outline path for [border] at [size].
Path _buildScreenPath(Size size, ScreenBorder border) {
  return switch (border) {
    CircularBorder(:final radius) =>
      Path()..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      ),
    SquircleBorder() => _buildSquirclePath(size, border),
  };
}

/// Builds a full squircle screen outline path from the corner Bezier data in
/// [border].
///
/// [SquircleBorder.segments] describe the top-right corner going from the
/// tangent on the top edge to the tangent on the right edge, in coordinates
/// relative to the top-right corner position (logW, 0). The painter reuses
/// this corner for all four corners via sign-flip transforms.
///
/// Reflecting across **both** axes (sx=-1, sy=-1: bottom-left) or **neither**
/// (sx=1, sy=1: top-right) preserves path orientation, so the segments can be
/// applied in forward order. Reflecting across **one** axis (bottom-right:
/// sy=-1; top-left: sx=-1) reverses orientation, so those two corners must
/// apply the segments in reverse order (see [_addCornerSegmentsReversed]).
///
/// Corner construction:
///   - Top edge: top-left tangent -> top-right tangent.
///   - Top-right: forward segments, ox=(w,0), sx=1,  sy=1.
///   - Right edge: down to bottom-right tangent.
///   - Bottom-right: reversed segments, ox=(w,h), sx=1,  sy=-1.
///   - Bottom edge: right tangent -> left tangent.
///   - Bottom-left: forward segments, ox=(0,h), sx=-1, sy=-1.
///   - Left edge: up to top-left tangent.
///   - Top-left: reversed segments, ox=(0,0), sx=-1, sy=1.
Path _buildSquirclePath(Size size, SquircleBorder border) {
  final w = size.width;
  final h = size.height;
  final topT = border.topTangentLength;
  final sideT = border.sideTangentLength;
  final segs = border.segments;

  final path = Path();

  // ── Top edge ────────────────────────────────────────────────────────────
  path.moveTo(topT, 0); // top-left tangent (mirror of top-right)
  path.lineTo(w - topT, 0); // top-right tangent

  // ── Top-right corner ────────────────────────────────────────────────────
  _addCornerSegments(path, segs, ox: w, oy: 0, sx: 1, sy: 1);

  // ── Right edge ──────────────────────────────────────────────────────────
  path.lineTo(w, h - sideT);

  // ── Bottom-right corner ─────────────────────────────────────────────────
  // Single-axis reflection (sy=-1) reverses orientation -> use reversed order.
  _addCornerSegmentsReversed(
    path,
    segs,
    ox: w,
    oy: h,
    sx: 1,
    sy: -1,
    topT: topT,
  );

  // ── Bottom edge ─────────────────────────────────────────────────────────
  path.lineTo(topT, h);

  // ── Bottom-left corner ───────────────────────────────────────────────────
  // Double-axis reflection preserves orientation -> forward order is correct.
  _addCornerSegments(path, segs, ox: 0, oy: h, sx: -1, sy: -1);

  // ── Left edge ───────────────────────────────────────────────────────────
  path.lineTo(0, sideT);

  // ── Top-left corner ──────────────────────────────────────────────────────
  // Single-axis reflection (sx=-1) reverses orientation -> use reversed order.
  _addCornerSegmentsReversed(
    path,
    segs,
    ox: 0,
    oy: 0,
    sx: -1,
    sy: 1,
    topT: topT,
  );

  path.close();
  return path;
}

/// Appends the squircle corner [segs] to [path] in forward order, transforming
/// each point by `x_out = ox + sx * seg_x`, `y_out = oy + sy * seg_y`.
///
/// Used for top-right (sx=1, sy=1) and bottom-left (sx=-1, sy=-1), where the
/// double-axis reflection preserves path orientation.
void _addCornerSegments(
  Path path,
  List<List<double>> segs, {
  required double ox,
  required double oy,
  required double sx,
  required double sy,
}) {
  for (final seg in segs) {
    path.cubicTo(
      ox + sx * seg[0],
      oy + sy * seg[1],
      ox + sx * seg[2],
      oy + sy * seg[3],
      ox + sx * seg[4],
      oy + sy * seg[5],
    );
  }
}

/// Appends the squircle corner [segs] to [path] in **reverse** order.
///
/// Used for bottom-right (sx=1, sy=-1) and top-left (sx=-1, sy=1), where a
/// single-axis reflection reverses the winding direction. Reversing each cubic
/// means swapping its two control points and using the previous segment's
/// endpoint as the new destination. The last reversed segment lands at the
/// corner's natural start point `(ox + sx * (-topT), oy)`.
void _addCornerSegmentsReversed(
  Path path,
  List<List<double>> segs, {
  required double ox,
  required double oy,
  required double sx,
  required double sy,
  required double topT,
}) {
  for (var i = segs.length - 1; i >= 0; i--) {
    final seg = segs[i];

    // Reversed cubic: cp1 <-> cp2 swapped; endpoint is the previous seg's endpoint
    // (or the corner's natural start for the very last reversed segment).
    final double rendx;
    final double rendy;
    if (i > 0) {
      rendx = ox + sx * segs[i - 1][4];
      rendy = oy + sy * segs[i - 1][5];
    } else {
      rendx = ox + sx * (-topT);
      rendy = oy; // sy * 0 == 0
    }
    path.cubicTo(
      ox + sx * seg[2],
      oy + sy * seg[3],
      ox + sx * seg[0],
      oy + sy * seg[1],
      rendx,
      rendy,
    );
  }
}
