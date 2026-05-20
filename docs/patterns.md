# flight_check — Common Patterns

How-to reference for the most common agent tasks in this codebase. For
architectural context, see `docs/design.md`. For the project map, see
`docs/toc.md`.

---

## Adding a New Device Profile

Add an entry to `device_database.dart`. The `DeviceProfile` constructor is the
only thing that needs to change — no registration, no factory, no codegen.
Include a comment recording the data source for cutout geometry and corner
radius.

```dart
// Pixel 8a (codename: akita) / covers 7a (lynx), 8 (husky/shiba), 8a (akita).
// Cutout: verified against Android Emulator via `adb shell dumpsys display`.
//   Cutout spec: M 507,66 a 33,33 0 1 0 66,0 33,33 0 1 0 -66,0 Z @left
//   Circle: center (540, 66)px physical, radius 33px physical.
//   Diameter: 66px / 2.625 DPR ≈ 25dp; center Y: 66px / 2.625 ≈ 25dp.
// Corner radius: 47px / 2.625 ≈ 18dp (from roundedCorners in dumpsys output).
// Safe areas: verified against Android Emulator.
final pixel_8a = DeviceProfile(
  id: 'pixel_8a',
  name: 'Google Pixel 8a',
  shortName: 'Pixel 8a',
  platform: DevicePlatform.android,
  logicalSize: const Size(411, 914),
  safeAreaPortrait: const EdgeInsets.only(top: 45, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(left: 45, top: 28, bottom: 24),
  screenBorder: const CircularBorder(18),
  cutout: const PunchHoleCutout(diameter: 25, topOffset: 25),
  description: 'Mid-range A-series Pixel, small punch hole — covers Pixel 7a, 8, 8a',
);
```

For cutout geometry sources and how to convert Android SVG paths to Flutter
values, see `docs/cutout-research.md`. For which devices are already covered and
proxy groups, see `docs/devices.md`.

---

## Modifying What the Binding Spoofs

All metric spoofing lives in `PreviewFlutterView`
(`lib/src/binding/preview_flutter_view.dart`). Add or modify overrides there.
Always delegate to `_real` for anything not being spoofed:

```dart
@override
ui.Size get physicalSize =>
    _controller.emulatedLogicalSize * _real.devicePixelRatio;
```

See `docs/design.md` — "Binding Layer" and "Device Pixel Ratio and Window
Sizing" sections — for the DPR derivation identity and why `physicalSize` is not
a free variable.

---

## Testing

- **Unit-test** `DeviceProfile` logic and `DeviceDatabase` lookups directly.
- **Unit-test** `PreviewPlatformDispatcher` and `PreviewFlutterView` metric
  calculations (physicalSize, padding derivation) with plain Dart tests — no
  Flutter widget harness needed.
- **Widget tests** for `DeviceFramePainter`: prefer assertion-based tests over
  golden files to reduce maintenance overhead.
- **Do not** write widget tests that depend on `window_manager` — mock
  `WindowManagerService` at its interface boundary.

```
flutter test
```
