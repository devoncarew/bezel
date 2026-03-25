import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../frame/device_frame_widget.dart';
import '../preview_controller.dart';

/// Background colour shown behind the device frame.
const _kBackgroundColor = Color(0xFF121212);

/// Wraps the app in a device-frame preview UI.
///
/// Uses [LayoutBuilder] + [ListenableBuilder] to react to both window-size
/// changes and [PreviewController] state changes. Centers a [DeviceFrameWidget]
/// scaled to fit the available space, with a dark matte background.
///
/// Installed automatically by [PreviewBinding.attachRootWidget]. Should not
/// need to be used directly.
class PreviewOverlay extends StatelessWidget {
  const PreviewOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  /// The shared controller for this preview session.
  final PreviewController controller;

  /// The app's root widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.biggest;
            final emulated = controller.emulatedLogicalSize;
            final scale = _computeScale(available, emulated);

            return ColoredBox(
              color: _kBackgroundColor,
              child: Stack(
                children: [
                  // Device frame, centered and scaled to fit.
                  // ClipRect prevents overflow debug banners when the emulated
                  // device is larger than the available window space.
                  ClipRect(
                    child: Center(
                      child: SizedBox(
                        width: emulated.width,
                        height: emulated.height,
                        child: Transform.scale(
                          scale: scale,
                          child: DeviceFrameWidget(
                            profile: controller.activeProfile,
                            orientation: controller.orientation,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // TODO(step 2.5): PreviewToolbar goes here.
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Computes the uniform scale factor to apply to the device frame.
  ///
  /// Returns 1.0 when the emulated size fits within 90 % of [available].
  /// Otherwise returns the largest scale that fits within [available] with a
  /// 10 % margin.
  static double computeScale(Size available, Size emulated) =>
      _computeScale(available, emulated);

  static double _computeScale(Size available, Size emulated) {
    if (emulated.width <= available.width * 0.9 &&
        emulated.height <= available.height * 0.9) {
      return 1.0;
    }
    return math.min(
          available.width / emulated.width,
          available.height / emulated.height,
        ) *
        0.9;
  }
}
