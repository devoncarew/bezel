import 'package:flutter/rendering.dart';

import '../devices/device_profile.dart';
import '../devices/screen_cutout.dart';

// Body and bezel geometry constants (logical pixels in painter space).
const _kBodyRadius = Radius.circular(24.0);
const _kScreenRadius = Radius.circular(8.0);
const _kSideBezel = 8.0;
const _kModernBezel = 8.0;
const _kClassicTopBezel = 18.0;
const _kClassicBottomBezel = 42.0;

// Colors.
const _kBodyColor = Color(0xFF1C1C1E);
const _kScreenColor = Color(0xFF000000);
const _kDecorationColor = Color(0xFF3A3A3C);

/// Paints a simplified but recognizable device frame onto a [CustomPaint]
/// canvas.
///
/// The painter fills the entire painter bounds. The inner screen area —
/// the rect within which app content renders — is returned by the static
/// [screenRectForSize] helper, which [DeviceFrameWidget] uses to position
/// and size the child.
///
/// For non-[NoCutout] profiles the painter also applies a [Canvas.clipPath]
/// that subtracts the cutout shape from the screen area. Because Flutter
/// composites the child after the painter runs, this clip is inherited by
/// the child, meaning the child's pixels are physically absent in the cutout
/// region — matching real-device behaviour.
class DeviceFramePainter extends CustomPainter {
  const DeviceFramePainter({required this.profile, required this.orientation});

  /// The device whose frame geometry and style to render.
  final DeviceProfile profile;

  /// The current screen orientation.
  final DeviceOrientation orientation;

  /// Returns the rect (in painter-local coordinates) within which app content
  /// should render, given [painterSize], [profile], and [orientation].
  ///
  /// The returned rect is guaranteed to be contained within
  /// `Offset.zero & painterSize`. Its aspect ratio matches
  /// `profile.logicalSizeForOrientation(orientation)`.
  static Rect screenRectForSize(
    Size painterSize,
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) {
    return _bezelsFor(
      profile,
      orientation,
    ).deflateRect(Offset.zero & painterSize);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = screenRectForSize(size, profile, orientation);

    // 1. Device body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, _kBodyRadius),
      Paint()..color = _kBodyColor,
    );

    // 2. Frame-style decorations painted in the bezel region (before clip).
    _drawDecorations(canvas, size, screenRect);

    // 3. Clip canvas to the screen area (minus cutout) so the child widget
    //    and any subsequent drawing is occluded where the physical camera
    //    housing would be.
    _applyScreenClip(canvas, screenRect);

    // 4. Screen background (visible before the child paints).
    canvas.drawRect(screenRect, Paint()..color = _kScreenColor);
  }

  // ---------------------------------------------------------------------------
  // Frame decorations
  // ---------------------------------------------------------------------------

  void _drawDecorations(Canvas canvas, Size size, Rect screenRect) {
    // Classic layout: devices with no cutout (iPhone SE, iPads) have thick
    // bezels and decorative speaker / home-button indicators.
    if (profile.cutout is NoCutout) {
      _drawClassicDecorations(canvas, size, screenRect);
    }
  }

  void _drawClassicDecorations(Canvas canvas, Size size, Rect screenRect) {
    final paint = Paint()..color = _kDecorationColor;
    if (orientation == DeviceOrientation.portrait) {
      // Top speaker slit.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, screenRect.top / 2),
            width: 48,
            height: 5,
          ),
          const Radius.circular(2.5),
        ),
        paint,
      );
      // Bottom home-button indicator.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              size.width / 2,
              (screenRect.bottom + size.height) / 2,
            ),
            width: 36,
            height: 10,
          ),
          const Radius.circular(5),
        ),
        paint,
      );
    } else {
      // Landscape — speaker on the left, home button on the right.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(screenRect.left / 2, size.height / 2),
            width: 5,
            height: 48,
          ),
          const Radius.circular(2.5),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              (screenRect.right + size.width) / 2,
              size.height / 2,
            ),
            width: 10,
            height: 36,
          ),
          const Radius.circular(5),
        ),
        paint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Screen clip
  // ---------------------------------------------------------------------------

  void _applyScreenClip(Canvas canvas, Rect screenRect) {
    final cutout = profile.cutoutForOrientation(orientation);
    if (cutout is NoCutout) {
      canvas.clipRRect(RRect.fromRectAndRadius(screenRect, _kScreenRadius));
      return;
    }

    final screenPath = Path()
      ..addRRect(RRect.fromRectAndRadius(screenRect, _kScreenRadius));
    final cutoutPath = _buildCutoutPath(cutout, screenRect);
    canvas.clipPath(
      Path.combine(PathOperation.difference, screenPath, cutoutPath),
    );
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static EdgeInsets _bezelsFor(
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) {
    // Classic layout: devices with no cutout use asymmetric thick bezels.
    if (profile.cutout is NoCutout) {
      return orientation == DeviceOrientation.portrait
          ? const EdgeInsets.only(
              top: _kClassicTopBezel,
              bottom: _kClassicBottomBezel,
              left: _kSideBezel,
              right: _kSideBezel,
            )
          : const EdgeInsets.only(
              top: _kSideBezel,
              bottom: _kSideBezel,
              left: _kClassicTopBezel,
              right: _kClassicBottomBezel,
            );
    }
    return const EdgeInsets.all(_kModernBezel);
  }

  @override
  bool shouldRepaint(DeviceFramePainter oldDelegate) =>
      oldDelegate.profile != profile || oldDelegate.orientation != orientation;
}
