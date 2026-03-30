// ignore_for_file: non_constant_identifier_names

import 'package:flutter/painting.dart' show EdgeInsets, Size;

import 'device_profile.dart';
import 'screen_border.dart';
import 'screen_cutout.dart';

/// The curated list of supported device profiles.
///
/// **iOS geometry** is sourced from community measurements — Apple does not
/// publish machine-readable cutout geometry. Safe-area insets are from
/// useyourloaf.com; Dynamic Island dimensions and corner radii are
/// design-community approximations cross-referenced with iosresolution.com.
///
/// **iOS screen corner radii** use 44pt for all iPhones — a community
/// approximation verified visually against the iOS Simulator. Apple uses
/// squircle (continuous curvature) corners, not circular arcs. The iOS
/// Simulator framebuffer PDFs (see `tool/extract_simdevicetype.dart`) yield
/// larger values (53–69pt depending on model), but those measure the *squircle
/// tangent point*, not an equivalent circular-arc radius. Feeding them into an
/// RRect produces visually oversized corners. The correct fix is a proper
/// squircle path builder derived from the PDF Bézier data; until that work is
/// done, 44pt circular arcs remain the best-looking approximation.
///
/// **Android (Pixel) geometry** is converted from AOSP device-tree XML:
///   `device/google/<codename>/overlay/.../config.xml`
/// `config_mainBuiltInDisplayCutout` gives the cutout shape in physical pixels;
/// `config_mainDisplayShape` gives the screen outline. Divide physical
/// coordinates by the device's DPR to get logical (dp) values.
///
/// **Android (Samsung) geometry** uses community approximations; Samsung does
/// not publish device-tree cutout configs.
final List<DeviceProfile> kDeviceProfiles = [
  // iOS
  iphone_se_3,
  iphone_14,
  iphone_15,
  iphone_15_pro_max,
  iphone_17,
  iphone_17_air,
  iphone_17_pro,
  iphone_17_pro_max,

  // Android
  samsung_galaxy_a15,
  samsung_galaxy_a55,
  samsung_galaxy_s24,
  pixel_7a,
  pixel_10,
  pixel_10_pro,

  // Tablets
  ipad_mini_a17,
  ipad_a16,
];

// ── iOS ─────────────────────────────────────────────────────────────────

// iPhone SE (3rd gen): traditional 4.7" LCD with large bezels; no cutout
// and a flat-edged display — screenCornerRadius 0 is intentional.
// Safe-area: status bar 20pt (no home indicator; hardware home button).
// Source: iosresolution.com, useyourloaf.com
final iphone_se_3 = DeviceProfile(
  id: 'iphone_se_3',
  name: 'iPhone SE (3rd gen)',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(375, 667),
  safeAreaPortrait: const EdgeInsets.only(top: 20),
  safeAreaLandscape: EdgeInsets.zero,
  screenBorder: const CircularBorder(0),
  cutout: const NoCutout(),
  description: 'Flat-edge, no cutout, small screen — budget / upgrade path',
);

