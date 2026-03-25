# PLAN.md — bezel Implementation Plan

Each step is designed to be self-contained and completable by a coding agent in one pass.
Steps within a phase are ordered by dependency. Complete Phase 1 before starting Phase 2, etc.

A step is **done** when: the described files exist, `flutter analyze` is clean,
`dart format` reports no changes, and `flutter test` passes.

---

## Phase 1 — Foundation

### Step 1.1 — Package scaffold [done]

Create the package directory structure and `pubspec.yaml`.

- `pubspec.yaml` with name `bezel`, sdk constraint `^3.3.0`, dependency on
  `window_manager: ^0.4.0`, and `flutter_test` as a dev dependency
- `lib/bezel.dart` — empty barrel file with a single `// TODO: export src`
  comment
- `lib/src/` directory with a `.gitkeep` placeholder
- `analysis_options.yaml` — enable `flutter` lints, add `avoid_print`,
  `prefer_const_constructors`, `prefer_final_fields`
- `example/` — a minimal Flutter desktop app (`example/lib/main.dart`) that imports
  `bezel` and calls `Bezel.ensureInitialized()` before `runApp`.
  The app body can be a simple `MaterialApp` with a `Scaffold` and a centered `Text`.
- `example/pubspec.yaml` with a path dependency on `..`

### Step 1.2 — DeviceProfile model and ScreenCutout [done]

Create `lib/src/devices/screen_cutout.dart`.

Implement the `ScreenCutout` sealed class hierarchy exactly as specified in DESIGN.md:
- `sealed class ScreenCutout` with abstract `rotatedForLandscape(Size portraitScreenSize)`
- `final class NoCutout extends ScreenCutout`
- `final class NotchCutout extends ScreenCutout` — `size`, `topOffset`
- `final class DynamicIslandCutout extends ScreenCutout` — `size`, `topOffset`
- `final class PunchHoleCutout extends ScreenCutout` — `diameter`, `topOffset`,
  optional `centerX` (null means horizontally centered)
- `final class _SideCutout extends ScreenCutout` (private) — produced by landscape
  rotation of the above types; fields: `size`, `edge` (`_CutoutEdge` enum), `centerOffset`,
  `edgeOffset`

The `rotatedForLandscape` implementations on each type should produce a `_SideCutout`
representing the cutout migrated to the left edge of the screen. The default implementation
on `ScreenCutout` returns `this` (correct for `NoCutout` and `_SideCutout`).

All constructors should be `const`. All fields `final`.

Create `lib/src/devices/device_profile.dart`.

- `enum DevicePlatform { iOS, android }`
- `enum DeviceFrameStyle { notch, dynamicIsland, punchHole, classic }`
- `enum DeviceOrientation { portrait, landscape }`
- `class DeviceProfile` with fields: `id`, `name`, `platform`, `logicalSize` (portrait),
  `devicePixelRatio`, `safeAreaPortrait`, `safeAreaLandscape`, `frameStyle`, `cutout`
  — all `final`, constructor `const`
- A `logicalSizeForOrientation(DeviceOrientation)` method that returns the `Size` with
  width and height swapped for landscape
- A `safeAreaForOrientation(DeviceOrientation)` method
- A `cutoutForOrientation(DeviceOrientation)` method — returns `cutout` for portrait,
  `cutout.rotatedForLandscape(logicalSize)` for landscape

Unit tests in `test/devices/device_profile_test.dart`:
- Orientation size swap
- Safe area selection for each orientation
- `cutoutForOrientation` returns `NoCutout` unchanged, and correctly rotates a
  `PunchHoleCutout` and `DynamicIslandCutout` for landscape
- `rotatedForLandscape` on a `PunchHoleCutout` with no `centerX` computes the landscape
  `centerOffset` as `portraitScreenSize.width / 2`

### Step 1.3 — Device database [done]

Create `lib/src/devices/device_database.dart`.

Populate a `const List<DeviceProfile> kDeviceProfiles` with the following devices. Look up
current accurate values for logical size, DPR, safe areas, and cutout geometry for each.
Cutout dimensions should be in logical pixels, sourced from manufacturer specs.

- iPhone SE (3rd gen) — `frameStyle: classic`, `cutout: NoCutout()`
- iPhone 15 — `frameStyle: dynamicIsland`,
  `cutout: DynamicIslandCutout(size: Size(37, 12), topOffset: 14)`
- iPhone 15 Pro — `frameStyle: dynamicIsland`, same cutout as iPhone 15
- iPhone 15 Pro Max — `frameStyle: dynamicIsland`, same cutout scaled for larger screen
- iPad (10th gen) — `frameStyle: classic`, `cutout: NoCutout()`
- iPad mini (6th gen) — `frameStyle: classic`, `cutout: NoCutout()`
- Samsung Galaxy S24 — `frameStyle: punchHole`,
  `cutout: PunchHoleCutout(diameter: 10, topOffset: 12)` (centered)
