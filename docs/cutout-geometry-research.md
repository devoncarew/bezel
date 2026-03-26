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

## Rounded Screen Corners

### Android
The `config_mainDisplayShape` key in the same device config XML provides an SVG path
describing the full screen outline including corner curves. This is authoritative geometry.
It is also in physical pixels (divide by DPR to get dp).

### iOS
Not officially published. The design community approximates corner radii by overlaying
circles on device screenshots. Common cited values:
- iPhone 12 and later: ~47pt outer corner radius, ~39pt inner (screen) corner radius
- Figma device mockup files from Apple's design resources use these approximations

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