// iPhone 14: 6.1" Super Retina XDR, traditional notch (same as iPhone X–13).
// Corner border: 6-segment squircle Bézier from the Simulator framebuffer PDF
// (Xcode 16, "iPhone 14", 1170×2532 px, 3× scale).
//   Top tangent: 390 − 322.54 = 67.46 pt. Side tangent: 67.47 pt.
// Cutout: PathCutout from the Simulator sensor bar PDF (Xcode 16, "iPhone 14",
//   sensor_bar_class_03, MediaBox 176×34 pt, logical points).
// Safe area portrait: status bar 47pt covers the full notch depth.
// Safe area landscape: notch rotates to left edge; left = 47pt.
final iphone_14 = DeviceProfile(
  id: 'iphone_14',
  name: 'iPhone 14',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(390, 844),
  safeAreaPortrait: const EdgeInsets.only(top: 47, bottom: 34),
  safeAreaLandscape: const EdgeInsets.only(left: 47, bottom: 20),
  screenBorder: const SquircleBorder(
    topTangentLength: 67.46,
    // Segments are relative to the top-right corner (390, 0). Each row is one
    // cubic: cp1x, cp1y, cp2x, cp2y, x, y.
    segments: [
      [-63.04, 0.00, -57.60, 0.02, -53.22, 0.16],
      [-48.49, 0.32, -43.71, 0.65, -39.03, 1.48],
      [-29.42, 3.18, -20.81, 6.90, -13.85, 13.85],
      [-6.89, 20.81, -3.17, 29.43, -1.48, 39.03],
      [-0.65, 43.71, -0.31, 48.50, -0.16, 53.22],
      [-0.01, 57.60, 0.00, 63.04, 0.00, 67.47],
    ],
  ),
  cutout: PathCutout(
    mediaBoxWidth: 176,
    mediaBoxHeight: 34,
    // PDF ops from sensor_bar_class_03 (y=0 at bottom, y increases upward).
    // Traces the notch outline clockwise from the right ear to the left ear.
    ops: [
      PathOp.moveTo(175.558, 34.002),
      PathOp.curveTo(174.912, 33.993, 174.242, 33.955, 173.539, 33.825),
      PathOp.curveTo(172.386, 33.609, 171.392, 33.171, 170.622, 32.416),
      PathOp.curveTo(169.851, 31.662, 169.389, 30.680, 169.149, 29.534),
      PathOp.curveTo(168.897, 28.348, 168.918, 27.255, 168.884, 26.198),
      PathOp.curveTo(168.810, 23.833, 168.780, 21.618, 168.388, 19.170),
      PathOp.curveTo(168.009, 16.810, 167.342, 14.656, 166.277, 12.571),
      PathOp.curveTo(164.990, 10.057, 163.169, 7.758, 160.972, 5.862),
      PathOp.curveTo(158.714, 3.915, 156.171, 2.481, 153.416, 1.595),
      PathOp.curveTo(148.911, 0.145, 144.431, 0.328, 139.676, 0.328),
      PathOp.lineTo(36.322, 0.328),
      PathOp.curveTo(31.567, 0.328, 27.090, 0.145, 22.582, 1.595),
      PathOp.curveTo(19.830, 2.481, 17.284, 3.915, 15.028, 5.862),
      PathOp.curveTo(12.829, 7.758, 11.008, 10.057, 9.723, 12.571),
      PathOp.curveTo(8.656, 14.656, 7.989, 16.810, 7.612, 19.170),
      PathOp.curveTo(7.218, 21.618, 7.188, 23.833, 7.114, 26.198),
      PathOp.curveTo(7.080, 27.255, 7.103, 28.348, 6.852, 29.534),
      PathOp.curveTo(6.609, 30.680, 6.149, 31.662, 5.378, 32.416),
      PathOp.curveTo(4.607, 33.171, 3.611, 33.609, 2.459, 33.825),
      PathOp.curveTo(1.757, 33.955, 1.088, 33.993, 0.441, 34.002),
      PathOp.close(),
    ],
  ),
  description: 'Notch, 390 × 844 — covers iPhone 12, 13, 14',
);