- Google Pixel 8 — `frameStyle: punchHole`,
  `cutout: PunchHoleCutout(diameter: 11, topOffset: 13)` (centered)
- Google Pixel 8 Pro — `frameStyle: punchHole`, same cutout as Pixel 8

Verify the logical-pixel values above against current specs before committing; treat them
as approximate starting points, not authoritative values.

Add a `DeviceDatabase` class with:
- `static List<DeviceProfile> all` — returns `kDeviceProfiles`
- `static List<DeviceProfile> forPlatform(DevicePlatform)` — filtered list
- `static DeviceProfile? findById(String id)`
- `static DeviceProfile get defaultProfile` — returns iPhone 15

Unit tests in `test/devices/device_database_test.dart` covering `forPlatform`,
`findById` (found and not-found), that `defaultProfile` is in `all`, and that every profile
in `all` has a non-null `cutout` (i.e. no profile accidentally omits the field).

### Step 1.4 — PreviewController [done]

Create `lib/src/preview_controller.dart`.

`class PreviewController extends ChangeNotifier` with:
- `DeviceProfile activeProfile` — starts as `DeviceDatabase.defaultProfile`
- `DeviceOrientation orientation` — starts as `portrait`
- `bool toolbarVisible` — starts as `true`
- `void setProfile(DeviceProfile profile)` — sets profile, notifies
- `void toggleOrientation()` — flips orientation, notifies
- `void toggleToolbar()` — flips visibility, notifies
- `Size get emulatedLogicalSize` — delegates to
  `activeProfile.logicalSizeForOrientation(orientation)`
- `EdgeInsets get emulatedSafeArea` — delegates to
  `activeProfile.safeAreaForOrientation(orientation)`

Unit tests in `test/preview_controller_test.dart` verifying notification firing on each
mutation and correct derived values for both orientations.

### Step 1.5 — PreviewFlutterView [done]

Create `lib/src/binding/preview_flutter_view.dart`.

`class PreviewFlutterView implements ui.FlutterView` that:
- Takes a `ui.FlutterView _real` and a `PreviewController _controller` in its constructor
- Overrides `devicePixelRatio` → `_controller.activeProfile.devicePixelRatio`
- Overrides `physicalSize` →
  `_controller.emulatedLogicalSize * _controller.activeProfile.devicePixelRatio`
- Overrides `padding` → derive a `ui.ViewPadding` from `_controller.emulatedSafeArea`
  (implement a private helper `_EdgeInsetsViewPadding implements ui.ViewPadding`)
- Overrides `viewPadding` → same as `padding`
- Overrides `viewInsets` → `ui.ViewPadding.zero`
- Delegates every other member to `_real`

Note: `ui.ViewPadding` is an abstract interface. Create `_EdgeInsetsViewPadding` as a
private implementation class that wraps an `EdgeInsets`.

Unit tests in `test/binding/preview_flutter_view_test.dart`:
- Verify `physicalSize` equals `logicalSize * dpr` for a known profile
- Verify `devicePixelRatio` returns the profile's value
- Verify `padding.top` returns the profile's safe area top

### Step 1.6 — PreviewPlatformDispatcher

Create `lib/src/binding/preview_platform_dispatcher.dart`.

`class PreviewPlatformDispatcher implements ui.PlatformDispatcher` that:
- Takes `ui.PlatformDispatcher _real` and `PreviewController _controller`
- Maintains a `late PreviewFlutterView _previewView` initialized lazily from
  `_real.views.first`
- Overrides `views` to return `[_previewView]`
- Overrides `implicitView` to return `_previewView`
- Delegates all other members to `_real`

Important: `ui.PlatformDispatcher` has many members (callbacks, onXxx handlers, etc.).
Every one must be delegated. Use the real dispatcher's implementation for all callbacks —
the preview view just wraps the real one, it doesn't replace it.

No unit tests needed at this layer — integration is tested via the binding step.

### Step 1.7 — PreviewBinding

Create `lib/src/binding/preview_binding.dart`.

`class PreviewBinding extends WidgetsFlutterBinding` that:
- Overrides `createPlatformDispatcher()` to return a `PreviewPlatformDispatcher` wrapping
  `super.createPlatformDispatcher()` and the shared `PreviewController`
- Exposes a static `PreviewController get controller`
- Provides `static PreviewBinding ensureInitialized()` following the standard Flutter
  binding initialization pattern

Create `lib/src/bezel.dart` with the real implementation:

```dart
void debugEnsureInitialized() => PreviewBinding.ensureInitialized();
```

Create `lib/src/bezel.dart` with a no-op stub:

```dart
void debugEnsureInitialized() {}
```

Update `lib/bezel.dart` to export a `Bezel` class with:
```dart
static void ensureInitialized() {
  assert(() { debugEnsureInitialized(); return true; }());
}
static PreviewController? get controller => ...
```

