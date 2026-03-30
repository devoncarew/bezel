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
    final cutout = profile.cutoutForOrientation(orientation);
    if (cutout is NoCutout) return screenPath;

    final cutoutPath = _buildCutoutPath(cutout, Offset.zero & size);
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

/// Builds a full squircle screen outline path from the corner Bézier data in
/// [border].
///
/// [SquircleBorder.segments] describe the top-right corner going from the
/// tangent on the top edge to the tangent on the right edge, in coordinates
/// relative to the top-right corner position (logW, 0). The painter reuses
/// this corner for all four corners via sign-flip transforms.
///
/// Reflecting across **both** axes (sx=−1, sy=−1: bottom-left) or **neither**
/// (sx=1, sy=1: top-right) preserves path orientation, so the segments can be
/// applied in forward order. Reflecting across **one** axis (bottom-right:
/// sy=−1; top-left: sx=−1) reverses orientation, so those two corners must
/// apply the segments in reverse order (see [_addCornerSegmentsReversed]).
///
/// Corner construction:
///   - Top edge: top-left tangent → top-right tangent.
///   - Top-right: forward segments, ox=(w,0), sx=1,  sy=1.
///   - Right edge: down to bottom-right tangent.
///   - Bottom-right: reversed segments, ox=(w,h), sx=1,  sy=−1.
///   - Bottom edge: right tangent → left tangent.
///   - Bottom-left: forward segments, ox=(0,h), sx=−1, sy=−1.
///   - Left edge: up to top-left tangent.
///   - Top-left: reversed segments, ox=(0,0), sx=−1, sy=1.
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
  // Single-axis reflection (sy=−1) reverses orientation → use reversed order.
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
  // Double-axis reflection preserves orientation → forward order is correct.
  _addCornerSegments(path, segs, ox: 0, oy: h, sx: -1, sy: -1);

  // ── Left edge ───────────────────────────────────────────────────────────
  path.lineTo(0, sideT);

  // ── Top-left corner ──────────────────────────────────────────────────────
  // Single-axis reflection (sx=−1) reverses orientation → use reversed order.
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
/// Used for top-right (sx=1, sy=1) and bottom-left (sx=−1, sy=−1), where the
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
/// Used for bottom-right (sx=1, sy=−1) and top-left (sx=−1, sy=1), where a
/// single-axis reflection reverses the winding direction. Reversing each cubic
/// means swapping its two control points and using the previous segment's
/// endpoint as the new destination. The last reversed segment lands at the
/// corner's natural start point `(ox + sx * (−topT), oy)`.
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

    // Reversed cubic: cp1 ↔ cp2 swapped; endpoint is the previous seg's endpoint
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

// ── Cutout paths ──────────────────────────────────────────────────────────────

Path _buildCutoutPath(ScreenCutout cutout, Rect screenRect) {
  return switch (cutout) {
    NoCutout() => Path(),
    TeardropCutout(
      :final width,
      :final height,
      :final bottomRadius,
      :final sideRadius,
    ) =>
      _buildTeardropPath(
        screenRect,
        width: width,
        height: height,
        bottomRadius: bottomRadius,
        sideRadius: sideRadius,
      ),
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
            centerX != null ? screenRect.left + centerX : screenRect.center.dx,
            screenRect.top + topOffset,
          ),
          width: diameter,
          height: diameter,
        ),
      ),
    SideCutout(
      :final size,
      :final centerOffset,
      :final edgeOffset,
      :final cornerRadius,
    ) =>
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            screenRect.left + edgeOffset,
            screenRect.top + centerOffset - size.height / 2,
            size.width,
            size.height,
          ),
          Radius.circular(cornerRadius),
        ),
      ),
    PathCutout(:final mediaBoxWidth, :final mediaBoxHeight, :final ops) =>
      _buildPathCutoutPath(
        screenRect,
        mediaBoxWidth: mediaBoxWidth,
        mediaBoxHeight: mediaBoxHeight,
        ops: ops,
      ),
  };
}

/// Replays the [PathCutout.ops] list as a Flutter [Path], converting from PDF
/// coordinates (y=0 at the bottom of the MediaBox) to Flutter screen
/// coordinates (y=0 at the top of [screenRect]).
///
/// The path is horizontally centered on [screenRect].
Path _buildPathCutoutPath(
  Rect screenRect, {
  required double mediaBoxWidth,
  required double mediaBoxHeight,
  required List<PathOp> ops,
}) {
  // Horizontal offset to centre the MediaBox on the screen.
  final offsetX = screenRect.left + (screenRect.width - mediaBoxWidth) / 2;
  final offsetY = screenRect.top;

  // Convert a PDF x coordinate to Flutter screen x.
  double fx(double pdfX) => offsetX + pdfX;
  // Convert a PDF y coordinate to Flutter screen y (flip axis).
  double fy(double pdfY) => offsetY + mediaBoxHeight - pdfY;

  final path = Path();

  for (final op in ops) {
    switch (op) {
      case PathOpMoveTo():
        path.moveTo(fx(op.x), fy(op.y));
      case PathOpLineTo():
        path.lineTo(fx(op.x), fy(op.y));
      case PathOpCurveTo():
        path.cubicTo(
          fx(op.cp1x),
          fy(op.cp1y),
          fx(op.cp2x),
          fy(op.cp2y),
          fx(op.x),
          fy(op.y),
        );
      case PathOpClose():
        path.close();
    }
  }
  return path;
}

// Builds the clip path for a TeardropCutout centred at the top of
// [screenRect]. The shape is a narrow U with:
//   - concave "ear" arcs (radius [sideRadius]) at the top corners, curving
//     outward into the screen area
//   - straight sides running down from the ears
//   - a semicircular bottom arc (radius [bottomRadius]) surrounding the camera
Path _buildTeardropPath(
  Rect screenRect, {
  required double width,
  required double height,
  required double bottomRadius,
  required double sideRadius,
}) {
  final cx = screenRect.left + screenRect.width / 2;
  final top = screenRect.top;
  return Path()
    // Left ear: concave arc from the outer top edge into the left wall.
    ..moveTo(cx - width / 2 - sideRadius, top)
    ..arcToPoint(
      Offset(cx - width / 2, top + sideRadius),
      radius: Radius.circular(sideRadius),
      clockwise: true,
    )
    // Left straight side, down to where the bottom arc begins.
    ..lineTo(cx - width / 2, top + height - bottomRadius)
    // Bottom left corner.
    ..arcToPoint(
      Offset(cx - width / 2 + bottomRadius, top + height),
      radius: Radius.circular(bottomRadius),
      clockwise: false,
    )
    // Line across the bottom.
    ..lineTo(cx + width / 2 - bottomRadius, top + height)
    // Bottom right corner.
    ..arcToPoint(
      Offset(cx + width / 2, top + height - bottomRadius),
      radius: Radius.circular(bottomRadius),
      clockwise: false,
    )
    // Right straight side, back up to the ear.
    ..lineTo(cx + width / 2, top + sideRadius)
    // Right ear: symmetric concave arc back to the top edge.
    ..arcToPoint(
      Offset(cx + width / 2 + sideRadius, top),
      radius: Radius.circular(sideRadius),
      clockwise: true,
    )
    // Close across the top edge back to the start.
    ..close();
}
