# flight_check — Design Document

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

**2. Minimal chrome.** The UI surface is a small floating toolbar at the bottom of the
window. No device case rendering, no drawers, no settings panels, no plugin slots. Everything
non-essential is behind a keyboard shortcut or omitted entirely.

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

- `physicalSize` — computed from the emulated logical size × derived DPR
- `devicePixelRatio` — derived from the available window area and the emulated logical size
  (see DPR section below)
- `padding` / `viewPadding` / `viewInsets` — the profile's safe area insets
- Everything else delegated to the real view

This means `_MediaQueryFromView` (Flutter's internal widget that populates `MediaQuery` from
the view) automatically derives correct `MediaQueryData` without any widget injection. Code
that bypasses MediaQuery and reads `View.of(context)` directly also sees consistent values.

### Platform Emulation

When a device profile is selected, `PreviewBinding` sets
`debugDefaultTargetPlatformOverride` to match the profile's platform (iOS or Android). This
gives correct scroll physics, page transitions, haptic feedback patterns, and theme
behavior (Material vs Cupertino). The override is applied before `runApp` so that the widget
tree initializes with the right platform from the start.

Switching profiles triggers a reassemble that resets ephemeral widget state, which is the
same behavior as hot reload.

Known limitation: text-field keyboard shortcuts may not match the host keyboard when host OS
and emulated platform differ (e.g. Android profile on macOS); back-navigation expectations
(Android system back, iOS swipe-back) cannot be satisfied on desktop.

### Device Pixel Ratio and Window Sizing

`physicalSize`, `logicalSize`, and `devicePixelRatio` are not three independent values —
they are bound by the identity:

```
physicalSize = logicalSize × devicePixelRatio
```

`physicalSize` is fixed by the actual OS window; it is the real render surface and cannot
be freely spoofed without causing rendering artifacts. This means **DPR is a derived value,
not a design choice**: given a window of known physical dimensions and a target emulated
logical size, DPR follows automatically.

```dart
// After the window resize settles:
final hostDpr = realView.devicePixelRatio;          // e.g. 2.0 on Retina
final windowLogicalWidth = windowSize.width;         // logical px passed to setSize()
final physicalWidth = windowLogicalWidth * hostDpr;  // actual physical pixels
final reportedDpr = physicalWidth / emulatedLogicalWidth;
```

Note that `window_manager`'s `setSize()` takes **logical pixels** (OS window coordinates),
not physical pixels, so the host DPR must be factored in when computing the reported DPR.

`PreviewFlutterView` listens to `realView.onMetricsChanged` and recomputes `devicePixelRatio`
on every event, keeping it in sync with whatever the window actually is at any moment — both
after programmatic resizes and after manual user resizes.

**What DPR affects in practice:**

The goal of emulating logical pixel dimensions is what matters most for catching layout
issues. DPR has minimal impact on layout:

- Widget sizing, constraints, flex/scroll layout, `MediaQuery.size` — all logical,
  completely DPR-independent.
- Image asset resolution selection — at a typical desktop DPR of 2.0 the preview loads
  2× assets even when the real device would load 3×. The visual difference is negligible
  and is not a layout concern.
- `MediaQuery.devicePixelRatio` — apps that branch on this value (uncommon) will see the
  derived value rather than the device's nominal DPR. This is an accepted limitation.
- Custom `Canvas` painting in physical pixels — hairline strokes and pixel-snapped geometry
  will reflect the host display's DPR. Not a layout issue.

### Window Sizing

When the user selects a device or toggles orientation, the window is resized to show the
emulated device at 90% of its logical pixel dimensions:

1. Compute the target emulated area: `emulatedLogicalSize × 0.9`.
2. Compute the full window height: emulated height + toolbar area
   (`kPreviewSpacing + kToolbarHeight + kPreviewPadding`).
3. If the window height would exceed 90% of the screen height, scale down proportionally
   to fit.
4. If the computed window position would place part of it off the right edge or bottom of
   the screen, reposition the window to stay fully visible.

**Reactive data flow — the same path for both programmatic and manual resizes:**

