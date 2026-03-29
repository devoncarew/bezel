# PLAN.md — flight_check Implementation Plan

Each step is designed to be self-contained and completable by a coding agent in one pass.
Steps within a phase are ordered by dependency. Complete Phase 1 before starting Phase 2, etc.

A step is **done** when: the described files exist, `flutter analyze` is clean,
`dart format` reports no changes, and `flutter test` passes.

---

## Phase 1 — Foundation

### Step 1.1 — Package scaffold [done]

Created `pubspec.yaml`, `analysis_options.yaml`, the `lib/src/` skeleton, and a stub
`lib/flight_check.dart` barrel file. Added an `example/` Flutter desktop app that calls
`FlightCheck.configure()` before `runApp`.

### Step 1.2 — DeviceProfile model and ScreenCutout [done]

Created a sealed `ScreenCutout` hierarchy and `DeviceProfile` (const, all-final fields)
with `DevicePlatform`, `DeviceFrameStyle`, and `DeviceOrientation` enums plus
orientation-aware helpers for size, safe area, and cutout.

### Step 1.3 — Device database [done]

Created `DeviceDatabase` with 10 device profiles (iPhone SE through Pixel 8 Pro) with
accurate logical-pixel sizes, DPRs, safe areas, and cutout geometry; exposes `all`,
`forPlatform`, `findById`, and `defaultProfile` (iPhone 15).

### Step 1.4 — PreviewController [done]

Created `PreviewController` — a `ChangeNotifier` that tracks `activeProfile`,
`orientation`, `toolbarVisible`, `passthroughMode`, and `devicePickerVisible`, with
derived `emulatedLogicalSize` and `emulatedSafeArea`.

### Step 1.5 — PreviewFlutterView [done]

Created `PreviewFlutterView` — a `ui.FlutterView` that overrides `devicePixelRatio`,
`physicalSize`, `padding`, `viewPadding`, and `viewInsets` with values derived from the
active `DeviceProfile`, delegating all other members to the real view.

### Step 1.6 — PreviewPlatformDispatcher [done]

Created `PreviewPlatformDispatcher` — a `ui.PlatformDispatcher` that overrides `views`
and `implicitView` to return a `PreviewFlutterView`, delegating everything else to the
real dispatcher.

### Step 1.7 — PreviewBinding [done]

Created `PreviewBinding` — a `WidgetsFlutterBinding` subclass that installs
`PreviewPlatformDispatcher` and exposes `configure()` / `controller`; updated
`flight_check.dart` to use a conditional import so all preview code is tree-shaken in release.

---

## Phase 2 — Visual Layer

### Step 2.1 — DeviceFramePainter (portrait, simplified shapes) [done]

Created `DeviceFramePainter` — a `CustomPainter` that renders a dark rounded-rect device
body with style-specific bezels and uses `canvas.clipPath` to cut out the camera area;
exposes `screenRectForSize` for the layout widget.

### Step 2.2 — DeviceFrameWidget [done]

Created `DeviceFrameWidget` — a `StatelessWidget` that uses `LayoutBuilder` to fill
available space, computes the screen rect via `DeviceFramePainter.screenRectForSize`, and
positions the child behind a `CustomPaint` layer with cutout clipping.

### Step 2.3 — PreviewOverlay [done]

Created `PreviewOverlay` — installed via `PreviewBinding.wrapWithDefaultView`, it wraps
the app in a dark background with a centered, scaled `DeviceFrameWidget`, a floating
toolbar, and a full-screen device picker layer.

### Step 2.4 — Window auto-sizing and reactive DPR [done]

Made `physicalSize` delegate to the real view and `devicePixelRatio` compute reactively
from the real window width. Created `WindowSizingService` / `WindowManagerSizingService`
to resize the desktop window to fit the emulated device on profile or orientation changes.

### Step 2.5 — Preview toolbar [done]

Created `PreviewToolbar` — a pill-shaped floating widget with a device name button
(opens picker), orientation toggle, reassemble button, and passthrough-mode toggle; styled
with a semi-transparent dark background.

### Step 2.6 — Device picker popover [done]

