# Device Cutout Geometry Research Summary

## Context

This document summarizes research into data sources for physical screen cutout geometry
(notches, punch-holes, Dynamic Islands, rounded corners) for use in a Flutter desktop device
preview tool. The tool needs to render accurate cutout shapes so developers can spot layout
issues before testing on real devices.

---

## Android: Authoritative Machine-Readable Data Available

Android device manufacturers are required to define cutout geometry as SVG path data in
their AOSP device tree, in a resource file typically at:

```
device/google/<codename>/overlay/frameworks/base/core/res/res/values/config.xml
```

The relevant XML keys are:

| Key | Contents |
|---|---|
| `config_mainBuiltInDisplayCutout` | Exact SVG path of the cutout shape, in **physical pixels** |
| `config_mainBuiltInDisplayCutoutRectApproximation` | Bounding box used for layout inset calculations |
| `config_mainDisplayShape` | SVG path of the full screen outline, including rounded corners |

Coordinates use the `@left` suffix convention (origin at left edge of display). The `@dp`
suffix can also appear, indicating coordinates are already in density-independent pixels.

**This is the exact data Android's `DisplayCutout` API reads at runtime.** It is as
authoritative as it gets.

### Example: Pixel 8 Pro (codename `shusky`, from AOSP)

Physical display: 1344x2992px, DPR ~ 2.625

```xml
<string name="config_mainBuiltInDisplayCutout">
    M 626.5,75.5
    a 45,45 0 1 0 90,0
    a 45,45 0 1 0 -90,0
    Z
    @left
</string>

<string name="config_mainBuiltInDisplayCutoutRectApproximation">
    M 615.5,0
    h 110
    v 151
    h -110
    Z
    @left
</string>
```

This describes a circle centered at (671.5px, 75.5px) with radius 45px.

Converting to logical pixels (dp) by dividing by DPR 2.625:
- Center: approximately (256dp, 29dp) from top-left of screen
- Radius: approximately 17dp
- Diameter: approximately 34dp

### Where to Find Android Device Trees

- **Google Pixels**: `android.googlesource.com/device/google/<codename>` -- authoritative
  source, publicly accessible
- **GitHub mirrors**: Many custom ROM projects (LineageOS, GrapheneOS, etc.) maintain
  mirrors under `android_device_google_<codename>` -- easier to browse on GitHub
- **Codename lookup**: gsmarena.com or the LineageOS device wiki list codenames

Key Pixel codenames:
| Device | Codename |
|---|---|
| Pixel 7a | `lynx` |
| Pixel 8 | `shiba` |
| Pixel 8 Pro | `husky` (in `shusky` repo) |
| Pixel 9 | `tokay` |

For non-Google Android devices (Samsung, OnePlus, etc.), device trees may be in
manufacturer GitHub repos or community ROM trees. Samsung in particular keeps most of its
device-specific config proprietary, so community measurements may be needed.

### Coordinate System Notes

- All coordinates in `config_mainBuiltInDisplayCutout` are in **physical pixels** unless
  the path ends with `@dp`
- The SVG path origin is the **top-left of the full display** (not the safe area)
- To convert to Flutter logical pixels: divide each coordinate by the device's
  `devicePixelRatio`
- The `@left` suffix is an Android convention meaning the path is specified relative to
  the left edge -- this is the default and just indicates coordinate origin

---

## iOS: Community Approximations Only

Apple does not publish machine-readable cutout geometry. No equivalent of Android's
`config_mainBuiltInDisplayCutout` exists in any public Apple developer resource.

### What Is Available

**Safe area insets** -- reliably documented by the community via device measurement.
The useyourloaf.com blog is the most thorough and regularly updated source:
- iPhone 15 portrait: top 59pt, bottom 34pt
- iPhone 15 Pro Max portrait: top 59pt, bottom 34pt
- iPhone 15 Pro landscape: top 0pt, bottom 21pt, left 59pt, right 59pt

**Dynamic Island dimensions** -- designer approximations based on measurement and
reverse engineering. Widely cited values for the compact/default pill shape:
- iPhone 14 Pro / 15 / 15 Pro: approximately 126x37pt, with ~19pt corner radius
- The pill sits approximately 11-14pt from the top edge of the screen area
- These are community figures, not Apple-published specs

Note: The Dynamic Island is actually two separate hardware cutouts (a pill for Face ID
sensors and a circle for the camera) that are visually merged by software. The outer pill
shape is what matters for layout purposes.

**Corner radii** -- not officially published. Community measurements suggest approximately
47-55pt on modern iPhones (iPhone 12 and later). The SwiftUI `ContainerRelativeShape` API
adapts to device corners at runtime but does not expose the underlying radius.

### Reliable iOS Reference Sources

- **useyourloaf.com/blog** -- "iPhone XX Screen Sizes" posts, updated each year. Covers
  logical screen size, DPR, status bar height, and safe area insets for every model.
- **iOS Resolution** (iosresolution.com) -- tabular reference for physical resolution,
  logical resolution, and DPR across all models.
- **Apple HIG** -- documents safe area insets conceptually but not numerically.
- **Apple Tech Specs** -- physical resolution only; no logical pixel data or cutout geometry.

---

## iOS Simulator `.simdevicetype` Bundles

The iOS Simulator ships with `.simdevicetype` bundles under:

```
/Library/Developer/CoreSimulator/Profiles/DeviceTypes/
```