```
[device selected or orientation toggled]
        ↓
compute target window size (emulated logical size × 0.9 + toolbar height)
        ↓
windowManager.setSize(targetLogicalSize)
        ↓                                     ← also fires on manual resize
[onMetricsChanged on real FlutterView]
        ↓
PreviewFlutterView recomputes:
  physicalSize  = emulatedLogicalSize × devicePixelRatio
  devicePixelRatio = physicalSize.width / emulatedLogicalWidth
        ↓
Flutter re-lays out app at emulatedLogicalSize with updated DPR
```

**Manual resize behavior:** when the user drags the window to a different size, the emulated
logical dimensions remain fixed. The emulated content scales uniformly to fill as much of
the available space as possible while maintaining the correct aspect ratio. Letterboxing
(the background color) appears on the dimension that doesn't fill. The toolbar remains at
the bottom of the window. The preview does **not** reflow the app into the new window
dimensions — that would break the "I'm emulating this specific device" premise.

### Device Profile Database

A curated, hard-coded list of profiles selected by market share data: the devices that
collectively represent the widest share of real-world usage. The goal is not exhaustive
coverage but a small set of profiles that catches the most layout surprises — different
screen sizes, aspect ratios, safe area shapes, and cutout styles. Tablets are included for
the distinct form-factor constraints they impose.

See [`docs/devices.md`](docs/devices.md) for the full coverage document: current profiles,
proxy groups, verification status, and coverage gaps.

Each profile contains:

```dart
class DeviceProfile {
  final String id;                    // e.g. 'iphone_15'
  final String name;                  // e.g. 'iPhone 15'
  final DevicePlatform platform;      // iOS or android
  final Size logicalSize;             // portrait logical pixels
  final EdgeInsets safeAreaPortrait;
  final EdgeInsets safeAreaLandscape;
  final double screenCornerRadius;    // logical pixels; 0 = square corners
  final ScreenCutout cutout;          // camera cutout geometry
  final bool tablet;
  final String? description;          // short proxy-group description
}
```

Profiles are versioned in the source and updated as new flagship devices ship. The
`devicePixelRatio` is not stored — it is derived from the window dimensions at runtime
(see DPR section above).

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
sealed class ScreenCutout { ... }

final class NoCutout extends ScreenCutout { ... }
  // Large-bezel devices: iPhone SE, iPads.

final class NotchCutout extends ScreenCutout {
  final Size size;
  final double topOffset;   // Usually 0 (flush to top edge).
}
  // Wide notch: iPhone X–14, some Androids.

final class DynamicIslandCutout extends ScreenCutout {
  final Size size;
  final double topOffset;
}
  // Pill-shaped cutout: iPhone 15 and later.

final class PunchHoleCutout extends ScreenCutout {
  final double diameter;
  final double topOffset;
  final double? centerX;    // Null = horizontally centered.
}
  // Small circular hole: Pixel, Galaxy S series.

final class SideCutout extends ScreenCutout {
  final Size size;
  final double centerOffset;
  final double edgeOffset;
}
  // Left-edge cutout produced by landscape rotation; not set directly.