// iPhone 15: 6.1" Super Retina XDR, Dynamic Island.
// Dynamic Island: ~126×37pt pill, ~11pt from screen top
//   (community measurement; hardware cutout, not the expanded software UI).
// Safe-area: useyourloaf.com iPhone 15 Screen Sizes
// Corner border: 6-segment squircle Bézier from the Simulator framebuffer PDF
// (Xcode 16, "iPhone 15", 1179×2556 px, 3× scale).
//   Top tangent: 393 − 318.35 = 74.65 pt. Side tangent: 73.80 pt.
//   Same corner shape as iPhone 14 Pro, 15 Pro, 16, 16e.
final iphone_15 = DeviceProfile(
  id: 'iphone_15',
  name: 'iPhone 15',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(393, 852),
  safeAreaPortrait: const EdgeInsets.only(top: 59, bottom: 34),
  safeAreaLandscape: const EdgeInsets.only(left: 59, bottom: 20),
  screenBorder: const SquircleBorder(
    topTangentLength: 74.65,
    // Segments relative to top-right corner (393, 0). Each row: cp1x, cp1y,
    // cp2x, cp2y, x, y.
    segments: [
      [-70.06, 0.00, -65.48, 0.02, -60.89, 0.19],
      [-55.47, 0.39, -50.10, 0.80, -44.74, 1.80],
      [-33.93, 3.82, -24.09, 8.19, -16.14, 16.14],
      [-8.19, 24.09, -3.82, 33.92, -1.80, 44.74],
      [-0.80, 50.10, -0.39, 55.47, -0.19, 60.90],
      [-0.03, 65.20, 0.00, 69.50, 0.00, 73.80],
    ],
  ),
  cutout: const DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  description:
      'Dynamic Island, 393 × 852 — proxy for iPhone 14 Pro, 15 Pro, 16, 16e',
);

// iPhone 15 Pro Max: 6.7" variant; same DI cutout geometry.
// Corner border: 6-segment squircle Bézier from the Simulator framebuffer PDF
// (Xcode 16, "iPhone 15 Plus", 1290×2796 px, 3× scale).
//   Top tangent: 430 − 355.35 = 74.65 pt. Side tangent: 75.90 pt.
//   Same tangent length as the 393 pt wide family; corner shape is identical.
// Source: useyourloaf.com, iosresolution.com
final iphone_15_pro_max = DeviceProfile(
  id: 'iphone_15_pro_max',
  name: 'iPhone 15 Pro Max',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(430, 932),
  safeAreaPortrait: const EdgeInsets.only(top: 59, bottom: 34),
  safeAreaLandscape: const EdgeInsets.only(left: 59, bottom: 20),
  screenBorder: const SquircleBorder(
    topTangentLength: 74.65,
    // Segments relative to top-right corner (430, 0). Each row: cp1x, cp1y,
    // cp2x, cp2y, x, y.
    segments: [
      [-70.06, 0.00, -65.48, 0.02, -60.89, 0.19],
      [-55.47, 0.39, -50.10, 0.80, -44.74, 1.80],
      [-33.93, 3.82, -24.09, 8.19, -16.14, 16.14],
      [-8.19, 24.09, -3.82, 33.92, -1.80, 44.74],
      [-0.80, 50.10, -0.39, 55.47, -0.19, 60.90],
      [0.00, 65.90, 0.00, 70.90, 0.00, 75.90],
    ],
  ),
  cutout: const DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  description: 'Dynamic Island, 430 × 932 — covers iPhone 15 Plus, 16 Plus',
);

// iPhone 17: 6.1" display, 402×874 logical pixels.
// Apple changed the standard iPhone screen size with the iPhone 17; it now
// shares the same 402×874 geometry as the iPhone 17 Pro (Simulator-confirmed).
// Corner border: Simulator framebuffer PDF ("iPhone 17", 1206×2622 px, 3× scale)
// — identical PDF to "iPhone 17 Pro".
//   Top tangent: 402 − 317.34 = 84.66 pt. Side tangent: 84.50 pt.
// Listed separately so the current standard flagship appears in the picker.
final iphone_17 = DeviceProfile(
  id: 'iphone_17',
  name: 'iPhone 17',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(402, 874),
  safeAreaPortrait: const EdgeInsets.only(top: 62, bottom: 34),
  safeAreaLandscape: const EdgeInsets.only(left: 62, bottom: 20),
  screenBorder: const SquircleBorder(
    topTangentLength: 84.66,
    // Segments relative to top-right corner (402, 0). Identical to iphone_17_pro.
    segments: [
      [-79.32, 0.00, -73.98, 0.02, -68.63, 0.21],
      [-62.51, 0.44, -56.46, 0.90, -50.42, 2.03],
      [-38.23, 4.30, -27.14, 9.23, -18.19, 18.19],
      [-9.23, 27.14, -4.30, 38.23, -2.03, 50.43],
      [-0.90, 56.46, -0.44, 62.51, -0.21, 68.62],
      [-0.02, 73.92, 0.00, 79.21, 0.00, 84.50],
    ],
  ),
  cutout: const DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  description:
      'Current standard iPhone, 402 × 874 — same geometry as iPhone 17 Pro',
);

