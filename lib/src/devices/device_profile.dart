import 'package:flutter/material.dart';

import 'screen_border.dart';
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
/// Use [logicalSizeForOrientation] and [safeAreaForOrientation] to retrieve
/// values for a specific orientation.
class DeviceProfile {
  /// Unique stable identifier, e.g. `'iphone_15'`.
  final String id;

  /// Human-readable display name, e.g. `'iPhone 15'`.
  final String name;

  /// Short display name for compact UI surfaces such as the control badge,
  /// e.g. `'Pixel 10'` instead of `'Google Pixel 10'`.
  ///
  /// Falls back to [name] when not provided.
  final String? shortName;

  /// Host platform.
  final DevicePlatform platform;

  /// Logical screen size in **portrait** orientation.
  final Size logicalSize;

  /// Safe area insets in portrait orientation.
  final EdgeInsets safeAreaPortrait;

  /// Safe area insets in landscape orientation.
  final EdgeInsets safeAreaLandscape;

  /// Screen corner shape used to clip the display to its true rounded outline.
  ///
  /// A [CircularBorder] with radius 0 means square corners (e.g. iPhone SE).
  /// All current profiles use [CircularBorder]; [SquircleBorder] will be added
  /// for iOS devices in Step 5.4 once Bézier control points are available.
  final ScreenBorder screenBorder;

  /// Camera cutout geometry in portrait orientation.
  final ScreenCutout cutout;

  /// Whether this device is a tablet.
  final bool tablet;

  /// Short description of what this profile covers; displayed in the device
  /// picker and included in generated documentation.
  ///
  /// Keep to one short sentence or a comma-separated phrase list. `null` means
  /// no additional context is shown.
  final String? description;

  DeviceProfile({
    required this.id,
    required this.name,
    this.shortName,
    required this.platform,
    required this.logicalSize,
    required this.safeAreaPortrait,
    required this.safeAreaLandscape,
    required this.screenBorder,
    required this.cutout,
    this.tablet = false,
    this.description,
  });

  IconData get icon {
    return switch (platform) {
      DevicePlatform.iOS => tablet ? Icons.tablet_mac : Icons.phone_iphone,
      DevicePlatform.android =>
        tablet ? Icons.tablet_android : Icons.phone_android,
    };
  }

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
}