Using a conditional export for the impl vs stub based on `dart.library.html`.

Verify manually that the `example` app launches on desktop with no errors.

---

## Phase 2 — Visual Layer

### Step 2.1 — DeviceFramePainter (portrait, simplified shapes)

Create `lib/src/frame/frame_style.dart` (re-export of the enum, already defined in
`device_profile.dart` — move it here and re-export from `device_profile.dart` if cleaner).

Create `lib/src/frame/device_frame_painter.dart`.

`class DeviceFramePainter extends CustomPainter` that accepts a `DeviceProfile` and
`DeviceOrientation` and paints a simplified but recognizable device frame:

- **All styles**: a rounded-rect outer body in a neutral dark color, a lighter inner screen
  rect (the "hole" the app renders into), thin bezels
- **`classic`**: home button indicator at the bottom (small rounded rect), top speaker slit
- **`dynamicIsland`**: pill-shaped cutout centered at the top of the screen area
- **`punchHole`**: small circle cutout top-center of the screen area
- **`notch`**: classic notch shape at the top

**Cutout rendering** — for each non-`NoCutout` profile, the painter must:
1. Call `profile.cutoutForOrientation(orientation)` to get the correctly rotated
   `ScreenCutout` value
2. Build a `Path` for the cutout shape (rounded rect for Dynamic Island / notch, circle
   for punch-hole, using the cutout's logical-pixel geometry offset by `screenRect.topLeft`)
3. Use `canvas.clipPath` to subtract the cutout from the drawable screen area before
   painting the app content region — this ensures the app's background and any content
   bleeding under the status bar is genuinely occluded by the cutout, not just overlaid
4. Paint the cutout outline in the frame's bezel color on top, giving it the appearance
   of a physical camera housing

The clip path approach (step 3) is important: it means the widget child rendered inside the
screen area will have its pixels physically absent in the cutout region, which is how a
real device behaves and is what reveals layout issues that a simple overlay would hide.

The painter should expose a static `Rect screenRectForSize(Size painterSize, DeviceProfile,
DeviceOrientation)` method that returns the exact `Rect` within which the app content should
render. This is used by the layout widget to position the app.

Widget test in `test/frame/device_frame_painter_test.dart`: render each frame style in a
`CustomPaint` widget and verify that `screenRectForSize` returns a rect contained within
the painter bounds and has correct aspect ratio for the profile. Also verify that profiles
with `NoCutout` do not apply a clip path (inspect the canvas calls or simply ensure no
exception is thrown for all four frame styles).

### Step 2.2 — DeviceFrameWidget

Create `lib/src/frame/device_frame_widget.dart`.

`class DeviceFrameWidget extends StatelessWidget` that:
- Takes `DeviceProfile`, `DeviceOrientation`, and `Widget child`
- Uses a `LayoutBuilder` to get the available size
- Computes the screen rect via `DeviceFramePainter.screenRectForSize`
- Uses a `Stack` with a `CustomPaint` (the frame) and a `Positioned` child constrained
  to the screen rect
- Clips the child to the screen rect using `ClipRect`

Note: the cutout clip is applied by `DeviceFramePainter` directly to the canvas (via
`canvas.clipPath`), so the `ClipRect` here only clips to the outer screen rect boundary.
The two clips compose correctly — no additional cutout handling is needed in this widget.

The widget does **not** do any metric spoofing — it is purely cosmetic framing.

Widget test: verify the child is constrained to a rect with the correct aspect ratio.

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

### Step 2.4 — Window auto-sizing

Create `lib/src/window/window_sizing_service.dart`.

`class WindowSizingService` that:
- Has a `void applyProfile(DeviceProfile profile, DeviceOrientation orientation)` method
- Computes target window size = emulated logical size + constant frame chrome padding
  (e.g. 80px each side for the frame, 60px top for toolbar)
- Queries the available screen size via `window_manager`'s `getScreenList()` /
  `getCurrentScreen()`
- If the target size fits within 90% of the screen, calls
  `windowManager.setSize(targetSize)`
- If not, clamps to 90% of screen (the overlay scale factor handles the rest)
- Sets minimum window size to prevent nonsensical shrinking

Wire `WindowSizingService` into `PreviewController`: when `setProfile` or
`toggleOrientation` is called, call `windowSizingService.applyProfile(...)`.

Initialize `window_manager` properly in `PreviewBinding.ensureInitialized()` with
`windowManager.ensureInitialized()`.

### Step 2.5 — Preview toolbar

Create `lib/src/ui/preview_toolbar.dart`.

`class PreviewToolbar extends StatelessWidget` takes a `PreviewController`.

Renders a floating pill-shaped container with:
- Device name `Text` (truncated if needed) — tapping opens the device picker (Step 2.6)
- Orientation toggle `IconButton` (portrait/landscape icon)
- Reassemble `IconButton` (refresh icon) — calls
  `WidgetsBinding.instance.reassembleApplication()`
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