// iPhone 17 Air: 6.6" display, 420×912 logical pixels.
// Introduced with the iPhone 17 Air (2025). Source: issue #60.
// Corner border: 6-segment squircle Bézier extracted from the Simulator
// framebuffer PDF ("iPhone Air", 1260×2736 px physical, 3× scale).
// The PDF uses a 2× internal coordinate space (2520×5472), so all values are
// divided by 6 to get logical points.
//   Top tangent: 420 − 1989.283/6 = 88.45 pt. Side tangent: 88.17 pt.
// DI cutout: same pill shape as the rest of the Dynamic Island family.
// Safe area: top 68pt (confirmed via iOS Simulator), bottom 34pt.
final iphone_17_air = DeviceProfile(
  id: 'iphone_17_air',
  name: 'iPhone 17 Air',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(420, 912),
  safeAreaPortrait: const EdgeInsets.only(top: 68, bottom: 34),
  safeAreaLandscape: const EdgeInsets.only(left: 68, bottom: 20),
  screenBorder: const SquircleBorder(
    topTangentLength: 88.45,
    // Segments relative to top-right corner (420, 0). Each row: cp1x, cp1y,
    // cp2x, cp2y, x, y.
    segments: [
      [-82.87, 0.00, -77.29, 0.02, -71.71, 0.22],
      [-65.31, 0.46, -58.99, 0.94, -52.68, 2.12],
      [-39.94, 4.49, -28.36, 9.64, -19.00, 18.98],
      [-9.65, 28.32, -4.49, 39.90, -2.12, 52.62],
      [-0.95, 58.92, -0.46, 65.23, -0.22, 71.61],
      [-0.02, 77.13, 0.00, 82.65, 0.00, 88.17],
    ],
  ),
  cutout: const DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  description: 'Dynamic Island, 420 × 912 — iPhone 17 Air',
);

// iPhone 17 Pro: 6.3" display, 402×874 logical pixels.
// This geometry was introduced with the iPhone 16 Pro and continues with the
// iPhone 17 Pro. Source: issue #59.
// Corner border: 6-segment squircle Bézier from the Simulator framebuffer PDF
// (Xcode 16, "iPhone 16 Pro", 1206×2622 px, 3× scale).
//   Top tangent: 402 − 317.34 = 84.66 pt. Side tangent: 84.50 pt.
// DI cutout: same pill shape as iPhone 15/16 family (community measurement).
// Safe area: same as other Dynamic Island iPhones (portrait T:59 B:34).
final iphone_17_pro = DeviceProfile(
  id: 'iphone_17_pro',
  name: 'iPhone 17 Pro',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(402, 874),
  safeAreaPortrait: const EdgeInsets.only(top: 62, bottom: 34),
  safeAreaLandscape: const EdgeInsets.only(left: 62, bottom: 20),
  screenBorder: const SquircleBorder(
    topTangentLength: 84.66,
    // Segments relative to top-right corner (402, 0). Each row: cp1x, cp1y,
    // cp2x, cp2y, x, y.
    segments: [
      [-79.32, 0.00, -73.98, 0.02, -68.63, 0.21],
      [-62.51, 0.44, -56.46, 0.90, -50.42, 2.03],
      [-38.23, 4.30, -27.14, 9.23, -18.19, 18.19],
      [-9.23, 27.14, -4.30, 38.23, -2.03, 50.43],
      [-0.90, 56.46, -0.44, 62.51, -0.21, 68.62],
      [-0.02, 73.92, 0.00, 79.21, 0.00, 84.50],
    ],
  ),
  cutout: const DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  description: 'Dynamic Island, 402 × 874 — covers iPhone 16 Pro, 17 Pro',
);

