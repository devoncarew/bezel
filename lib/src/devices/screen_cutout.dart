import 'dart:ui' show Offset, Path, Radius, Rect, RRect, Size;

/// Models the physical camera cutout geometry for a device screen.
///
/// Cutout coordinates are expressed in logical pixels from the top-left corner
/// of the screen area in **portrait** orientation. Used by [ScreenClipPainter]
/// to clip the camera housing region from the canvas.
///
/// Each subclass implements [buildPath] to produce the portrait clip path.
/// Landscape rendering is handled by the painter, which applies a rotation
/// transform to the portrait path — so cutout subclasses only need to know
/// about their portrait geometry.
sealed class ScreenCutout {
  const ScreenCutout();

  /// Builds the clip [Path] for this cutout in portrait orientation.
  ///
  /// [screenRect] is the portrait screen rectangle (typically
  /// `Offset.zero & portraitSize`). The returned path describes the region
  /// that should be *subtracted* from the visible screen area.
  ///
  /// Returns an empty path for [NoCutout].
  Path buildPath(Rect screenRect);
}

/// No cutout — large-bezel devices such as iPhone SE and iPads.
final class NoCutout extends ScreenCutout {
  const NoCutout();

  @override
  Path buildPath(Rect screenRect) => Path();
}

/// Wide notch at the top center — older iPhones (X–14) and some Androids.
final class NotchCutout extends ScreenCutout {
  /// Width and height of the notch in logical pixels.
  final Size size;

  /// Distance from the top edge of the screen area. Usually 0 (flush).
  final double topOffset;

  const NotchCutout({required this.size, this.topOffset = 0});

  @override
  Path buildPath(Rect screenRect) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          screenRect.left + (screenRect.width - size.width) / 2,
          screenRect.top + topOffset,
          size.width,
          size.height,
        ),
        const Radius.circular(4),
      ),
    );
  }
}

/// Dynamic Island pill cutout — iPhone 15 and later.
final class DynamicIslandCutout extends ScreenCutout {
  /// Width and height of the pill in logical pixels.
  final Size size;

  /// Distance from the top edge of the screen area.
  final double topOffset;

  const DynamicIslandCutout({required this.size, required this.topOffset});

  @override
  Path buildPath(Rect screenRect) {
    return Path()..addRRect(
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
    );
  }
}

/// Teardrop / Infinity-U notch — Samsung Galaxy A-series and similar Androids.
///
/// The notch is flush with the screen top edge. The bottom is a semicircular
/// arc (radius defaults to [width] / 2) surrounding the camera. At the top
/// corners, the notch curves *outward* — away from the notch centre — with
/// radius [sideRadius], giving the characteristic concave "ear" shape where
/// the notch meets the screen edge.
final class TeardropCutout extends ScreenCutout {
  /// Maximum width of the notch at its widest (circular bottom), in logical px.
  final double width;

  /// Total depth of the notch from the screen top edge, in logical pixels.
  final double height;

  /// Radius of the bottom arc. Defaults to [width] / 2 (a perfect semicircle).
  final double bottomRadius;

  /// Radius of the concave ear where the notch sides meet the top edge,
  /// in logical pixels.
  final double sideRadius;

  const TeardropCutout({
    required this.width,
    required this.height,
    required this.bottomRadius,
    required this.sideRadius,
  });

  @override
  Path buildPath(Rect screenRect) {
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
}

/// Small circular punch-hole camera — Pixel, Galaxy S series.
final class PunchHoleCutout extends ScreenCutout {
  /// Diameter of the circle in logical pixels.
  final double diameter;

  /// Distance from the top edge of the screen area to the center of the hole.
  final double topOffset;

  /// Horizontal center of the hole in logical pixels.
  ///
  /// `null` means horizontally centered on the screen.
  final double? centerX;

  const PunchHoleCutout({
    required this.diameter,
    required this.topOffset,
    this.centerX,
  });

  @override
  Path buildPath(Rect screenRect) {
    return Path()..addOval(
      Rect.fromCenter(
        center: Offset(
          centerX != null ? screenRect.left + centerX! : screenRect.center.dx,
          screenRect.top + topOffset,
        ),
        width: diameter,
        height: diameter,
      ),
    );
  }
}

/// A notch cutout described by Bezier path data from the iOS Simulator
/// sensor-bar PDF.
///
/// The path is encoded as a list of PathOps in [ops].
///
/// | PathOp | Args | Meaning |
/// |--------|------|---------|
/// | [PathOpMoveTo]  | x, y | PDF moveto |
/// | [PathOpLineTo]  | x, y | PDF lineto |
/// | [PathOpCubicTo] | cp1x, cp1y, cp2x, cp2y, x, y | PDF curveto |
/// | [PathOpClose]   | — | close path |
///
/// Coordinates are in **PDF convention**: y = 0 at the bottom of the
/// MediaBox, y increases upward. The path is horizontally centered on the
/// screen when rendered. [mediaBoxWidth] x [mediaBoxHeight] gives the
/// bounding area.
///
/// See `tool/extract_simdevicetype.dart` for how this data is extracted.
final class PathCutout extends ScreenCutout {
  /// Width of the PDF MediaBox in logical points.
  final double mediaBoxWidth;

  /// Height of the PDF MediaBox in logical points (= notch depth from screen
  /// top to the bottom of the cutout shape).
  final double mediaBoxHeight;

  /// Flat list of path operations.
  final List<PathOp> ops;

  const PathCutout({
    required this.mediaBoxWidth,
    required this.mediaBoxHeight,
    required this.ops,
  });

  @override
  Path buildPath(Rect screenRect) {
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
}

sealed class PathOp {
  static PathOp moveTo(double x, double y) => PathOpMoveTo(x, y);

  static PathOp lineTo(double x, double y) => PathOpLineTo(x, y);

  static PathOp curveTo(
    double cp1x,
    double cp1y,
    double cp2x,
    double cp2y,
    double x,
    double y,
  ) => PathOpCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);

  static PathOp close() => PathOpClose();
}

/// Represents a PDF moveto operation.
class PathOpMoveTo extends PathOp {
  final double x;
  final double y;

  PathOpMoveTo(this.x, this.y);
}

/// Represents a PDF lineto operation.
class PathOpLineTo extends PathOp {
  final double x;
  final double y;

  PathOpLineTo(this.x, this.y);
}

/// Represents a PDF curveto operation.
class PathOpCurveTo extends PathOp {
  final double cp1x;
  final double cp1y;
  final double cp2x;
  final double cp2y;
  final double x;
  final double y;

  PathOpCurveTo(this.cp1x, this.cp1y, this.cp2x, this.cp2y, this.x, this.y);
}

/// Represents a close path operation.
class PathOpClose extends PathOp {}