Each bundle contains `Contents/Resources/`:

| File | Contents |
|---|---|
| `profile.plist` | Device metadata: physical dimensions, scale, file references |
| `{UUID}.pdf` (path from `framebufferMask` key) | Screen outline path in **physical pixels** |
| `{name}.pdf` (path from `sensorBarImage` key) | Notch/sensor bar path in **logical points** |

### Extracting Corner Radii from `framebufferMask`

The framebuffer mask PDF contains a FlateDecode-compressed path stream describing the
screen outline in **physical pixels** (MediaBox matches physical resolution). The path
traces the screen starting at the top edge, curves around each corner, and closes.

To find the corner radius:
1. Find all `l` (lineto) coordinates on the top edge (y == screen_height_px).
2. The last such x-coordinate before the corner curve is the tangent point.
3. `corner_radius_px = screen_width_px - tangent_x`
4. `corner_radius_pt = corner_radius_px / scale`

Corner radii extracted from Simulator framebuffer PDFs (as of Xcode 16 / early 2026):

| Device family | Logical size | Scale | Corner radius (px) | Corner radius (pt) | Current DB value |
|---|---|---|---|---|---|
| iPhone 12, 12 Pro, 13, 14 | 390 × 844 | 3x | ~160 px | **~53 pt** | 44 pt |
| iPhone 15, 15 Pro, 16 | 393 × 852 | 3x | ~183 px | **~61 pt** | 44 pt |
| iPhone 16 Pro | 402 × 874 | 3x | ~206 px | **~69 pt** | 44 pt (n/a) |
| iPhone 17 Pro Max | 440 × 956 | 3x | ~207 px | **~69 pt** | 44 pt |

**These values are significantly larger than the 44pt currently in the database.** The
current 44pt figure is a widely-cited community approximation that appears to represent
the inner corner radius of the glass, not the outer display radius. The Simulator PDFs
contain the authoritative screen-clip geometry. The database should be updated once
the visual difference is validated.

Note: Apple uses squircle (superellipse) curves for screen corners, not circular arcs.
The radius extracted here approximates the circular arc radius that best fits the
squircle tangent point; the actual path is subtly different.

### Notch Geometry from `sensorBarImage`

The sensor bar PDF contains the notch or Dynamic Island shape:

- **Pre-Dynamic Island devices** (iPhone X–14): contains a FlateDecode path stream
  with the notch Bezier path. MediaBox dimensions appear to be in **logical points**
  and represent the notch bounding area only (not the full screen width).
- **Dynamic Island devices** (iPhone 14 Pro and later): sensor bar PDF contains only
  `q Q` (empty). The DI shape is drawn programmatically by the Simulator; no path
  data is stored here.

iPhone 13 / iPhone 14 share the same sensor bar PDF (`sensor_bar_class_03` /
`sensor_bar_class_04`). The notch PDF has MediaBox `0 0 176 34`, meaning the notch
area is approximately **176 pt wide and 34 pt tall** in logical points. The Bezier
path data contains concave ear arcs (squircles) where the notch meets the display edge.

The tool `tool/extract_simdevicetype.dart` can extract and print both the corner
radius and the raw sensor bar path data for any Simulator device.

---

## Rounded Screen Corners

### Android
The `config_mainDisplayShape` key in the same device config XML provides an SVG path
describing the full screen outline including corner curves. This is authoritative geometry.
It is also in physical pixels (divide by DPR to get dp).

### iOS
The `framebufferMask` PDF in each `.simdevicetype` bundle (see above) is authoritative.
Community measurements of ~47pt were approximations; Simulator data shows ~53–69pt
depending on generation (see table above).

---

## Recommended Approach for Bezel's Device Database

**For Android (Pixel) profiles**: Extract cutout geometry directly from AOSP device tree
XML. Convert physical pixel coordinates to dp by dividing by the device's DPR. This gives
authoritative, exact values.

**For iOS profiles**: Use community-measured safe area insets (reliable) and
community-approximated Dynamic Island dimensions (good enough for "few surprises" goal).

---

## Quick Reference: Converting Android SVG Path to Flutter Cutout

Given a `config_mainBuiltInDisplayCutout` path like the Pixel 8 Pro example:

```
M 626.5,75.5
a 45,45 0 1 0 90,0
a 45,45 0 1 0 -90,0
Z
@left
```

1. Identify the shape: two arc commands completing a circle -> `PunchHoleCutout`
2. Extract center: `M x,y` where x = 626.5 + 45 = 671.5, y = 75.5 (center of arc)
   -- the `M` command moves to the *leftmost point* of the circle, so add the radius
   to get the horizontal center
3. Extract radius: 45px
4. Divide by device DPR (2.625) -> center (256dp, 29dp), radius ~17dp
5. `centerX` = 256dp (not centered -- use explicit value)
6. `topOffset` = 29dp - 17dp = 12dp (top of circle from screen top)

```dart
PunchHoleCutout(
  diameter: 34,      // 2 x 17dp
  topOffset: 12,
  centerX: 256,      // not centered; specify explicitly
)
```

For a notch path (the wide trapezoid/curve shape used on older Pixels and iPhones X-14),
the path will be more complex. Parse the bounding box from
`config_mainBuiltInDisplayCutoutRectApproximation` instead -- it gives a clean Rect that
maps directly to `NotchCutout(size: Size(width, height), topOffset: ...)`.