// iPhone 17 Pro Max: 6.9" display, largest screen Apple has shipped.
// Logical size 440×956pt confirmed at launch (Sept 2025).
// Corner border: 6-segment squircle Bézier from the Simulator framebuffer PDF
// (Xcode 16, "iPhone 17 Pro Max", 1320×2868 px, 3× scale).
//   Top tangent: 440 − 354.84 = 85.16 pt. Side tangent: 85.00 pt.
// DI cutout and safe-area values extrapolated from the iPhone 15 Pro Max family.
// Source: iosresolution.com, community measurements
final iphone_17_pro_max = DeviceProfile(
  id: 'iphone_17_pro_max',
  name: 'iPhone 17 Pro Max',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(440, 956),
  safeAreaPortrait: const EdgeInsets.only(top: 62, bottom: 34),
  safeAreaLandscape: const EdgeInsets.only(left: 62, bottom: 20),
  screenBorder: const SquircleBorder(
    topTangentLength: 85.16,
    // Segments relative to top-right corner (440, 0). Each row: cp1x, cp1y,
    // cp2x, cp2y, x, y.
    segments: [
      [-79.79, 0.00, -74.41, 0.02, -69.04, 0.22],
      [-62.88, 0.44, -56.80, 0.91, -50.73, 2.04],
      [-38.46, 4.33, -27.30, 9.29, -18.30, 18.30],
      [-9.29, 27.31, -4.33, 38.46, -2.04, 50.73],
      [-0.91, 56.80, -0.44, 62.88, -0.21, 69.03],
      [-0.02, 74.35, 0.00, 79.68, 0.00, 85.00],
    ],
  ),
  cutout: const DynamicIslandCutout(size: Size(126, 37), topOffset: 11),
  description: 'Largest iPhone screen, 440 × 956',
);

// ── Android ──────────────────────────────────────────────────────────────

