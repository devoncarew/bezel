import 'dart:math' as math;

import 'package:flutter/material.dart' show Theme, ThemeData, Brightness;
import 'package:flutter/widgets.dart';

import '../devices/screen_border.dart';
import '../frame/screen_clip_widget.dart';
import '../preview_controller.dart';
import '../theme.dart';
import 'common.dart';
import 'device_picker.dart';
import 'preview_shortcuts.dart';
import 'preview_toolbar.dart';

/// Wraps the app in a device-frame preview UI.
///
/// Layout (top to bottom):
///   [kPreviewPadding] — [device area, kPreviewPadding left/right] —
///   [kPreviewPadding] — [toolbar] — [kPreviewPadding]
///
/// [ListenableBuilder] rebuilds on [PreviewController] changes. The device
/// area uses an inner [LayoutBuilder] so [computeScale] operates on the actual
/// available device space (already accounting for padding) rather than the
/// full window size.
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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.passthroughMode) {
          return child;
        }

        // Directionality + Theme are provided here because the overlay
        // sits above the user's MaterialApp and has no such ancestors.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: ThemeData(brightness: Brightness.dark),
            child: PreviewShortcuts(
              controller: controller,
              child: ColoredBox(
                color: kPreviewBackground,
                child: Stack(
                  children: [
                    // Main column: padding → device area → padding →
                    // toolbar → padding.
                    Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final emulated = controller.emulatedLogicalSize;
                              final scale = computeScale(
                                constraints.biggest,
                                emulated,
                              );
                              return Center(
                                child: RaisedSurface(
                                  borderRadius: BorderRadius.circular(
                                    _cornerRadiusValue(
                                      controller.activeProfile.screenBorder,
                                    ),
                                  ),
                                  height: 6,
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
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: kPreviewSpacing),

                        SizedBox(
                          height: kToolbarHeight,
                          child: Align(
                            alignment: Alignment.center,
                            child: PreviewToolbar(controller: controller),
                          ),
                        ),

                        const SizedBox(height: kPreviewPadding),
                      ],
                    ),

                    // Backdrop + picker — always mounted so the picker
                    // can animate in and out. The backdrop covers the full
                    // window (including toolbar) so all taps outside the
                    // card dismiss the picker.
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

double _cornerRadiusValue(ScreenBorder border) {
  return switch (border) {
    CircularBorder(:final radius) => radius,
    // Use topTangentLength as an approximation for the outer shadow radius on
    // the RaisedSurface — close enough for the cosmetic drop shadow.
    SquircleBorder(:final topTangentLength) => topTangentLength,
  };
}
