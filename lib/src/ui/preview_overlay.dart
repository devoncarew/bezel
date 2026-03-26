import 'dart:math' as math;

import 'package:flutter/material.dart' show Theme, ThemeData, Brightness;
import 'package:flutter/widgets.dart';

import '../frame/screen_clip_widget.dart';
import '../preview_controller.dart';
import 'device_picker.dart';
import 'macos_menu.dart';
import 'preview_shortcuts.dart';
import 'preview_toolbar.dart';

/// Background colour shown behind the device frame.
///
/// A medium-dark neutral so the near-black device frame has enough contrast
/// to read clearly without the background feeling overly bright.
const _kBackgroundColor = Color(0xFF4A4A52);

/// Wraps the app in a device-frame preview UI.
///
/// Uses [LayoutBuilder] + [ListenableBuilder] to react to both window-size
/// changes and [PreviewController] state changes. Scales the [ScreenClipWidget]
/// to fill the available area, letterboxing with the background colour on
/// whichever axis has leftover space.
///
/// The floating toolbar overlaps the bottom edge of the device content.
/// Because [PreviewFlutterView] reports a [physicalSize] derived purely from
/// the emulated logical dimensions, the available area normally equals the
/// emulated size and [computeScale] returns 1.0. If the user manually resizes
/// the window, [computeScale] letterboxes the content to fit.
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
    return MacosPreviewMenu(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.passthroughMode) {
            return child;
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.biggest;
              final emulated = controller.emulatedLogicalSize;
              final scale = computeScale(available, emulated);

              // Directionality + Theme are provided here because the overlay
              // sits above the user's MaterialApp and has no such ancestors.
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Theme(
                  data: ThemeData(brightness: Brightness.dark),
                  child: PreviewShortcuts(
                    controller: controller,
                    child: ColoredBox(
                      color: _kBackgroundColor,
                      child: Stack(
                        children: [
                          // Device content — centered and letterboxed within
                          // the full available area.
                          Positioned.fill(
                            child: Center(
                              child: SizedBox(
                                width: emulated.width * scale,
                                height: emulated.height * scale,
                                child: ScreenClipWidget(
                                  profile: controller.activeProfile,
                                  orientation: controller.orientation,
                                  child: child,
                                ),
                              ),
                            ),
                          ),

                          // Floating toolbar — bottom-center with a small margin,
                          // overlapping the bottom edge of the device content.
                          if (controller.toolbarVisible)
                            Positioned(
                              bottom: 8.0,
                              left: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: PreviewToolbar(controller: controller),
                              ),
                            ),

                          // Device picker — covers the full overlay when open.
                          if (controller.devicePickerVisible)
                            Positioned.fill(
                              child: DevicePicker(controller: controller),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
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