Created `DevicePicker` — an inline `Stack` overlay (no `Navigator`/`Overlay` ancestor)
showing iOS and Android profiles grouped under section headers, with checkmark on the
active profile; tap-outside dismisses via `HitTestBehavior.opaque`.

---

## Phase 3 — Polish and Power Features

### Step 3.1 — Keyboard shortcuts [done]

Created `PreviewShortcuts` — wraps the overlay in `Shortcuts` + `Actions` with
`ToggleToolbarIntent` (⌘/Ctrl+\\), `ToggleOrientationIntent` (⌘/Ctrl+L), and
`ReassembleIntent` (⌘/Ctrl+R); modifier key chosen via `defaultTargetPlatform`.

### Step 3.2 — macOS menu bar integration [done]

Created `MacosPreviewMenu` — a `StatefulWidget` that installs a native `PlatformMenuBar`
on macOS with a "Preview" menu containing a "Device" submenu (iOS/Android groups with ✓
on the active profile), "Toggle Orientation" (⌘L), and "Reload" (⌘R); only rebuilds the
menus list when the active profile changes to avoid dismissing an open menu.

### Step 3.3 — Smooth device transition animation [no longer planned]

Update `PreviewOverlay` to animate between device profiles.

### Step 3.4 — VM service hot-reload integration (experimental) [on hold]

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

### Step 3.5 — README polish [done]

Wrote `README.md` with a one-paragraph description, getting-started snippet, keyboard
shortcuts table, supported devices table, and known limitations section sourced from
`DESIGN.md`.

---

## Phase 4 — Refinement

Feedback-driven improvements to the controls, rendering fidelity, and window sizing after
initial MVP usage.

### Step 4.1 — Add `screenCornerRadius` to DeviceProfile, remove `DeviceFrameStyle` [done]

Added `screenCornerRadius` (double, logical pixels) to `DeviceProfile` and removed
`DeviceFrameStyle` enum and `frameStyle` field; updated all 10 device profiles with
per-device corner radius values (annotated with data sources), and updated the painter to
infer classic vs modern layout from the `ScreenCutout` type.

### Step 4.2 — Remove device frame body/bezels, clip at corners and cutouts [done]

Refactor `DeviceFramePainter`:
- Remove the device body rect (dark rounded rect), bezel padding (`_bezelsFor`), and
  classic decorations (speaker slit, home button).
- Screen rect = full painter bounds (no bezel deflation).
- Clip content at rounded screen corners using the profile's `screenCornerRadius`.
- Clip cutout regions from the canvas and fill with black.

Update `DeviceFrameWidget` — `screenRectForSize` returns full bounds, child positioning
simplifies. Consider renaming both files since they no longer paint a "device frame".

### Step 4.3 — Move toolbar to bottom, make compact [done]

In `PreviewOverlay`, move the toolbar `Positioned` from `top: 8` to `bottom: 8`. The
toolbar sits below the emulated content area, in the background/letterbox region.

In `PreviewToolbar`, reduce vertical padding to make it shorter while keeping the pill
shape and current button set.

Update device picker positioning if needed. Update tests.

### Step 4.4 — Update window sizing [done]

In `WindowManagerSizingService`:
- Remove `_kFramePadding` (no bezels).
- Window width = emulated logical width.
- Window height = emulated logical height + toolbar area height.
- DPR = host DPR (natural result of window width matching emulated width).

Add bounds logic:
- If window exceeds screen dimensions, reduce to fit.
- If window position would place part of it off the right edge or bottom of the screen,
  reposition the window to stay fully visible.

Update `computeTargetSize` and tests.

### Step 4.5 — Update overlay layout for aspect-ratio scaling [done]

