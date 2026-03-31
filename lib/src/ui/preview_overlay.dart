import 'dart:math' as math;

import 'package:flutter/material.dart' show Theme, ThemeData, Brightness;
import 'package:flutter/widgets.dart';

import '../frame/screen_clip_widget.dart';
import '../preview_controller.dart';
import '../theme.dart';
import 'control_badge.dart';
import 'control_panel.dart';
import 'preview_shortcuts.dart';

/// Wraps the app in a device-frame preview UI.
///
/// The emulator area is edge-to-edge with the window content area. The
/// [ControlBadge] and [ControlPanel] are overlaid in the top-right corner.
///
/// [ListenableBuilder] rebuilds on [PreviewController] changes. The device
/// area uses an inner [LayoutBuilder] so [computeScale] operates on the actual
/// available space.
///
/// Installed automatically by [PreviewBinding.wrapWithDefaultView]. Should not
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
    // Directionality + Theme are provided here because the overlay sits above
    // the user's MaterialApp and has no such ancestors. They wrap everything,
    // including the badge, so it renders correctly in passthrough mode too.
    //
    // Overlay is required by Tooltip (used in ControlPanel's IconButtons).
    // PreviewOverlay sits above the user's MaterialApp so no Overlay ancestor
    // exists; we provide one explicitly here.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: ThemeData(brightness: Brightness.dark),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => PreviewShortcuts(
                controller: controller,
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    if (controller.passthroughMode) {
                      // In passthrough mode render the app at its natural
                      // size with the badge overlaid so the user can
                      // return to preview mode.
                      return Stack(
                        children: [
                          child,
                          Positioned(
                            top: 0,
                            right: 0,
                            child: ControlBadge(controller: controller),
                          ),
                        ],
                      );
                    }

                    return ColoredBox(
                      color: kPreviewBackground,
                      child: Stack(
                        children: [
                          // Emulator area fills the full content area.
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final emulated = controller.emulatedLogicalSize;
                              final scale = computeScale(
                                constraints.biggest,
                                emulated,
                              );
                              return Center(
                                child: SizedBox(
                                  width: emulated.width * scale,
                                  height: emulated.height * scale,
                                  child: ScreenClipWidget(
                                    profile: controller.activeProfile,
                                    orientation: controller.orientation,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Control panel — always mounted so it can
                          // animate in and out. Anchored to the top-right
                          // corner (below the badge) with its own
                          // full-window backdrop.
                          Positioned.fill(
                            child: ControlPanel(controller: controller),
                          ),

                          // Control badge — anchored to top-right corner.
                          Positioned(
                            top: 0,
                            right: 0,
                            child: ControlBadge(controller: controller),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Computes the uniform scale factor to fit [emulated] inside [available].
  ///
  /// Returns the largest scale ≤ 1.0 such that the scaled emulated size fits
  /// within [available]. Returns 1.0 when the emulated size already fits.
  static double computeScale(Size available, Size emulated) {
    return math
        .min(
          available.width / emulated.width,
          available.height / emulated.height,
        )
        .clamp(0.0, 1.0);
  }
}