```

The screen clip painter uses the cutout geometry in two ways:

1. **Clip path** — the cutout shape is subtracted from the screen rect using
   `canvas.clipPath`, so the app's own content is physically obscured by the cutout area
   rather than just overlaid. This ensures background colors and images interact with the
   cutout shape honestly.
2. **Black fill** — the cutout region is filled with black, giving it the appearance of a
   physical camera housing or sensor bar.

The screen is also clipped at rounded corners using the profile's `screenCornerRadius`,
so the background color shows through where a real device's screen would end.

Cutout dimensions are approximate logical-pixel values. For Android (Pixel) devices,
values are sourced from AOSP device tree configuration (`config_mainBuiltInDisplayCutout`),
converted from physical pixels to logical pixels via the device's DPR. For iOS and other
devices, values are community-measured approximations. Data sources are annotated per
profile in `device_database.dart`.

### UI Components

**Screen Clip Widget** — clips the app content to the device's screen shape: rounded
corners (using `screenCornerRadius`) and cutout regions. Cutouts are filled with black.
No decorative device body or bezels are rendered — the emulated content fills the available
area directly, with the preview background color visible through clipped corners.

**Preview Toolbar** — a compact floating pill widget anchored to the bottom-center of the
window, below the emulated content area. Contains:

- Device name + chevron → opens device picker
- Orientation toggle icon button
- Passthrough mode toggle (hides the device frame entirely)

The toolbar is toggled with `Ctrl+\` (or `Cmd+\` on macOS). When hidden, only the
keyboard shortcut remains.

**Device Picker** — a lightweight overlay card with three tabs (iOS, Android, Tablets)
listing available profiles. Opens to the tab of the currently active device. Tapping
outside the card or selecting a device closes it.

**macOS Menu Bar** — on macOS, a `PlatformMenuBar` exposes device selection and orientation
toggle as native menu items, making the floating toolbar optional.

### Persistence

The last-selected device ID is saved to a JSON file so the same device is restored on next
launch:

- macOS / Linux: `$HOME/.config/flight_check.json`
- Windows: `%APPDATA%\flight_check.json`

Persistence failures are silently ignored — it is a convenience feature, not a correctness
requirement.

### Hot Reassemble

A keyboard shortcut (`Ctrl+R` / `Cmd+R`) calls `BindingBase.reassembleApplication()`. This
is the in-process rebuild — equivalent to the widget rebuild phase of hot reload. It picks
up changes to `StatelessWidget.build`, theme data, and similar, without requiring Dart
source recompilation.

---

## Integration API

```dart
// In main.dart:
import 'package:flight_check/flight_check.dart';

void main() {
  // In debug mode: installs PreviewBinding, returns true.
  // In release/profile mode: no-op, returns false.
  FlightCheck.configure();
  runApp(const MyApp());
}
```

No wrapper widget is required. The preview activates automatically in debug mode.

---

## File Structure

```
lib/
  flight_check.dart         # public API surface
  src/
    binding/
      preview_binding.dart
      preview_platform_dispatcher.dart
      preview_flutter_view.dart
    devices/
      device_profile.dart
      screen_cutout.dart    # ScreenCutout sealed class hierarchy
      device_database.dart
    frame/
      screen_clip_painter.dart  # clips screen to rounded corners + cutouts, fills black
      screen_clip_widget.dart   # wraps app content in the screen clip
    persistence/
      device_persistence.dart   # saves/loads last-selected device ID
    ui/
      common.dart               # shared widgets (RaisedSurface neumorphic container)
      preview_overlay.dart      # orchestrates device clip + toolbar + picker
      preview_toolbar.dart
      device_picker.dart
      preview_shortcuts.dart    # keyboard shortcut bindings
      macos_menu.dart           # PlatformMenuBar for macOS
    window/
      window_sizing_service.dart
      window_manager_sizing_service.dart
    preview_controller.dart     # ChangeNotifier: active profile, orientation, visibility
    preview_real.dart           # debug-mode entry point (imported conditionally)
    preview_stub.dart           # no-op stub for non-desktop targets
    theme.dart                  # shared colours and layout constants
```

---

## Dependencies

| Package | Purpose |
| --- | --- |
| `window_manager` | Programmatic window resize / positioning |

Intentionally minimal. No state management packages — `ChangeNotifier` is sufficient.
The screen clipping is hand-rolled `CustomPainter`, not an image asset dependency.

---

## Accepted Limitations

- Font hinting and sub-pixel rendering will match the host display, not the emulated device
- Platform plugins (maps, camera, webviews) will receive the spoofed `FlutterView` metrics
  but their native rendering surfaces are unaffected
- Safe area insets are static per profile; dynamic changes (e.g. keyboard appearance) are
  not emulated
- Cutout dimensions and screen corner radii are approximate; may be off by a few logical
  pixels but sufficient for catching layout surprises before on-device testing
- `MediaQuery.devicePixelRatio` reflects the derived window DPR, not the device's nominal
  DPR; apps that branch on this value may behave differently than on a real device
- Text-field keyboard shortcuts may not match the host keyboard when host OS and emulated
  platform differ (e.g. Android profile on macOS)
- Back-navigation expectations (Android system back, iOS swipe-back) cannot be satisfied
  on desktop
- Switching platforms performs a framework reassemble that resets ephemeral widget state
