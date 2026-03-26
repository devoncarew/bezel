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
    centerOffset: portraitScreenSize.height / 2,
    edgeOffset: topOffset,
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
    centerOffset: portraitScreenSize.height / 2,
    edgeOffset: topOffset,
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

  /// Distance from the vertical midpoint of the left edge to the center of
  /// the cutout, in logical pixels.
  final double centerOffset;

  /// Distance from the left edge of the screen area to the near side of the
  /// cutout, in logical pixels.
  final double edgeOffset;

  const SideCutout({
    required this.size,
    required this.centerOffset,
    this.edgeOffset = 0,
  });
}
