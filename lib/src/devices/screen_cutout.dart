import 'dart:ui' show Size;

/// Models the physical camera cutout geometry for a device screen.
///
/// Cutout coordinates are expressed in logical pixels from the top-left corner
/// of the screen area. Used by [ScreenClipPainter] to clip the camera housing
/// region from the canvas.
sealed class ScreenCutout {
  const ScreenCutout();

  /// Returns the cutout geometry appropriate for landscape orientation.
  ///
  /// [portraitScreenSize] is the portrait logical screen size, used to compute
  /// the cutout position after the screen is rotated. The default
  /// implementation returns [this], which is correct for [NoCutout] and
  /// [_SideCutout].
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) => this;
}

/// No cutout — large-bezel devices such as iPhone SE and iPads.
final class NoCutout extends ScreenCutout {
  const NoCutout();
}

/// Wide notch at the top center — older iPhones (X–14) and some Androids.
final class NotchCutout extends ScreenCutout {
  /// Width and height of the notch in logical pixels.
  final Size size;

  /// Distance from the top edge of the screen area. Usually 0 (flush).
  final double topOffset;

  const NotchCutout({required this.size, this.topOffset = 0});

  @override
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) => SideCutout(
    size: Size(size.height, size.width),
    // The notch is horizontally centered in portrait; after rotation its
    // portrait x-center (portrait width / 2) becomes the landscape y-center.
    centerOffset: portraitScreenSize.width / 2,
    edgeOffset: topOffset,
    cornerRadius: 4,
  );
}

/// Dynamic Island pill cutout — iPhone 15 and later.
final class DynamicIslandCutout extends ScreenCutout {
  /// Width and height of the pill in logical pixels.
  final Size size;

  /// Distance from the top edge of the screen area.
  final double topOffset;

  const DynamicIslandCutout({required this.size, required this.topOffset});

  @override
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) => SideCutout(
    size: Size(size.height, size.width),
    // The DI is horizontally centered in portrait; after rotation its
    // portrait x-center (portrait width / 2) becomes the landscape y-center.
    centerOffset: portraitScreenSize.width / 2,
    edgeOffset: topOffset,
    // Rotated pill: short axis is now the width (size.height from portrait).
    cornerRadius: size.height / 2,
  );
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
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) => SideCutout(
    // Portrait width ↔ landscape height, portrait height ↔ landscape width.
    size: Size(height, width),
    // The notch is centered on the portrait width; after rotation that
    // x-centre becomes the landscape y-centre.
    centerOffset: portraitScreenSize.width / 2,
    cornerRadius: bottomRadius,
  );
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
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) {
    // When null, the hole is centered on the portrait width, which becomes the
    // landscape height's center after rotation.
    final cx = centerX ?? portraitScreenSize.width / 2;
    return SideCutout(
      size: Size(diameter, diameter),
      centerOffset: cx,
      edgeOffset: topOffset,
      cornerRadius: diameter / 2,
    );
  }
}

/// A cutout on the left edge, produced by landscape rotation of a portrait
/// cutout via [ScreenCutout.rotatedForLandscape].
///
/// Not typically instantiated directly — use [ScreenCutout.rotatedForLandscape]
/// to obtain one.
final class SideCutout extends ScreenCutout {
  /// Width and height of the cutout bounding box, in logical pixels.
  final Size size;

  /// Distance from the top of the screen to the center of the cutout,
  /// in logical pixels.
  final double centerOffset;

  /// Distance from the left edge of the screen area to the near side of the
  /// cutout, in logical pixels.
  final double edgeOffset;

  /// Corner radius of the cutout shape, in logical pixels.
  ///
  /// Defaults to 4, which suits a notch. A Dynamic Island rotated to landscape
  /// should use [size.width] / 2 to preserve the pill shape.
  final double cornerRadius;

  const SideCutout({
    required this.size,
    required this.centerOffset,
    this.edgeOffset = 0,
    this.cornerRadius = 4,
  });
}
