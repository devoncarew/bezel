# PLAN.md — bezel Implementation Plan

Each step is designed to be self-contained and completable by a coding agent in one pass.
Steps within a phase are ordered by dependency. Complete Phase 1 before starting Phase 2, etc.

A step is **done** when: the described files exist, `flutter analyze` is clean,
`dart format` reports no changes, and `flutter test` passes.

---

## Phase 1 — Foundation

### Step 1.1 — Package scaffold [done]

Created `pubspec.yaml` (`sdk: ^3.10.0`, `window_manager: ^0.5.1`), `analysis_options.yaml` with Flutter lints, the `lib/src/` directory skeleton, and a stub `lib/bezel.dart` barrel file. Added an `example/` Flutter desktop app that calls `Bezel.ensureInitialized()` before `runApp`.

### Step 1.2 — DeviceProfile model and ScreenCutout [done]

Created `lib/src/devices/screen_cutout.dart` with a sealed `ScreenCutout` hierarchy (`NoCutout`, `NotchCutout`, `DynamicIslandCutout`, `PunchHoleCutout`, `SideCutout`) where each type implements `rotatedForLandscape` to produce a left-edge `SideCutout`. Created `lib/src/devices/device_profile.dart` with `DeviceProfile` (const, all-final fields) and the `DevicePlatform`, `DeviceFrameStyle`, and `DeviceOrientation` enums, plus orientation-aware helpers for size, safe area, and cutout.

### Step 1.3 — Device database [done]

Created `lib/src/devices/device_database.dart` with 10 device profiles (iPhone SE 3rd gen, iPhone 15/15 Pro/15 Pro Max, iPad 10th gen, iPad mini 6th gen, Samsung Galaxy S24, Pixel 7a/8/8 Pro) with accurate logical-pixel sizes, DPRs, safe areas, and cutout geometry sourced from manufacturer specs. Added a `DeviceDatabase` class with `all`, `forPlatform`, `findById`, and `defaultProfile` (iPhone 15).

### Step 1.4 — PreviewController [done]

Created `lib/src/preview_controller.dart` — a `ChangeNotifier` that tracks `activeProfile`, `orientation`, and `toolbarVisible`, fires notifications on each mutation, and exposes `emulatedLogicalSize` and `emulatedSafeArea` as derived values.

### Step 1.5 — PreviewFlutterView [done]

Created `lib/src/binding/preview_flutter_view.dart` — a `ui.FlutterView` implementation that overrides `devicePixelRatio`, `physicalSize`, `padding`, `viewPadding`, and `viewInsets` with values derived from the active `DeviceProfile`, delegating all other members to the real view. Includes a private `_EdgeInsetsViewPadding` helper to adapt `EdgeInsets` to the `ui.ViewPadding` interface.

> **Note:** The current implementation computes `physicalSize = emulatedLogicalSize × profile.devicePixelRatio` — a deliberate simplification. DESIGN.md specifies a more accurate reactive model: `physicalSize` should stay as the real window's physical size and `devicePixelRatio` should be derived from it dynamically via an `onMetricsChanged` listener. Step 2.4 corrects this.

### Step 1.6 — PreviewPlatformDispatcher [done]

Created `lib/src/binding/preview_platform_dispatcher.dart` — a full `ui.PlatformDispatcher` implementation (~40 delegated members) that overrides `views` and `implicitView` to return a `PreviewFlutterView` wrapping the real view, while delegating all callbacks and other members to the real dispatcher.

### Step 1.7 — PreviewBinding [done]

Created `lib/src/binding/preview_binding.dart` — a `WidgetsFlutterBinding` subclass that overrides `platformDispatcher` to install `PreviewPlatformDispatcher` and exposes a static `ensureInitialized()` / `controller` API. Updated `lib/bezel.dart` to expose a `Bezel` class with `ensureInitialized()` and `controller` guarded by `assert`, using a conditional import to swap in a no-op web stub so all preview code is tree-shaken in release builds.

---

## Phase 2 — Visual Layer

### Step 2.1 — DeviceFramePainter (portrait, simplified shapes) [done]

