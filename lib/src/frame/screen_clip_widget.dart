import 'package:flutter/widgets.dart';

import '../devices/device_profile.dart';
import 'screen_clip_painter.dart';

/// Clips [child] to the device screen shape — rounded corners and cutout.
///
/// [ScreenClipPainter] draws a black background fill clipped to the rounded
/// screen rect (visible behind app content and inside the cutout region).
/// A [ClipPath] widget applies the same geometry — rounded corners minus
/// cutout — to the child widget tree, so app pixels are physically absent
/// inside the corner regions and the camera housing area.
///
/// This widget does **not** perform any metric spoofing — it is purely
/// cosmetic. Metric spoofing happens in the binding layer.
class ScreenClipWidget extends StatelessWidget {
  const ScreenClipWidget({
    super.key,
    required this.profile,
    required this.orientation,
    required this.child,
  });

  /// The device whose screen geometry to use for clipping.
  final DeviceProfile profile;

  /// The current screen orientation.
  final DeviceOrientation orientation;

  /// The app content to display inside the screen area.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScreenClipPainter(profile: profile, orientation: orientation),
      child: ClipPath(
        clipper: _ScreenClipper(profile: profile, orientation: orientation),
        child: child,
      ),
    );
  }
}

/// [CustomClipper] that clips to the device screen shape: a rounded rect with
/// the camera cutout region subtracted.
class _ScreenClipper extends CustomClipper<Path> {
  _ScreenClipper({required this.profile, required this.orientation});

  final DeviceProfile profile;
  final DeviceOrientation orientation;

  @override
  Path getClip(Size size) =>
      ScreenClipPainter.buildClipPath(size, profile, orientation);

  @override
  bool shouldReclip(_ScreenClipper old) =>
      old.profile != profile || old.orientation != orientation;
}
