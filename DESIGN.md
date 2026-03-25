# bezel — Design Document

## Goal

A Flutter desktop development tool that gives you a **"pretty good" sense** of what your app
will look like on popular mobile devices, with few surprises when you switch to a real device.

This is explicitly *not* a pixel-perfect emulator. It is a development ergonomics tool. The
target fidelity bar is: correct logical layout, plausible safe areas, representative screen
proportions, and honest pixel density scaling. Plugin rendering, native views, and sub-pixel
font hinting fidelity are out of scope.

---

## Non-Goals

- Perfect pixel-accurate rendering
- Full platform emulation (status bar behavior, system gestures, native keyboards)
- Flutter Web support
- Profile or release mode use — the tool is debug-only and tree-shaken out entirely otherwise
- Replacing on-device or simulator testing; this is a first-pass approximation tool

---

## Key Design Principles

**1. Low intrusion.** The preview mechanism should touch as little of the app's widget tree as
possible. Spoofing happens below the framework via a custom binding, not by injecting wrapper
widgets that can subtly affect layout.

**2. Minimal chrome.** The UI surface is a small floating toolbar plus a device frame. No
drawers, no settings panels, no plugin slots. Everything non-essential is behind a keyboard
shortcut or omitted entirely.

**3. Sensible defaults, no configuration required.** Drop in two lines — a binding initializer
and a `runApp` wrapper call — and get a working preview. Device selection, window sizing, and
orientation are all interactive at runtime.

**4. Desktop-native feel.** On macOS, controls live in the menu bar. Keyboard shortcuts follow
platform conventions. Window management uses the OS window APIs properly.

---

## Architecture

### Binding Layer (core spoofing mechanism)

A custom `WidgetsFlutterBinding` subclass (`PreviewBinding`) overrides `platformDispatcher`
with a `PreviewPlatformDispatcher`. This dispatcher wraps the real one and, when a
`DeviceProfile` is active, substitutes a `PreviewFlutterView` that reports:

- `physicalSize` — derived from the profile's logical size × its `devicePixelRatio`
- `devicePixelRatio` — the profile's DPR
- `padding` / `viewPadding` / `viewInsets` — the profile's safe area insets
- Everything else delegated to the real view

This means `_MediaQueryFromView` (Flutter's internal widget that populates `MediaQuery` from
the view) automatically derives correct `MediaQueryData` without any widget injection. Code
that bypasses MediaQuery and reads `View.of(context)` directly also sees consistent values.

### DPR Scale Compensation

There is an unavoidable mismatch: the host display has a physical DPR (typically 1.0–2.0 on
desktop) while the emulated device may have DPR 3.0+. We cannot make the GPU rasterize at a
higher DPR than the physical display, but we can give honest logical pixel sizes.

Strategy:
1. The `PreviewFlutterView` reports the emulated `devicePixelRatio`.
2. The physical rendering surface is the host window. We size the window so that the
   *logical* dimensions of the emulated device fit comfortably.
3. A `Transform.scale` is applied to the device frame widget to compensate for any
   letterboxing when the emulated logical size exceeds the available window space.
4. Developers should read the preview as representative of *layout* fidelity. Fine-grained
   pixel rendering (e.g. 1px borders that look hairline on a Retina display) will look
   slightly different from reality — this is documented and accepted.

### Window Sizing

When the user selects a device or toggles orientation:

1. Compute the desired window size: emulated logical size + frame chrome + toolbar height,
   scaled by a target fill factor (default 90% of available screen).
2. If the desired size fits, resize the window to match.
3. If it doesn't fit (e.g. large tablet on a small laptop), clamp to 90% of the screen and
   apply `Transform.scale` to fit the device frame within the window.
4. Per-device window sizes chosen by the user are remembered for the session.

Window resizing uses the `window_manager` package (`setSize`, `setMinimumSize`).

### Device Profile Database

A curated, hard-coded list of profiles covering:

- iPhone SE (small form factor baseline)
- iPhone 15 / 15 Pro (standard and Pro frame styles)
- iPhone 15 Pro Max
- Samsung Galaxy S24
- Google Pixel 8 / 8 Pro
- iPad mini
- iPad (standard)

Each profile contains:

```dart
class DeviceProfile {
  final String id;
  final String name;
  final DevicePlatform platform;     // iOS or android
  final Size logicalSize;            // portrait logical pixels
  final double devicePixelRatio;
  final EdgeInsets safeAreaPortrait;
  final EdgeInsets safeAreaLandscape;
  final DeviceFrameStyle frameStyle; // notch / dynamicIsland / punchHole / classic
  final ScreenCutout cutout;         // geometry of the camera cutout, if any
}
```

Profiles are versioned in the source and updated as new flagship devices ship.

### Screen Cutout Geometry

Physical cutouts (notches, Dynamic Islands, punch-holes) are modeled separately from the
safe area. The safe area tells the layout system where not to place content, but the cutout
geometry is needed to render the cutout shape honestly — so that background colors and
gradients that bleed under the status bar interact with the cutout visually, just as they
would on a real device. This is one of the more surprising gaps when moving from desktop
preview to a real device.

Cutout geometry is expressed in **screen coordinate space** — logical pixels from the
top-left corner of the screen area (not the outer device frame). This makes the coordinates
directly comparable to widget positions in the app.

```dart
sealed class ScreenCutout {
  const ScreenCutout();

  /// Returns the cutout geometry appropriate for landscape orientation.
  /// [portraitScreenSize] is the portrait logical screen size, used to
  /// compute the position of the cutout after the screen is rotated.
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) => this;
}

/// No cutout — large-bezel devices (iPhone SE, iPads).
final class NoCutout extends ScreenCutout {
  const NoCutout();
}

/// Wide notch at the top center — older iPhones (X–14), some Androids.
final class NotchCutout extends ScreenCutout {
  final Size size;

  /// Distance from the top edge of the screen area. Usually 0 (flush).
  final double topOffset;

  const NotchCutout({required this.size, this.topOffset = 0});

  @override
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) =>
      // Migrates to the left edge; width and height swap.
      _SideCutout(
        size: Size(size.height, size.width),
        edge: _CutoutEdge.left,
        centerOffset: portraitScreenSize.height / 2,
      );
}

/// Dynamic Island pill — iPhone 15 and later.
final class DynamicIslandCutout extends ScreenCutout {
  final Size size;
  final double topOffset;

  const DynamicIslandCutout({required this.size, required this.topOffset});

  @override
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) =>
      _SideCutout(
        size: Size(size.height, size.width),
        edge: _CutoutEdge.left,
        centerOffset: portraitScreenSize.height / 2,
      );
}

/// Small circular punch-hole camera — Pixel, Galaxy S series.
final class PunchHoleCutout extends ScreenCutout {
  final double diameter;
  final double topOffset;

  /// Horizontal center. Null means horizontally centered on the screen.
  final double? centerX;

  const PunchHoleCutout({
    required this.diameter,
    required this.topOffset,
    this.centerX,
  });

  @override
  ScreenCutout rotatedForLandscape(Size portraitScreenSize) {
    final cx = centerX ?? portraitScreenSize.width / 2;
    return _SideCutout(
      size: Size(diameter, diameter),
      edge: _CutoutEdge.left,
      centerOffset: cx,
      edgeOffset: topOffset,
    );
  }
}

/// Internal: a cutout on the left or right edge, produced by landscape rotation.
final class _SideCutout extends ScreenCutout {
  final Size size;
  final _CutoutEdge edge;
  final double centerOffset;
  final double edgeOffset;

  const _SideCutout({
    required this.size,
    required this.edge,
    required this.centerOffset,
    this.edgeOffset = 0,
  });
}

enum _CutoutEdge { left, right }
```

The `DeviceFramePainter` uses the cutout geometry in two ways:

1. **Clip path** — the cutout shape is subtracted from the screen rect using
   `canvas.clipPath`, so the app's own content is physically obscured by the cutout area
   rather than just overlaid. This ensures background colors and images interact with the
   cutout shape honestly.
2. **Frame decoration** — the cutout outline is painted in the frame's bezel color over
   the clip, giving it the appearance of a physical camera housing.

Cutout dimensions are approximate logical-pixel values sourced from manufacturer
specifications and may be off by a few points. This is consistent with the "pretty good,
few surprises" fidelity goal and is documented as an accepted limitation.

### UI Components

**Device Frame Widget** — a purely decorative `CustomPainter` that draws a phone/tablet
outline appropriate to the profile's `frameStyle`. It clips its child to the screen area,
subtracts the cutout shape from the clip path so the app content is honestly occluded by
the camera housing, and renders the status bar region as an inert graphic. No interactive
elements.

**Preview Toolbar** — a small floating pill widget anchored to the top-center of the window.
Contains:
- Device name + chevron → opens device picker popover
- Orientation toggle icon button
- Reassemble (hot reload) icon button
- Close / pass-through toggle

The toolbar is toggled with `Ctrl+\` (or `Cmd+\` on macOS). When hidden, only the
keyboard shortcut remains.

**Device Picker Popover** — a lightweight overlay listing available profiles, grouped by
platform. Keyboard-navigable.

**macOS Menu Bar** — on macOS, a `PlatformMenuBar` exposes device selection and orientation
toggle as native menu items, making the floating toolbar optional.

### Hot Reassemble

A "reassemble" button (and keyboard shortcut `Ctrl+R` / `Cmd+R`) calls
`BindingBase.reassembleApplication()`. This is the in-process rebuild — equivalent to the
widget rebuild phase of hot reload. It picks up changes to `StatelessWidget.build`,
theme data, and similar, without requiring Dart source recompilation.

This is distinct from a full hot reload (which requires the `flutter` tooling to recompile
sources). Full hot reload integration via the VM service is a Phase 3 consideration.

---

## Integration API

```dart
// In main.dart:
import 'package:bezel/bezel.dart';

void main() {
  // In debug mode: installs PreviewBinding, returns true.
  // In release/profile mode: no-op, returns false.
  Bezel.ensureInitialized();
  runApp(const MyApp());
}
```

No wrapper widget is required. The preview activates automatically in debug mode.
An optional `Bezel.configure(...)` call allows setting the default device profile
and whether the toolbar starts visible.

---

## File Structure

```
lib/
  bezel.dart          # public API surface
  src/
    binding/
      preview_binding.dart
      preview_platform_dispatcher.dart
      preview_flutter_view.dart
    devices/
      device_profile.dart
      screen_cutout.dart         # ScreenCutout sealed class hierarchy
      device_database.dart
    frame/
      device_frame_painter.dart
      frame_style.dart
    ui/
      preview_toolbar.dart
      device_picker.dart
      preview_overlay.dart       # orchestrates toolbar + frame
    window/
      window_manager.dart        # thin wrapper around package:window_manager
    hotreload/
      reassemble_service.dart
    preview_controller.dart      # ChangeNotifier: active profile, orientation, visibility
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `window_manager` | Programmatic window resize / positioning |
| `flutter_test` (dev) | Reference for TestFlutterView / TestPlatformDispatcher patterns |

Intentionally minimal. No state management packages — `ChangeNotifier` is sufficient.
The device frame painting is hand-rolled `CustomPainter`, not an image asset dependency.

---

## Accepted Limitations

- Font hinting and sub-pixel rendering will match the host display, not the emulated device
- Platform plugins (maps, camera, webviews) will receive the spoofed `FlutterView` metrics
  but their native rendering surfaces are unaffected
- Safe area insets are static per profile; dynamic changes (e.g. keyboard appearance) are
  not emulated
- Status bar content is decorative only
- Cutout dimensions (size, position) are approximate logical-pixel values sourced from
  manufacturer specifications; they may be off by a few points but are sufficient for
  catching layout surprises before on-device testing
