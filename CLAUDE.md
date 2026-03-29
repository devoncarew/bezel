# CLAUDE.md — flight_check

This file is guidance for AI coding agents working on this project. Read it fully before
making changes.

---

## What This Project Is

`flight_check` is a Flutter debug-mode tool that lets developers preview their app
against popular mobile device profiles while running on desktop. It spoofs device metrics
at the binding layer (not via widget injection), provides a minimal floating UI for device
selection and orientation toggle, and auto-resizes the desktop window to fit the emulated
device.

Read `DESIGN.md` for the full architecture. Read `docs/PLAN.md` for the current task list.

---

## Language and Style

- **Dart only.** No generated code, no build_runner, no macros.
- Follow the [official Dart style guide](https://dart.dev/effective-dart/style).
- Keep files focused. If a file is growing past ~200 lines, consider whether it should split.

---

## Architecture Rules

**Never inject MediaQuery wrapper widgets to spoof device metrics.** The spoofing happens
exclusively in `PreviewBinding` / `PreviewPlatformDispatcher` / `PreviewFlutterView`.
If you find yourself adding a `MediaQuery(data: ..., child: ...)` anywhere in the preview
mechanism, stop and reconsider.

**The `src/` directory is private.** Only `flight_check.dart` (the barrel file) is
public API. Do not add exports from `src/` directly in consumer code.

**`PreviewController` is the single source of truth** for active device profile,
orientation, and toolbar visibility. UI widgets read from it via `ListenableBuilder` or
`AnimatedBuilder`. The binding layer holds a reference to it and reacts to changes.

**Debug-only enforcement.** All preview code must be unreachable in profile/release builds.
The pattern is:

```dart
// In flight_check.dart:
void configure() {
  assert(() {
    _debugEnsureInitialized();
    return true;
  }());
}
```

For tree-shaking guarantees on the binding itself, use conditional imports:

```dart
// flight_check.dart
export 'src/preview_real.dart'
  if (dart.library.io) 'src/preview_stub.dart';
```

---

## Testing

- Unit-test `DeviceProfile` logic and `DeviceDatabase` lookups directly.
- Unit-test `PreviewPlatformDispatcher` and `PreviewFlutterView` metric calculations
  (physicalSize, padding derivation) with simple dart tests — no Flutter widget test
  harness needed.
- Widget tests for `DeviceFramePainter` can use `goldens` sparingly; prefer assertion-based
  tests over golden files where possible to reduce maintenance overhead.
- Do not write widget tests that depend on `window_manager` — mock `WindowManagerService`
  at the interface boundary.

Run tests with:
```
flutter test
```

---

## Common Patterns

### Adding a new device profile

Add an entry to `device_database.dart`. The `DeviceProfile` constructor is the only
thing that needs to change — no registration, no factory, no codegen. Include a comment
noting the data source for cutout geometry and corner radius.

```dart
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
  logicalSize: const Size(411, 914),
  safeAreaPortrait: const EdgeInsets.only(top: 45, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(left: 45, top: 28, bottom: 24),
  screenCornerRadius: 18,
  cutout: const PunchHoleCutout(diameter: 25, topOffset: 25),
  description: 'Mid-range Pixel, small punch hole — covers Pixel 7a, 8, 8a',
),
```

### Changing what the binding spoofs

All spoofing lives in `PreviewFlutterView`. Add or modify overrides there. Always
delegate to `_real` for anything not being spoofed:

```dart
@override
ui.Size get physicalSize =>
    _controller.emulatedLogicalSize * _real.devicePixelRatio;
```

---

## What Not to Do

- Do not add dependencies without a clear reason. The dep list is intentionally minimal.
- Do not support Flutter Web. The whole premise doesn't apply.
- Do not add a plugin/extension system. Keep the surface area small.
- Do not use `BuildContext` in the binding layer. The binding exists below the widget tree.
- Do not persist state across sessions (e.g. to shared_preferences). Session memory only.

---

## Dependencies

Current allowed dependencies:

| Package | Reason |
|---|---|
| `window_manager` | Window resize/position — no viable alternative |

Before adding any new dependency, check if the stdlib or Flutter SDK can cover it.

---

## Build and Run

This package is used as a dev dependency or direct source dependency in a
Flutter app. There is no standalone runnable target. To test changes, use the
`example/` app:

```
cd example
flutter run -d macos    # or linux / windows
```

Run these before every commit — all three must be clean:

```
dart format .
flutter analyze
flutter test
```

`dart format` is not optional. Unformatted code will fail CI. Run it even for
single-line changes.
