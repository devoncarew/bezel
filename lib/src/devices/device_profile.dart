import 'package:flutter/painting.dart' show EdgeInsets, Size;

import 'screen_cutout.dart';

/// The host platform of a device.
enum DevicePlatform {
  /// Apple iOS device.
  iOS,

  /// Android device.
  android,
}

/// The visual style of the device frame, driven by the camera cutout design.
enum DeviceFrameStyle {
  /// Wide notch at the top — older iPhones (X–14).
  notch,

  /// Dynamic Island pill — iPhone 15 and later.
  dynamicIsland,

  /// Small circular punch-hole — Pixel, Galaxy S series.
  punchHole,

  /// Full bezels with no cutout — iPhone SE, iPads.
  classic,
}

/// Screen orientation.
enum DeviceOrientation {
  /// Taller than wide.
  portrait,

  /// Wider than tall.
  landscape,
}

/// Describes the screen geometry and visual characteristics of a mobile device.
///
/// All size and inset values are in **logical pixels** for portrait orientation.
/// Use [logicalSizeForOrientation], [safeAreaForOrientation], and
/// [cutoutForOrientation] to retrieve values for a specific orientation.
class DeviceProfile {
  /// Unique stable identifier, e.g. `'iphone_15'`.
  final String id;

  /// Human-readable display name, e.g. `'iPhone 15'`.
  final String name;

  /// Host platform.
  final DevicePlatform platform;

  /// Logical screen size in **portrait** orientation.
  final Size logicalSize;

  /// Physical pixels per logical pixel.
  final double devicePixelRatio;

  /// Safe area insets in portrait orientation.
  final EdgeInsets safeAreaPortrait;

  /// Safe area insets in landscape orientation.
  final EdgeInsets safeAreaLandscape;

  /// Visual frame style used by [DeviceFramePainter].
  final DeviceFrameStyle frameStyle;

  /// Camera cutout geometry in portrait orientation.
  final ScreenCutout cutout;

  const DeviceProfile({
    required this.id,
    required this.name,
    required this.platform,
    required this.logicalSize,
    required this.devicePixelRatio,
    required this.safeAreaPortrait,
    required this.safeAreaLandscape,
    required this.frameStyle,
    required this.cutout,
  });

  /// Returns the logical screen size for [orientation].
  ///
  /// Portrait returns [logicalSize] unchanged; landscape swaps width and height.
  Size logicalSizeForOrientation(DeviceOrientation orientation) {
    return switch (orientation) {
      DeviceOrientation.portrait => logicalSize,
      DeviceOrientation.landscape => Size(
        logicalSize.height,
        logicalSize.width,
      ),
    };
  }

  /// Returns the safe area insets for [orientation].
  EdgeInsets safeAreaForOrientation(DeviceOrientation orientation) {
    return switch (orientation) {
      DeviceOrientation.portrait => safeAreaPortrait,
      DeviceOrientation.landscape => safeAreaLandscape,
    };
  }

  /// Returns the cutout geometry for [orientation].
  ///
  /// Portrait returns [cutout] unchanged; landscape calls
  /// [ScreenCutout.rotatedForLandscape] with [logicalSize].
  ScreenCutout cutoutForOrientation(DeviceOrientation orientation) {
    return switch (orientation) {
      DeviceOrientation.portrait => cutout,
      DeviceOrientation.landscape => cutout.rotatedForLandscape(logicalSize),
    };
  }
}
