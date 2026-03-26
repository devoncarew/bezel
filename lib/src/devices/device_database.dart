import 'package:flutter/painting.dart' show EdgeInsets, Size;

import 'device_profile.dart';
import 'screen_cutout.dart';

/// The curated list of supported device profiles.
///
/// Values are approximate logical-pixel figures sourced from manufacturer
/// specifications. Treat them as representative rather than exact — the goal
/// is "few layout surprises before on-device testing", not pixel-perfect
/// accuracy.
const List<DeviceProfile> kDeviceProfiles = [
  // ── iOS ─────────────────────────────────────────────────────────────────
  DeviceProfile(
    id: 'iphone_se_3',
    name: 'iPhone SE (3rd gen)',
    platform: DevicePlatform.iOS,
    logicalSize: Size(375, 667),
    devicePixelRatio: 2.0,
    safeAreaPortrait: EdgeInsets.only(top: 20),
    safeAreaLandscape: EdgeInsets.zero,
    screenCornerRadius: 0, // flat-cornered display behind large bezels
    cutout: NoCutout(),
  ),

  DeviceProfile(
    id: 'iphone_15',
    name: 'iPhone 15',
    platform: DevicePlatform.iOS,
    logicalSize: Size(393, 852),
    devicePixelRatio: 3.0,
    safeAreaPortrait: EdgeInsets.only(top: 59, bottom: 34),
    safeAreaLandscape: EdgeInsets.only(left: 59, right: 59, bottom: 21),
    screenCornerRadius: 47, // community measurement; to be refined in step 4.6
    cutout: DynamicIslandCutout(size: Size(37, 12), topOffset: 14),
  ),

  DeviceProfile(
    id: 'iphone_15_pro',
    name: 'iPhone 15 Pro',
    platform: DevicePlatform.iOS,
    logicalSize: Size(393, 852),
    devicePixelRatio: 3.0,
    safeAreaPortrait: EdgeInsets.only(top: 59, bottom: 34),
    safeAreaLandscape: EdgeInsets.only(left: 59, right: 59, bottom: 21),
    screenCornerRadius: 47, // community measurement; to be refined in step 4.6
    cutout: DynamicIslandCutout(size: Size(37, 12), topOffset: 14),
  ),

  DeviceProfile(
    id: 'iphone_15_pro_max',
    name: 'iPhone 15 Pro Max',
    platform: DevicePlatform.iOS,
    logicalSize: Size(430, 932),
    devicePixelRatio: 3.0,
    safeAreaPortrait: EdgeInsets.only(top: 59, bottom: 34),
    safeAreaLandscape: EdgeInsets.only(left: 59, right: 59, bottom: 21),
    screenCornerRadius: 47, // community measurement; to be refined in step 4.6
    cutout: DynamicIslandCutout(size: Size(37, 12), topOffset: 14),
  ),

  DeviceProfile(
    id: 'ipad_10',
    name: 'iPad (10th gen)',
    platform: DevicePlatform.iOS,
    logicalSize: Size(820, 1180),
    devicePixelRatio: 2.0,
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 20),
    safeAreaLandscape: EdgeInsets.only(top: 20, bottom: 20),
    screenCornerRadius: 0, // flat-cornered display behind large bezels
    cutout: NoCutout(),
  ),

  DeviceProfile(
    id: 'ipad_mini_6',
    name: 'iPad mini (6th gen)',
    platform: DevicePlatform.iOS,
    logicalSize: Size(744, 1133),
    devicePixelRatio: 2.0,
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 20),
    safeAreaLandscape: EdgeInsets.only(top: 20, bottom: 20),
    screenCornerRadius: 0, // flat-cornered display behind large bezels
    cutout: NoCutout(),
  ),

  // ── Android ──────────────────────────────────────────────────────────────
  DeviceProfile(
    id: 'samsung_galaxy_s24',
    name: 'Samsung Galaxy S24',
    platform: DevicePlatform.android,
    logicalSize: Size(360, 780),
    devicePixelRatio: 2.625,
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(bottom: 24),
    screenCornerRadius:
        26, // community approximation; Samsung config is proprietary
    cutout: PunchHoleCutout(diameter: 10, topOffset: 12),
  ),

  DeviceProfile(
    id: 'pixel_7a',
    name: 'Google Pixel 7a',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 914),
    devicePixelRatio: 2.625,
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(bottom: 24),
    screenCornerRadius: 22, // approximate; to be refined from AOSP in step 4.6
    cutout: PunchHoleCutout(diameter: 11, topOffset: 13),
  ),

  DeviceProfile(
    id: 'pixel_8',
    name: 'Google Pixel 8',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 914),
    devicePixelRatio: 2.625,
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(bottom: 24),
    screenCornerRadius: 25, // approximate; to be refined from AOSP in step 4.6
    cutout: PunchHoleCutout(diameter: 11, topOffset: 13),
  ),

  DeviceProfile(
    id: 'pixel_8_pro',
    name: 'Google Pixel 8 Pro',
    platform: DevicePlatform.android,
    logicalSize: Size(448, 998),
    devicePixelRatio: 3.0,
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(bottom: 24),
    screenCornerRadius: 25, // approximate; to be refined from AOSP in step 4.6
    cutout: PunchHoleCutout(diameter: 11, topOffset: 13),
  ),
];

/// Provides access to the built-in device profile catalog.
abstract final class DeviceDatabase {
  /// All supported device profiles.
  static List<DeviceProfile> get all => kDeviceProfiles;

  /// Profiles filtered to [platform].
  static List<DeviceProfile> forPlatform(DevicePlatform platform) =>
      kDeviceProfiles.where((p) => p.platform == platform).toList();

  /// Returns the profile with [id], or `null` if not found.
  static DeviceProfile? findById(String id) {
    for (final profile in kDeviceProfiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  /// The default profile used when no selection has been made.
  static DeviceProfile get defaultProfile => findById('iphone_15')!;
}
