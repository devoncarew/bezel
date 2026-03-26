import 'package:flutter/widgets.dart';

import '../devices/device_profile.dart';
import 'screen_clip_painter.dart';

/// Clips [child] to the device screen shape — rounded corners and cutout.
///
/// Uses [LayoutBuilder] to fill the available space and positions [child] to
/// fill the full bounds. The canvas clip (rounded corners minus cutout) is
/// applied by [ScreenClipPainter], so child pixels are physically absent inside
/// both the corner regions and the camera housing area.
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
      child: child,
    );
  }
}
