# CLAUDE.md — bezel

This file is guidance for AI coding agents working on this project. Read it fully before
making changes.

---

## What This Project Is

`bezel` is a Flutter debug-mode tool that lets developers preview their app
against popular mobile device profiles while running on desktop. It spoofs device metrics
at the binding layer (not via widget injection), provides a minimal floating UI for device
selection and orientation toggle, and auto-resizes the desktop window to fit the emulated
device.

Read `DESIGN.md` for the full architecture. Read `docs/PLAN.md` for the current task list.

---

## Language and Style

- **Dart only.** No generated code, no build_runner, no macros.
- Follow the [official Dart style guide](https://dart.dev/effective-dart/style).
- Use `final` everywhere it's applicable. Prefer `const` constructors.
- Use named parameters for anything with more than two parameters.
- No `dynamic`. No unnecessary casts. Prefer sealed classes / exhaustive switches for
  discriminated unions.
- Doc comments (`///`) on all public API. Brief inline comments for non-obvious logic only.
- Keep files focused. If a file is growing past ~200 lines, consider whether it should split.

---

## Architecture Rules

**Never inject MediaQuery wrapper widgets to spoof device metrics.** The spoofing happens
exclusively in `PreviewBinding` / `PreviewPlatformDispatcher` / `PreviewFlutterView`.
If you find yourself adding a `MediaQuery(data: ..., child: ...)` anywhere in the preview
mechanism, stop and reconsider.

**The `src/` directory is private.** Only `bezel.dart` (the barrel file) is
public API. Do not add exports from `src/` directly in consumer code.

**`PreviewController` is the single source of truth** for active device profile,
orientation, and toolbar visibility. UI widgets read from it via `ListenableBuilder` or
`AnimatedBuilder`. The binding layer holds a reference to it and reacts to changes.

**Debug-only enforcement.** All preview code must be unreachable in profile/release builds.
The pattern is:

```dart
// In bezel.dart:
void ensureInitialized() {
  assert(() {
    _debugEnsureInitialized();
    return true;
  }());
}
```

For tree-shaking guarantees on the binding itself, use conditional imports:

```dart
// bezel.dart
export 'src/preview_real.dart'
  if (dart.library.html) 'src/preview_stub.dart';
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

### Reading the active profile in a widget

```dart
class _MyWidget extends StatelessWidget {
  const _MyWidget({required this.controller});
  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final profile = controller.activeProfile;
        // ...
      },
    );
  }
}
```

### Adding a new device profile

Add an entry to `device_database.dart`. The `DeviceProfile` constructor is the only
thing that needs to change — no registration, no factory, no codegen.

```dart
DeviceProfile(
  id: 'pixel_8',
  name: 'Pixel 8',
  platform: DevicePlatform.android,
  logicalSize: const Size(411, 914),
  devicePixelRatio: 2.625,
  safeAreaPortrait: const EdgeInsets.only(top: 48, bottom: 24),
  safeAreaLandscape: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
  frameStyle: DeviceFrameStyle.punchHole,
),
```

### Changing what the binding spoofs

All spoofing lives in `PreviewFlutterView`. Add or modify overrides there. Always
delegate to `_real` for anything not being spoofed:

```dart
@override
double get devicePixelRatio =>
    _controller.activeProfile?.devicePixelRatio ?? _real.devicePixelRatio;
```

---

## What Not to Do

- Do not add dependencies without a clear reason. The dep list is intentionally minimal.
- Do not support Flutter Web. The whole premise doesn't apply.
- Do not add a plugin/extension system. Keep the surface area small.
- Do not use `BuildContext` in the binding layer. The binding exists below the widget tree.
- Do not persist state across sessions (e.g. to shared_preferences). Session memory only.
- Do not add screenshot functionality in Phase 1 or 2. It's out of scope.
- Do not add locale / accessibility / text scale overrides. Those are out of scope.

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

To run tests:
```
flutter test
```

To check analysis:
```
flutter analyze
```

To check formatting:
```
dart format --set-exit-if-changed .
```

All three must be clean before a change is considered done.
