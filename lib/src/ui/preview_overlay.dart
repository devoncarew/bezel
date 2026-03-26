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

/// Height reserved at the bottom of the window for the floating toolbar.
///
/// Must stay in sync with `_kToolbarAreaHeight` in
/// `window_manager_sizing_service.dart`.
const double _kToolbarAreaHeight = 40.0;

/// Wraps the app in a device-frame preview UI.
///
/// Uses [LayoutBuilder] + [ListenableBuilder] to react to both window-size
/// changes and [PreviewController] state changes. Scales the [ScreenClipWidget]
/// to fill the content area (available space minus the toolbar strip at the
/// bottom), letterboxing with the background colour on whichever axis has
/// leftover space.
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
              // Reserve the bottom strip for the toolbar; scale content to fill
              // the remaining area.
              final contentArea = Size(
                available.width,
                (available.height - _kToolbarAreaHeight).clamp(
                  1.0,
                  double.infinity,
                ),
              );
              final scale = computeScale(contentArea, emulated);

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
                          // Content area: fills window above the toolbar strip.
                          // Device frame is centered and letterboxed within it.
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: _kToolbarAreaHeight,
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

                          // Floating toolbar — bottom-center with a small margin.
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

  /// Computes the uniform scale factor to fit [emulated] inside [contentArea].
  ///
  /// Returns the largest scale ≤ 1.0 such that the scaled emulated size fits
  /// within [contentArea]. Returns 1.0 when the emulated size already fits.
  static double computeScale(Size contentArea, Size emulated) {
    return math
        .min(
          contentArea.width / emulated.width,
          contentArea.height / emulated.height,
        )
        .clamp(0.0, 1.0);
  }
}
