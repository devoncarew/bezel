import 'package:flutter/painting.dart' show EdgeInsets, Size;

import 'screen_cutout.dart';

/// The host platform of a device.
enum DevicePlatform {
  /// Apple iOS device.
  iOS('iOS'),

  /// Android device.
  android('Android');

  const DevicePlatform(this.label);

  final String label;
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

  /// Safe area insets in portrait orientation.
  final EdgeInsets safeAreaPortrait;

  /// Safe area insets in landscape orientation.
  final EdgeInsets safeAreaLandscape;

  /// Screen corner radius in logical pixels.
  ///
  /// Used to clip the device screen to its true rounded-corner shape so the
  /// preview background shows through where a real display's glass would end.
  /// A value of 0 means square corners (e.g. iPhone SE, iPads).
  final double screenCornerRadius;

  /// Camera cutout geometry in portrait orientation.
  final ScreenCutout cutout;

  /// TODO: Delete this once all devices are verified.
  final bool verified;

  /// Whether this device is a tablet.
  final bool tablet;

  /// Short description of what this profile covers; displayed in the device
  /// picker and included in generated documentation.
  ///
  /// Keep to one short sentence or a comma-separated phrase list. `null` means
  /// no additional context is shown.
  final String? description;

  const DeviceProfile({
    required this.id,
    required this.name,
    required this.platform,
    required this.logicalSize,
    required this.safeAreaPortrait,
    required this.safeAreaLandscape,
    required this.screenCornerRadius,
    required this.cutout,
    required this.verified,
    this.tablet = false,
    this.description,
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