Created `lib/src/frame/device_frame_painter.dart` — a `CustomPainter` that renders a dark rounded-rect device body with style-specific bezels and decorations (speaker slit + home button for `classic`), then applies `canvas.clipPath` to subtract the cutout shape from the screen area so the child widget's pixels are physically absent in the camera housing region. Exposes `DeviceFramePainter.screenRectForSize(Size, DeviceProfile, DeviceOrientation)` for use by the layout widget in step 2.2.

### Step 2.2 — DeviceFrameWidget [done]

Created `lib/src/frame/device_frame_widget.dart` — a `StatelessWidget` that uses `LayoutBuilder` to fill available space, computes the screen rect via `DeviceFramePainter.screenRectForSize`, and positions the child in a `Stack` with a `CustomPaint` painter and a `Positioned`+`ClipRect` child. The canvas clip from the painter is inherited by the child (cutout exclusion), and the `ClipRect` bounds the outer screen rect. Purely cosmetic — no metric spoofing.

### Step 2.3 — PreviewOverlay

Create `lib/src/ui/preview_overlay.dart`.

`class PreviewOverlay extends StatelessWidget` that wraps the app in the preview UI:
- Takes `Widget child` and `PreviewController controller`
- Uses `ListenableBuilder` to react to controller changes
- Computes a scale factor: if the emulated logical size fits within 90% of the window,
  scale is 1.0; otherwise scale is `min(availableWidth / emulatedWidth, availableHeight /
  emulatedHeight) * 0.9`
- Centers `DeviceFrameWidget` (scaled via `Transform.scale`) within the available space
- The toolbar is overlaid via a `Stack` (implemented as a placeholder `SizedBox` for now —
  toolbar comes in Step 2.5)

At this point the app should display inside a device frame. Wire it up in the `example`
app by having `PreviewBinding` install the overlay automatically via a
`WidgetsBinding.addPostFrameCallback` that wraps the root widget.

Consider the mechanism carefully: rather than wrapping `runApp`'s widget, install the
overlay as a sibling via `OverlayEntry` on the root `Navigator`, or — simpler — have
`PreviewBinding` override `attachRootWidget` to inject the overlay at the root.

### Step 2.4 — Window auto-sizing and reactive DPR

**Update `PreviewFlutterView`** to implement the reactive DPR model from DESIGN.md:

- Remove the `physicalSize` override — delegate to `_real.physicalSize` so the reported
  physical size matches the actual render surface.
- Subscribe to `_real.onMetricsChanged` and notify `PreviewController` listeners so the
  framework re-lays out when the window is resized.
- Compute `devicePixelRatio` reactively: `_real.physicalSize.width / emulatedLogicalWidth`.
  This keeps DPR in sync with whatever the window size actually is at any moment, including
  both programmatic resizes and manual user drags.

**Create `lib/src/window/window_sizing_service.dart`.**

`class WindowSizingService` that:
- Has a `void applyProfile(DeviceProfile profile, DeviceOrientation orientation)` method
- Computes target window size = emulated logical size + constant frame chrome padding
  (e.g. 80px each side for the frame, 60px top for toolbar)
- Queries the available screen size via `window_manager`'s `getScreenList()` /
  `getCurrentScreen()`
- If the target size fits within 90% of the screen, calls
  `windowManager.setSize(targetSize)` (takes logical pixels)
- If not, clamps to 90% of screen (the overlay scale factor handles the rest)
- Sets minimum window size to prevent nonsensical shrinking

Wire `WindowSizingService` into `PreviewController`: when `setProfile` or
`toggleOrientation` is called, call `windowSizingService.applyProfile(...)`.

Initialize `window_manager` in `PreviewBinding.ensureInitialized()` with
`windowManager.ensureInitialized()`.

### Step 2.5 — Preview toolbar

Create `lib/src/ui/preview_toolbar.dart`.

`class PreviewToolbar extends StatelessWidget` takes a `PreviewController`.

Renders a floating pill-shaped container with:
- Device name `Text` (truncated if needed) — tapping opens the device picker (Step 2.6)
- Orientation toggle `IconButton` (portrait/landscape icon)
- Reassemble `IconButton` (refresh icon) — calls
  `WidgetsBinding.instance.reassembleApplication()`