Update `PreviewOverlay`:
- Content area = available space minus toolbar height at bottom.
- Scale emulated content to fill content area, maintaining aspect ratio.
- Letterbox with background color (#4A4A52) on the dimension that doesn't fill.
- Toolbar floats at bottom of window.

Update `computeScale` for the new layout (no frame padding, toolbar at bottom). Update
tests.

### Step 4.6 — Update device profiles with accurate geometry [done]

**Android (Pixel):** Extract cutout geometry and screen corner radii from AOSP device tree
configs (`config_mainBuiltInDisplayCutout`, `config_mainDisplayShape`). Convert physical
pixel coordinates to logical pixels by dividing by the device's DPR. See
`docs/notch-research.md` for sources and conversion examples.

**Android (Samsung):** Keep community-approximated values. Annotate as approximate in
source.

**iOS:** Update with community-measured cutout dimensions and corner radii (useyourloaf.com,
iosresolution.com). Dynamic Island dimensions from community measurements (~126×37pt pill).

Add source comments in `device_database.dart` for each profile's data provenance.

### Step 4.7 — Platform emulation [done]

`PreviewBinding` sets `debugDefaultTargetPlatformOverride` to match the emulated
device's platform (iOS → `TargetPlatform.iOS`, Android → `TargetPlatform.android`).
Applied before `runApp` so `ThemeData` is constructed with the correct platform from
the start. A `reassembleApplication()` call is triggered when switching between
platforms so `ThemeData` rebuilds.

**What works well:** scroll physics (elastic vs clamping), page transitions (Cupertino
slide vs Material zoom), haptic feedback patterns, text-selection toolbar items,
`VisualDensity`.

**Known limitations (documented in `DESIGN.md`):** keyboard shortcuts may break when
the host OS and emulated platform differ; back-navigation platform assumptions cannot
be satisfied on desktop; platform switch resets ephemeral widget state via reassemble.

### Step 4.8 — General cleanup

+ Find a list of the most commonly used mobile devices and compare that to the
  devices we ship with
+ Remove DeviceProfile.devicePixelRatio.
+ Experiment with a neumorphic design and fixed padding around the emulation
  area.
+ Renamed `FlightCheck.ensureInitialized()` => `FlightCheck.configure()`.
+ Consider having the currently selected device persist.
+ Have a script which will update the readme from the device database.
+ Add a 'similarTo' field to the DeviceProfile class.
+ Update the code to generate the device list in the readme.
+ Finish valdating the devices.
+ Add iPhone 17
+ Rename from 'Bezel' to 'Flight Check' / flight_check.
+ Change the device picker to use a tabbed UI.
+ Improve window position management.
- Consider updating sizing logic so the emulator approximates a physical device.
- Consider a locale override.

---

## Phase 5 — iOS screen geometry fidelity (issue #63)

Apple uses continuous-curvature (squircle/superellipse) corners on all iPhone
displays, and the pre-Dynamic Island notch shape is also a squircle-cornered
Bézier path. This phase improves rendering fidelity for iOS devices.

### Step 5.1 — Update iPhone corner radii in the device database [done]

The current `screenCornerRadius` values (all 44pt) are a stale community
approximation. Update them to Simulator-measured tangent points from
`docs/notch-research.md`. These are still circular-arc radii (not squircles),
but they are significantly closer to reality.

- iPhone 12–14 family (390 × 844): 44pt → **53pt**
- iPhone 15–16 family (393 × 852): 44pt → **61pt**
- iPhone 17 Pro Max (440 × 956): 44pt → **69pt**

### Step 5.2 — Introduce `ScreenBorder` sealed class; replace `screenCornerRadius` [done]

Replace `DeviceProfile.screenCornerRadius: double` with a sealed `ScreenBorder`
type. Android and iPad devices use `CircularBorder(radius: ...)`. iOS devices
remain on `CircularBorder` for now, ready to be upgraded to `SquircleBorder`
once Bézier control points are extracted in step 5.4.

### Step 5.3 — Enhance `extract_simdevicetype.dart` to output Bézier control points

Extend the tool to parse `c` (curveto) commands in the corner region of the
framebuffer PDF and print the Bézier control points for one corner (top-left),
normalized to logical points. Also extract the iPhone 14 notch Bézier path from
the sensor bar PDF.

### Step 5.4 — Populate `SquircleBorder` for iOS devices; implement rendering

With control points from step 5.3, populate `SquircleBorder` entries for each
iPhone family. Implement path building in `ScreenClipPainter`: reflect/rotate
one corner's Bézier points to all four corners.

### Step 5.5 — iPhone 14 notch: `PathCutout` class and rendering

Add a `PathCutout` variant to `ScreenCutout` that stores raw Bézier segments
from the sensor bar PDF. Implement rendering in `ScreenClipPainter`. Replace
the `TeardropCutout` on `iphone_14` with a `PathCutout`.
