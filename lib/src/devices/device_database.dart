import 'package:flutter/painting.dart' show EdgeInsets, Size;

import 'device_profile.dart';
import 'screen_cutout.dart';

/// The curated list of supported device profiles.
///
/// **iOS geometry** is sourced from community measurements — Apple does not
/// publish machine-readable cutout geometry. Safe-area insets are from
/// useyourloaf.com; Dynamic Island dimensions and corner radii are
/// design-community approximations cross-referenced with iosresolution.com.
///
/// **Android (Pixel) geometry** is converted from AOSP device-tree XML:
///   `device/google/<codename>/overlay/.../config.xml`
/// `config_mainBuiltInDisplayCutout` gives the cutout shape in physical pixels;
/// `config_mainDisplayShape` gives the screen outline. Divide physical
/// coordinates by the device's DPR to get logical (dp) values.
///
/// **Android (Samsung) geometry** uses community approximations; Samsung does
/// not publish device-tree cutout configs.
const List<DeviceProfile> kDeviceProfiles = [
  // ── iOS ─────────────────────────────────────────────────────────────────

  // iPhone SE (3rd gen): traditional 4.7" LCD with large bezels; no cutout
  // and a flat-edged display — screenCornerRadius 0 is intentional.
  // Safe-area: status bar 20pt (no home indicator; hardware home button).
  // Source: iosresolution.com, useyourloaf.com
  DeviceProfile(
    id: 'iphone_se_3',
    name: 'iPhone SE (3rd gen)',
    platform: DevicePlatform.iOS,
    logicalSize: Size(375, 667),
    safeAreaPortrait: EdgeInsets.only(top: 20),
    safeAreaLandscape: EdgeInsets.zero,
    screenCornerRadius: 0,
    cutout: NoCutout(),
  ),

  // iPhone 15: 6.1" Super Retina XDR, Dynamic Island.
  // Corner radius: ~44pt (community measurement; Apple HIG Figma kit).
  // Dynamic Island: ~126×37pt pill, ~11pt from screen top
  //   (community measurement; hardware cutout, not the expanded software UI).
  // Safe-area: useyourloaf.com iPhone 15 Screen Sizes
  DeviceProfile(
    id: 'iphone_15',
    name: 'iPhone 15',
    platform: DevicePlatform.iOS,
    logicalSize: Size(393, 852),
    safeAreaPortrait: EdgeInsets.only(top: 59, bottom: 34),
    safeAreaLandscape: EdgeInsets.only(left: 59, right: 59, bottom: 21),
    screenCornerRadius: 44,
    cutout: DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  ),

  // iPhone 15 Pro: same screen size as iPhone 15, Pro chassis.
  // Geometry identical to iPhone 15 — same DI hardware cutout.
  // Source: useyourloaf.com, iosresolution.com
  DeviceProfile(
    id: 'iphone_15_pro',
    name: 'iPhone 15 Pro',
    platform: DevicePlatform.iOS,
    logicalSize: Size(393, 852),
    safeAreaPortrait: EdgeInsets.only(top: 59, bottom: 34),
    safeAreaLandscape: EdgeInsets.only(left: 59, right: 59, bottom: 21),
    screenCornerRadius: 44,
    cutout: DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  ),

  // iPhone 15 Pro Max: 6.7" variant; same DI cutout geometry.
  // Corner radius: ~44pt (same family as 15/15 Pro; community measurement).
  // Source: useyourloaf.com, iosresolution.com
  DeviceProfile(
    id: 'iphone_15_pro_max',
    name: 'iPhone 15 Pro Max',
    platform: DevicePlatform.iOS,
    logicalSize: Size(430, 932),
    safeAreaPortrait: EdgeInsets.only(top: 59, bottom: 34),
    safeAreaLandscape: EdgeInsets.only(left: 59, right: 59, bottom: 21),
    screenCornerRadius: 44,
    cutout: DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  ),

  // iPad (10th gen): thin-bezel design; rounded display corners visible.
  // Corner radius: ~18pt (community approximation).
  // No camera cutout — front camera sits in the top bezel.
  // Source: iosresolution.com, useyourloaf.com
  DeviceProfile(
    id: 'ipad_10',
    name: 'iPad (10th gen)',
    platform: DevicePlatform.iOS,
    logicalSize: Size(820, 1180),
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 20),
    safeAreaLandscape: EdgeInsets.only(top: 20, bottom: 20),
    screenCornerRadius: 18,
    cutout: NoCutout(),
  ),

  // iPad mini (6th gen): compact form factor with thin bezels.
  // Corner radius: ~18pt (community approximation; same family as iPad 10).
  // No camera cutout — front camera in the top bezel.
  // Source: iosresolution.com, useyourloaf.com
  DeviceProfile(
    id: 'ipad_mini_6',
    name: 'iPad mini (6th gen)',
    platform: DevicePlatform.iOS,
    logicalSize: Size(744, 1133),
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 20),
    safeAreaLandscape: EdgeInsets.only(top: 20, bottom: 20),
    screenCornerRadius: 18,
    cutout: NoCutout(),
  ),

  // ── Android ──────────────────────────────────────────────────────────────

  // Samsung Galaxy A15 (4G, SM-A155F, released Dec 2023): community
  // approximation — Samsung does not publish device-tree cutout configs.
  // Physical: 1080×2340px, ~396 PPI. Runtime density: ~420 dpi (2.625 DPR),
  //   inferred from Samsung One UI convention for this resolution class.
  //   Logical size: 1080/2.625 × 2340/2.625 ≈ 411×892dp.
  // Display type: Infinity-U (teardrop/waterdrop notch) — NOT a punch-hole.
  //   No measured source found; approximate values based on Samsung A-series
  //   Infinity-U design language.
  //   Notch size: ~54×32dp. Notch topOffset: 0 (flush with screen top edge).
  // Corner radius: ~20dp (budget-tier approximation; no measured source).
  // Safe area portrait: status bar matches notch height ≈ 32dp.
  // Safe area landscape: notch rotates to left edge; left ≈ 32dp.
  DeviceProfile(
    id: 'samsung_galaxy_a15',
    name: 'Samsung Galaxy A15',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 892),
    safeAreaPortrait: EdgeInsets.only(top: 32, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 32, bottom: 24),
    screenCornerRadius: 20, // community approximation
    cutout: NotchCutout(size: Size(54, 32)),
  ),

  // Samsung Galaxy S24: community approximation — Samsung does not publish
  // device-tree cutout geometry (config is proprietary).
  // Corner radius: ~26pt (community measurement).
  // Punch hole: ~10pt diameter, centered, ~12pt from screen top (center Y).
  DeviceProfile(
    id: 'samsung_galaxy_s24',
    name: 'Samsung Galaxy S24',
    platform: DevicePlatform.android,
    logicalSize: Size(360, 780),
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(bottom: 24),
    screenCornerRadius: 26, // community approximation
    cutout: PunchHoleCutout(diameter: 10, topOffset: 12),
  ),

  // Pixel 8a (codename: akita).
  // Cutout: AOSP config_mainBuiltInDisplayCutout, akita device tree.
  //   m 573.22,68.71 a 33.72,33.72 0 0 0 -67.43,0 ... Z @left
  //   Circle: center (539.5, 68.71)px physical, radius 33.72px physical.
  //   Diameter: 67.44px / 2.625 ≈ 26dp. Center Y: 68.71px / 2.625 ≈ 26dp.
  // Corner radius: AOSP config_mainDisplayShape, akita:
  //   M 96.5,0.09 ... — path starts at x=96.5 on top edge (= corner radius).
  //   96.5px / 2.625 ≈ 37dp.
  // Safe area portrait: AOSP config_mainBuiltInDisplayCutoutRectApproximation,
  //   akita: m 485.5,0 h 110 v 121 h -110 Z → height 121px / 2.625 ≈ 46dp.
  // Safe area landscape: punch hole rotates to left edge;
  //   left = topOffset + diameter = 26 + 26 = 52dp.
  DeviceProfile(
    id: 'pixel_8a',
    name: 'Google Pixel 8a',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 914),
    safeAreaPortrait: EdgeInsets.only(top: 46, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 52, bottom: 24),
    screenCornerRadius: 37,
    cutout: PunchHoleCutout(diameter: 26, topOffset: 26),
  ),

  // Pixel 8 (codename: shiba).
  // Cutout: AOSP config_mainBuiltInDisplayCutout, shiba device tree.
  //   Circle ~28px physical diameter, center ~34px from screen top.
  //   28px / 2.625 DPR ≈ 11dp diameter; 34px / 2.625 ≈ 13dp center Y.
  // Corner radius: ~25pt (AOSP config_mainDisplayShape, shiba;
  //   physical arc ~65px / DPR 2.625 ≈ 25dp).
  // Safe area portrait: cutout bottom = 13 + 5.5 = 18.5dp < 24dp status bar.
  // Safe area landscape: left = edgeOffset + diameter = 13 + 11 = 24dp.
  DeviceProfile(
    id: 'pixel_8',
    name: 'Google Pixel 8',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 914),
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 24, bottom: 24),
    screenCornerRadius: 25,
    cutout: PunchHoleCutout(diameter: 11, topOffset: 13),
  ),

  // Pixel 9 (codename: tokay, in caimito repo).
  // Cutout: AOSP config_mainBuiltInDisplayCutout, caimito/tokay device tree.
  //   m 581.5,86.5 a 42,42 0 0 0 -84,0 42,42 0 0 0 84,0 z @left
  //   Circle: center (539.5, 86.5)px physical, radius 42px physical.
  //   Diameter: 84px / 2.625 = 32dp. Center Y: 86.5px / 2.625 ≈ 33dp.
  // Corner radius: AOSP config_mainDisplayShape, tokay:
  //   M 886.188,0.022 ... — path starts 193.8px from right edge on top.
  //   193.8px / 2.625 ≈ 74dp.
  // Safe area portrait: AOSP config_mainBuiltInDisplayCutoutRectApproximation,
  //   tokay: m 484.5,0 h 110 v 173 h -110 z → height 173px / 2.625 ≈ 66dp.
  // Safe area landscape: punch hole rotates to left edge;
  //   left = topOffset + diameter = 33 + 32 = 65dp.
  DeviceProfile(
    id: 'pixel_9',
    name: 'Google Pixel 9',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 923),
    safeAreaPortrait: EdgeInsets.only(top: 66, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 65, bottom: 24),
    screenCornerRadius: 74,
    cutout: PunchHoleCutout(diameter: 32, topOffset: 33),
  ),

  // Pixel 10 (codename: frankel, in muzel repo).
  // Panel geometry is identical to the Pixel 9 (same 1080×2424px display).
  // Cutout: TensorG5-devs/device_google_muzel, frankel overlay.
  //   m 581.5,86 a 42,42 0 0 0 -84,0 42,42 0 0 0 84,0 z @left
  //   Circle: center (539.5, 86)px physical, radius 42px physical.
  //   Diameter: 84px / 2.625 = 32dp. Center Y: 86px / 2.625 ≈ 33dp.
  // Corner radius: same panel as Pixel 9 → 74dp.
  // Safe area portrait: same bounding box as Pixel 9 → 66dp.
  // Safe area landscape: left = topOffset + diameter = 33 + 32 = 65dp.
  // Note: Google has not published Pixel 10 device trees to AOSP; data sourced
  //   from the community-maintained TensorG5-devs/device_google_muzel repo.
  DeviceProfile(
    id: 'pixel_10',
    name: 'Google Pixel 10',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 923),
    safeAreaPortrait: EdgeInsets.only(top: 66, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 65, bottom: 24),
    screenCornerRadius: 74,
    cutout: PunchHoleCutout(diameter: 32, topOffset: 33),
  ),

  // Pixel 10 Pro (codename: blazer, in muzel repo).
  // Cutout: TensorG5-devs/device_google_muzel, blazer overlay.
  //   m 689,102 a 49,49 0 0 0 -98,0 49,49 0 0 0 98,0 z @left
  //   Circle: center (640, 102)px physical, radius 49px. Centered on 1280px
  //   display. Diameter: 98px / 3.125 ≈ 31dp. Center Y: 102px / 3.125 ≈ 33dp.
  // Corner radius: path starts at (0.003, 226.705) on left edge →
  //   226.705px / 3.125 ≈ 73dp.
  // Safe area portrait: AOSP config_mainBuiltInDisplayCutoutRectApproximation,
  //   blazer: m 586,0 h 108.5 v 204 h -108.5 Z → height 204px / 3.125 ≈ 65dp.
  // Safe area landscape: left = topOffset + diameter = 33 + 31 = 64dp.
  // Note: DPR is 3.125 (density 500 = 500/160) set via vendor proprietary
  //   config; AOSP TARGET_SCREEN_DENSITY says 480 but runtime value is 500.
  //   Data from TensorG5-devs/device_google_muzel (not yet in AOSP).
  DeviceProfile(
    id: 'pixel_10_pro',
    name: 'Google Pixel 10 Pro',
    platform: DevicePlatform.android,
    logicalSize: Size(410, 914),
    safeAreaPortrait: EdgeInsets.only(top: 65, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 64, bottom: 24),
    screenCornerRadius: 73,
    cutout: PunchHoleCutout(diameter: 31, topOffset: 33),
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
  // todo: Switch back to an iphone device.
  // static DeviceProfile get defaultProfile => findById('iphone_15')!;
  static DeviceProfile get defaultProfile => findById('pixel_8a')!;
}