- Pass-through toggle `IconButton` — hides the device frame and shows the raw app at its
  natural window size, letting developers momentarily inspect the unframed layout; toggling
  again re-activates the preview. State lives in `PreviewController` (add a `passthroughMode`
  bool, similar to `toolbarVisible`).
- Uses `Material` + `InkWell` for press feedback
- Styled with a semi-transparent dark background, white icons/text, pill border radius

Position the toolbar at the top-center of the `PreviewOverlay`'s stack, with a small top
margin. It should float above the device frame.

### Step 2.6 — Device picker popover

Create `lib/src/ui/device_picker.dart`.

`class DevicePicker` — a static method `show(BuildContext context, PreviewController
controller)` that shows a `showDialog`-based popover (or `showMenu`) listing all devices
from `DeviceDatabase.all`, grouped under "iOS" and "Android" section headers.

Each item shows the device name. The active device is checkmarked. Tapping an item calls
`controller.setProfile(profile)` and closes the picker.

---

## Phase 3 — Polish and Power Features

### Step 3.1 — Keyboard shortcuts

Create `lib/src/ui/preview_shortcuts.dart`.

Wrap the `PreviewOverlay` content in a `Shortcuts` + `Actions` widget pair:
- `Ctrl+\` / `Cmd+\` → `controller.toggleToolbar()`
- `Ctrl+R` / `Cmd+R` → `WidgetsBinding.instance.reassembleApplication()`
- `Ctrl+L` / `Cmd+L` → `controller.toggleOrientation()`

Use `SingleActivator` with `meta` on macOS and `control` on other platforms, detected via
`defaultTargetPlatform`.

### Step 3.2 — macOS menu bar integration

Create `lib/src/ui/macos_menu.dart`.

`class MacosPreviewMenu extends StatelessWidget` — conditionally compiled for macOS only
via `if (Platform.isMacOS)`.

Uses `PlatformMenuBar` to add a "Preview" top-level menu with:
- Device submenu listing all `DeviceDatabase.all` profiles (checkmark on active)
- "Toggle Orientation" item with keyboard shortcut display
- "Reassemble" item

Integrate into `PreviewOverlay` as an additional root-level widget (macOS only).

### Step 3.3 — Smooth device transition animation

Update `PreviewOverlay` to animate between device profiles:

- Wrap `DeviceFrameWidget` in an `AnimatedContainer` for size changes
- Use `AnimatedSwitcher` with a fade + scale transition when the profile changes
- Duration: 250ms, curve: `Curves.easeInOut`

This is purely cosmetic — no logic changes.

### Step 3.4 — VM service hot-reload integration (optional / experimental)

Create `lib/src/hotreload/vm_reload_service.dart`.

`class VmReloadService`:
- In `init()`, obtain the VM service URI via `dart:developer`'s `Service.getInfo()`
- Connect to the VM service using `package:vm_service`
- Expose `Future<void> reload()` that:
  1. Calls `vmService.reloadSources(isolateId)` to recompile
  2. Calls `vmService.callServiceExtension('ext.flutter.reassemble', ...)`
- Expose `bool get isAvailable` — false if the VM service is not reachable

Add a dependency on `vm_service: ^14.0.0` in `pubspec.yaml`.

Wire this as an enhanced version of the reassemble button: if `VmReloadService.isAvailable`,
use the full reload path; otherwise fall back to in-process reassemble.

Add a note in the toolbar tooltip indicating which mode is active.

### Step 3.5 — README and example polish

Write `README.md`:
- One-paragraph description
- "Getting started" — the two lines needed in `main.dart`
- Keyboard shortcuts table
- Supported devices table (pulled from `DeviceDatabase`)
- Known limitations section (matching DESIGN.md)
- Screenshot or ASCII mockup of the toolbar

Polish `example/lib/main.dart` into a small but visually interesting demo app — a simple
profile card or settings screen — that exercises safe areas, scrolling, and responsive
layout, so it actually demonstrates the preview meaningfully.

---

## Phase ordering summary

| Phase | What you get |
|---|---|
| After Phase 1 | App runs inside a spoofed device environment; metrics are correct; no visual frame |
| After Phase 2 | Full visual — device frame, floating toolbar, device picker, auto window sizing |
| After Phase 3 | Keyboard shortcuts, macOS menu bar, animations, optional hot reload |