// Samsung Galaxy A15 (4G, SM-A155F, released Dec 2023).
// Physical: 1080×2340px. Runtime density: 2.625 DPR.
//   Logical size: 1080/2.625 × 2340/2.625 ≈ 411×892dp.
// Display type: Infinity-U (teardrop/waterdrop notch).
// Corner radius: ~38dp (measured from skin PNG).
// Notch: width 44dp, height 30dp, bottomRadius 22dp, sideRadius 13dp
//   (measured from skin PNG via tool/measure_device.py).
// Safe area portrait: status bar 32dp covers the full notch height.
// Safe area landscape: teardrop rotates to left edge; left ≈ 32dp.
final samsung_galaxy_a15 = DeviceProfile(
  id: 'samsung_galaxy_a15',
  name: 'Samsung Galaxy A15',
  platform: DevicePlatform.android,
  logicalSize: const Size(411, 892),
  safeAreaPortrait: const EdgeInsets.only(top: 32, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(left: 32, bottom: 24),
  screenBorder: const CircularBorder(38),
  cutout: const TeardropCutout(
    width: 44,
    height: 30,
    bottomRadius: 22,
    sideRadius: 13,
  ),
  description: 'Budget Samsung Infinity-U notch, 411 × 892 — covers A15, A25',
);

// Samsung Galaxy A55 (SM-A556B, released Mar 2024).
// Corner radius: 94px / 2.625 DPR = 35.8 ≈ 36dp.
// Punch hole: centered, horizontally.
//   Camera radius 27px → diameter 54px / 2.625 = 20.6 ≈ 21dp.
//   Camera center Y 65px / 2.625 = 24.8 ≈ 25dp from screen top.
// Logical size and safe areas: community approximation — not yet verified.
final samsung_galaxy_a55 = DeviceProfile(
  id: 'samsung_galaxy_a55',
  name: 'Samsung Galaxy A55',
  platform: DevicePlatform.android,
  logicalSize: const Size(384, 854),
  safeAreaPortrait: const EdgeInsets.only(top: 24, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(bottom: 24),
  screenBorder: const CircularBorder(36),
  cutout: const PunchHoleCutout(diameter: 21, topOffset: 25),
  description: 'Mid-range Samsung A-series, ~384 × 854 — covers A54, A55',
);

// Samsung Galaxy S24: Samsung does not publish device-tree cutout geometry.
// Corner radius: 94px / 3.0 DPR = 31.3 ≈ 31dp.
// Punch hole: centered, horizontally.
//   Camera radius 27px → diameter 54px / 3.0 = 18dp.
//   Camera center Y 54px / 3.0 = 18dp from screen top.
final samsung_galaxy_s24 = DeviceProfile(
  id: 'samsung_galaxy_s24',
  name: 'Samsung Galaxy S24',
  platform: DevicePlatform.android,
  logicalSize: const Size(360, 780),
  safeAreaPortrait: const EdgeInsets.only(top: 24, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(bottom: 24),
  screenBorder: const CircularBorder(31),
  cutout: const PunchHoleCutout(diameter: 18, topOffset: 18),
  description: 'Flagship Samsung, 360 × 780 — covers S23, S24',
);

// Pixel 7a (codename: lynx).
// Cutout: verified against Android Emulator via `adb shell dumpsys display`.
//   Cutout spec: M 507,66 a 33,33 0 1 0 66,0 33,33 0 1 0 -66,0 Z @left
//   Circle: center (540, 66)px physical, radius 33px physical.
//   Diameter: 66px / 2.625 DPR ≈ 25dp; center Y: 66px / 2.625 ≈ 25dp.
// Corner radius: 47px / 2.625 ≈ 18dp (from roundedCorners in dumpsys output).
// Safe areas: verified against Android Emulator.
final pixel_7a = DeviceProfile(
  id: 'pixel_7a',
  name: 'Google Pixel 7a',
  platform: DevicePlatform.android,
  logicalSize: const Size(411, 914),
  safeAreaPortrait: const EdgeInsets.only(top: 45, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(left: 45, top: 28, bottom: 24),
  screenBorder: const CircularBorder(18),
  cutout: const PunchHoleCutout(diameter: 25, topOffset: 25),
  description: 'Mid-range Pixel, small punch hole — covers Pixel 7a, 8, 8a',
);

// Pixel 10 (codename: frankel, in muzel repo).
// Cutout: verified against Pixel 9 Android Emulator (adb shell dumpsys display).
//   cutoutSpec: m 581.5,86.5 a 42,42 0 0 0 -84,0 42,42 0 0 0 84,0 z @left
//   Circle: center (539.5, 86.5)px physical, radius 42px physical.
//   Diameter: 84px / 2.625 = 32dp. Center Y: 86.5px / 2.625 ≈ 33dp.
// Corner radius: AOSP config_mainDisplayShape (Pixel 9 / tokay device tree):
//   193.8px / 2.625 ≈ 74dp. (Emulator reports 132px = 50dp; emulator geometry
//   is simplified — AOSP device tree is considered authoritative.)
// Safe areas: verified against Pixel 9 Android Emulator (adb shell dumpsys window).
//   Portrait:  statusBars=[0,0][1080,142] → 142px/2.625≈54dp top;
//              navigationBars=[0,2361][1080,2424] → 63px/2.625=24dp bottom.
//   Landscape: configInsets=[142,137][0,63] → left=54dp, top=52dp, bottom=24dp.
// Note: Google has not published Pixel 10 device trees to AOSP; data sourced
//   from the community-maintained TensorG5-devs/device_google_muzel repo.
//   Panel geometry is identical to the Pixel 9 (same 1080×2424px display).
final pixel_10 = DeviceProfile(
  id: 'pixel_10',
  name: 'Google Pixel 10',
  platform: DevicePlatform.android,
  logicalSize: const Size(411, 923),
  safeAreaPortrait: const EdgeInsets.only(top: 54, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(left: 54, top: 52, bottom: 24),
  screenBorder: const CircularBorder(74),
  cutout: const PunchHoleCutout(diameter: 32, topOffset: 33),
  description: 'Large punch hole, 411 × 923 — covers Pixel 9 and 10',
);

// Pixel 10 Pro (codename: blazer, in muzel repo).
// Cutout: TensorG5-devs/device_google_muzel, blazer overlay.
//   m 689,102 a 49,49 0 0 0 -98,0 49,49 0 0 0 98,0 z @left
//   Circle: center (640, 102)px physical, radius 49px. Centered on 1280px
//   display. Diameter: 98px / 3.125 ≈ 31dp. Center Y: 102px / 3.125 ≈ 33dp.
// Corner radius: AOSP config_mainDisplayShape (Pixel 9 Pro / caimito device tree,
//   which shares the same 1280×2856px display panel as Pixel 10 Pro):
//   path starts at (0.003, 226.705) → 226.705px / 3.125 ≈ 73dp.
// Safe area portrait: AOSP config_mainBuiltInDisplayCutoutRectApproximation,
//   blazer: m 586,0 h 108.5 v 204 h -108.5 Z → height 204px / 3.125 ≈ 65dp.
// Safe area landscape: left = topOffset + diameter = 33 + 31 = 64dp.
// Note: DPR is 3.125 (density 500 = 500/160) set via vendor proprietary
//   config; AOSP TARGET_SCREEN_DENSITY says 480 but runtime value is 500.
//   Cutout and safe-area data from TensorG5-devs/device_google_muzel (Pixel 10
//   Pro device tree not yet published to AOSP as of early 2026).
final pixel_10_pro = DeviceProfile(
  id: 'pixel_10_pro',
  name: 'Google Pixel 10 Pro',
  platform: DevicePlatform.android,
  logicalSize: const Size(410, 914),
  safeAreaPortrait: const EdgeInsets.only(top: 65, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(left: 64, bottom: 24),
  screenBorder: const CircularBorder(73),
  cutout: const PunchHoleCutout(diameter: 31, topOffset: 33),
  description: 'High-DPR Pixel (3.125), 410 × 914',
);

// ── Tablets ──────────────────────────────────────────────────────────────

// iPad mini (A17 Pro): compact form factor with thin bezels.
// Corner radius: ~18pt (community approximation; same family as iPad 10th
// gen).
// No camera cutout — front camera in the top bezel.
// Source: iosresolution.com, useyourloaf.com
final ipad_mini_a17 = DeviceProfile(
  id: 'ipad_mini_a17',
  name: 'iPad mini (A17 Pro)',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(744, 1133),
  safeAreaPortrait: const EdgeInsets.only(top: 32, bottom: 20),
  safeAreaLandscape: const EdgeInsets.only(top: 32, bottom: 20),
  screenBorder: const CircularBorder(18),
  cutout: const NoCutout(),
  tablet: true,
  description: 'Compact iPad, 744 × 1133',
);

// iPad (A16): thin-bezel design; rounded display corners visible.
// Corner radius: ~18pt (community approximation).
// No camera cutout — front camera sits in the top bezel.
// Source: iosresolution.com, useyourloaf.com
final ipad_a16 = DeviceProfile(
  id: 'ipad_a16',
  name: 'iPad (A16)',
  platform: DevicePlatform.iOS,
  logicalSize: const Size(820, 1180),
  safeAreaPortrait: const EdgeInsets.only(top: 32, bottom: 20),
  safeAreaLandscape: const EdgeInsets.only(top: 32, bottom: 20),
  screenBorder: const CircularBorder(18),
  cutout: const NoCutout(),
  tablet: true,
  description: 'Standard iPad, 820 × 1180',
);

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
  static DeviceProfile get defaultProfile => iphone_15;
}
