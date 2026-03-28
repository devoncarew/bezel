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
    verified: true,
    description: 'Flat-edge, no cutout, small screen — budget / upgrade path',
  ),

  // iPhone 14: 6.1" Super Retina XDR, traditional notch.
  // PLACEHOLDER — geometry not yet verified; specs to be filled in.
  DeviceProfile(
    id: 'iphone_14',
    name: 'iPhone 14',
    platform: DevicePlatform.iOS,
    logicalSize: Size(390, 844),
    safeAreaPortrait: EdgeInsets.only(top: 47, bottom: 34),
    safeAreaLandscape: EdgeInsets.only(left: 47, bottom: 21),
    screenCornerRadius: 44,
    cutout: NoCutout(), // TODO: replace with NotchCutout once implemented
    verified: false,
    description: 'Notch cutout, 390 × 844 — covers iPhone 12, 13, 14',
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
    safeAreaLandscape: EdgeInsets.only(left: 59, bottom: 20),
    screenCornerRadius: 44,
    cutout: DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
    verified: true,
    description:
        'Dynamic Island, 393 × 852 — covers iPhone 14 Pro, 15 Pro, 16, 16e',
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
    safeAreaLandscape: EdgeInsets.only(left: 59, bottom: 20),
    screenCornerRadius: 44,
    cutout: DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
    verified: true,
    description: 'Identical geometry to iPhone 15 — proxy for 14 Pro, 16',
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
    safeAreaLandscape: EdgeInsets.only(left: 59, bottom: 20),
    screenCornerRadius: 44,
    cutout: DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
    verified: true,
    description: 'Dynamic Island, 430 × 932 — covers iPhone 15 Plus, 16 Plus',
  ),

  // iPhone 16 Pro Max: 6.9" display, largest screen Apple has shipped.
  // PLACEHOLDER — geometry not yet verified; specs to be filled in.
  DeviceProfile(
    id: 'iphone_16_pro_max',
    name: 'iPhone 16 Pro Max',
    platform: DevicePlatform.iOS,
    logicalSize: Size(440, 956),
    safeAreaPortrait: EdgeInsets.only(top: 62, bottom: 34),
    safeAreaLandscape: EdgeInsets.only(left: 62, bottom: 20),
    screenCornerRadius: 44,
    cutout: DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
    verified: false,
    description:
        'Largest iPhone screen, 440 × 956 — exposes wide-layout edge cases',
  ),

  // iPad mini (A17 Pro): compact form factor with thin bezels.
  // Corner radius: ~18pt (community approximation; same family as iPad 10th
  // gen).
  // No camera cutout — front camera in the top bezel.
  // Source: iosresolution.com, useyourloaf.com
  DeviceProfile(
    id: 'ipad_mini_a17',
    name: 'iPad mini (A17 Pro)',
    platform: DevicePlatform.iOS,
    logicalSize: Size(744, 1133),
    safeAreaPortrait: EdgeInsets.only(top: 32, bottom: 20),
    safeAreaLandscape: EdgeInsets.only(top: 32, bottom: 20),
    screenCornerRadius: 18,
    cutout: NoCutout(),
    verified: true,
    tablet: true,
    description: 'Compact iPad, 744 × 1133',
  ),

  // iPad (A16): thin-bezel design; rounded display corners visible.
  // Corner radius: ~18pt (community approximation).
  // No camera cutout — front camera sits in the top bezel.
  // Source: iosresolution.com, useyourloaf.com
  DeviceProfile(
    id: 'ipad_a16',
    name: 'iPad (A16)',
    platform: DevicePlatform.iOS,
    logicalSize: Size(820, 1180),
    safeAreaPortrait: EdgeInsets.only(top: 32, bottom: 20),
    safeAreaLandscape: EdgeInsets.only(top: 32, bottom: 20),
    screenCornerRadius: 18,
    cutout: NoCutout(),
    verified: true,
    tablet: true,
    description: 'Standard iPad, 820 × 1180',
  ),

  // ── Android ──────────────────────────────────────────────────────────────

  // Samsung Galaxy A15 (4G, SM-A155F, released Dec 2023): community
  // approximation — Samsung does not publish device-tree cutout configs.
  // Physical: 1080×2340px, ~396 PPI. Runtime density: ~420 dpi (2.625 DPR),
  //   inferred from Samsung One UI convention for this resolution class.
  //   Logical size: 1080/2.625 × 2340/2.625 ≈ 411×892dp.
  // Display type: Infinity-U (teardrop/waterdrop notch). The camera sits in
  //   the circular bottom of the teardrop; concave "ear" arcs (sideRadius)
  //   connect the notch sides to the screen top edge.
  //   Dimensions measured from Android Emulator skin PNG via tool/measure_device.py.
  //   Width: ~44dp (straight-side width, 25% depth). Height: ~31dp. SideRadius: ~7dp.
  //   Total ear-to-ear width at screen edge: ~58dp.
  // Corner radius: ~42dp (measured from skin PNG via tool/measure_device.py).
  // Safe area portrait: status bar 32dp covers the full notch height.
  // Safe area landscape: teardrop rotates to left edge; left ≈ 32dp.
  DeviceProfile(
    id: 'samsung_galaxy_a15',
    name: 'Samsung Galaxy A15',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 892),
    safeAreaPortrait: EdgeInsets.only(top: 32, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 32, bottom: 24),
    screenCornerRadius: 42, // measured from skin PNG
    cutout: TeardropCutout(width: 44, height: 31, sideRadius: 13),
    verified: true,
    description: 'Budget Samsung Infinity-U notch, 411 × 892 — covers A15, A25',
  ),

  // Samsung Galaxy A55 (mid-range): PLACEHOLDER — geometry not yet verified.
  // Approximate logical size from community sources; specs to be filled in.
  DeviceProfile(
    id: 'samsung_galaxy_a55',
    name: 'Samsung Galaxy A55',
    platform: DevicePlatform.android,
    logicalSize: Size(384, 854),
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(bottom: 24),
    screenCornerRadius: 36,
    cutout: PunchHoleCutout(diameter: 10, topOffset: 12),
    verified: false,
    description: 'Mid-range Samsung A-series, ~384 × 854 — covers A54, A55',
  ),

  // Samsung Galaxy S24: Samsung does not publish device-tree cutout geometry.
  // Corner radius: 108.3px / 3.0 DPR ≈ 36dp (measured from skin PNG via
  //   tool/measure_device.py; skin PNG is 1080×2340px at native resolution).
  // Punch hole: ~10pt diameter, centered, ~12pt from screen top (center Y).
  //   Punch holes are transparent in device-skin images and cannot be measured
  //   by the tool; value retained from community approximation.
  DeviceProfile(
    id: 'samsung_galaxy_s24',
    name: 'Samsung Galaxy S24',
    platform: DevicePlatform.android,
    logicalSize: Size(360, 780),
    safeAreaPortrait: EdgeInsets.only(top: 24, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(bottom: 24),
    screenCornerRadius: 36, // measured from skin PNG
    cutout: PunchHoleCutout(diameter: 10, topOffset: 12),
    verified: true,
    description: 'Flagship Samsung, 360 × 780 — covers S23, S24',
  ),

  // Pixel 7a (codename: lynx).
  // Cutout: verified against Android Emulator via `adb shell dumpsys display`.
  //   Cutout spec: M 507,66 a 33,33 0 1 0 66,0 33,33 0 1 0 -66,0 Z @left
  //   Circle: center (540, 66)px physical, radius 33px physical.
  //   Diameter: 66px / 2.625 DPR ≈ 25dp; center Y: 66px / 2.625 ≈ 25dp.
  // Corner radius: 47px / 2.625 ≈ 18dp (from roundedCorners in dumpsys output).
  // Safe areas: verified against Android Emulator.
  DeviceProfile(
    id: 'pixel_7a',
    name: 'Google Pixel 7a',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 914),
    safeAreaPortrait: EdgeInsets.only(top: 45, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 45, top: 28, bottom: 24),
    screenCornerRadius: 18,
    cutout: PunchHoleCutout(diameter: 25, topOffset: 25),
    verified: true,
    description: 'Mid-range Pixel, small punch hole — covers Pixel 7a, 8a',
  ),

  // Pixel 10 (codename: frankel, in muzel repo).
  // Cutout: TensorG5-devs/device_google_muzel, frankel overlay.
  //   m 581.5,86 a 42,42 0 0 0 -84,0 42,42 0 0 0 84,0 z @left
  //   Circle: center (539.5, 86)px physical, radius 42px physical.
  //   Diameter: 84px / 2.625 = 32dp. Center Y: 86px / 2.625 ≈ 33dp.
  // Corner radius: same panel as Pixel 9 (AOSP config_mainDisplayShape, tokay:
  //   193.8px / 2.625 ≈ 74dp).
  // Safe area portrait: AOSP config_mainBuiltInDisplayCutoutRectApproximation,
  //   tokay: m 484.5,0 h 110 v 173 h -110 z → height 173px / 2.625 ≈ 66dp.
  // Safe area landscape: left = topOffset + diameter = 33 + 32 = 65dp.
  // Note: Google has not published Pixel 10 device trees to AOSP; data sourced
  //   from the community-maintained TensorG5-devs/device_google_muzel repo.
  //   Panel geometry is identical to the Pixel 9 (same 1080×2424px display).
  DeviceProfile(
    id: 'pixel_10',
    name: 'Google Pixel 10',
    platform: DevicePlatform.android,
    logicalSize: Size(411, 923),
    safeAreaPortrait: EdgeInsets.only(top: 66, bottom: 24),
    safeAreaLandscape: EdgeInsets.only(left: 65, bottom: 24),
    screenCornerRadius: 74,
    cutout: PunchHoleCutout(diameter: 32, topOffset: 33),
    verified: false,
    description: 'Large punch hole, 411 × 923 — covers Pixel 9 and 10',
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
    verified: false,
    description: 'High-DPR Pixel (3.125), 410 × 914',
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
