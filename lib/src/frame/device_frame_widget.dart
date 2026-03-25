import 'package:flutter/widgets.dart';

import '../devices/device_profile.dart';
import 'device_frame_painter.dart';

/// A purely decorative widget that paints a device frame around [child].
///
/// Uses [LayoutBuilder] to fill the available space, computes the screen rect
/// via [DeviceFramePainter.screenRectForSize], and positions [child] precisely
/// within that rect.
///
/// The cutout clip is applied by [DeviceFramePainter] directly to the canvas,
/// so child pixels are physically absent inside the camera housing region. The
/// [ClipRect] here only clips to the outer screen-rect boundary.
///
/// This widget does **not** perform any metric spoofing — it is purely
/// cosmetic. Metric spoofing happens in the binding layer.
class DeviceFrameWidget extends StatelessWidget {
  const DeviceFrameWidget({
    super.key,
    required this.profile,
    required this.orientation,
    required this.child,
  });

  /// The device whose frame to render.
  final DeviceProfile profile;

  /// The current screen orientation.
  final DeviceOrientation orientation;

  /// The app content to display inside the screen area.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final screenRect = DeviceFramePainter.screenRectForSize(
          size,
          profile,
          orientation,
        );

        return Stack(
          children: [
            // Device frame — fills the full layout bounds and sets the canvas
            // clip for anything rendered on top of it (including the child).
            Positioned.fill(
              child: CustomPaint(
                painter: DeviceFramePainter(
                  profile: profile,
                  orientation: orientation,
                ),
              ),
            ),

            // App content — constrained to the screen rect and clipped to its
            // boundary. The cutout clip from the painter further refines this.
            Positioned(
              left: screenRect.left,
              top: screenRect.top,
              width: screenRect.width,
              height: screenRect.height,
              child: ClipRect(child: child),
            ),
          ],
        );
      },
    );
  }
}
