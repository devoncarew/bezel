# CLAUDE.md — flight_check

flight_check is a Flutter **debug-only** desktop tool that lets developers
preview their app against mobile device profiles. It spoofs device metrics at
the binding layer (not via widget injection), shows a minimal floating UI for
device/orientation selection, and auto-resizes the desktop window to fit the
emulated device.

@docs/toc.md for a project map, annotated file structure, and links to deeper
docs.

---

## Architecture Rules

**Never inject MediaQuery wrapper widgets.** Spoofing happens exclusively in
`PreviewBinding` / `PreviewPlatformDispatcher` / `PreviewFlutterView`. Never add
`MediaQuery(data: ..., child: ...)` anywhere in the preview mechanism.

**`src/` is private.** Only `flight_check.dart` (the barrel file) is public API.
Do not add exports from `src/` in consumer code.

**`PreviewController` is the single source of truth** for active device profile,
orientation, and toolbar visibility. UI widgets read from it via
`ListenableBuilder`. The binding holds a reference and reacts to changes.

**Debug-only enforcement.** All preview code must be unreachable in
profile/release builds:

```dart
void configure() {
  assert(() { _debugEnsureInitialized(); return true; }());
}
```

For tree-shaking guarantees on the binding itself, use conditional imports:

```dart
export 'src/preview_real.dart'
  if (dart.library.io) 'src/preview_stub.dart';
```

---

## Language and Style

- **Dart only.** No generated code, no build_runner, no macros.
- Follow the [Dart style guide](https://dart.dev/effective-dart/style).

---

## Constraints

- No new dependencies without a strong reason (`window_manager` is the only
  current dep).
- No Flutter Web support — the premise does not apply.
- No plugin/extension system. Keep the surface area small.
- No `BuildContext` in the binding layer.
- No persisting state across sessions (e.g. shared_preferences). Session memory
  only.

---

## Build and Test

```
# Run the example app to test changes manually:
cd example && flutter run -d macos    # or linux / windows

# Before every commit — all three must pass:
dart format .
flutter analyze
flutter test
```

`dart format` is not optional. Unformatted code fails CI. Run it even for
single-line changes.
