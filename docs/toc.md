# flight_check — Project Map

flight_check is a Flutter debug-only desktop tool for previewing apps against
mobile device profiles. It spoofs device metrics at the binding layer and
provides a minimal floating UI for device and orientation selection.

---

## Documentation

| File                                          | Summary                                                                                              |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [docs/design.md](design.md)                   | Full architecture: binding layer, DPR derivation, window sizing, UI components, accepted limitations |
| [docs/patterns.md](patterns.md)               | How-to: adding device profiles, modifying the binding, testing approach                              |
| [docs/devices.md](devices.md)                 | Device database: supported profiles, proxy groups, coverage gaps, verification status                |
| [docs/cutout-research.md](cutout-research.md) | Research: data sources for cutout geometry (AOSP XML, iOS Simulator `.simdevicetype` bundles)        |

---

## Code Structure

```
lib/
  flight_check.dart                      # public API — the only export surface
  src/
    binding/
      preview_binding.dart               # custom WidgetsFlutterBinding; installs dispatcher
      preview_platform_dispatcher.dart   # wraps real dispatcher; substitutes PreviewFlutterView
      preview_flutter_view.dart          # spoofs physicalSize, devicePixelRatio, padding, viewInsets
    devices/
      device_profile.dart                # DeviceProfile data class + DevicePlatform enum
      screen_border.dart                 # ScreenBorder sealed class (circular / squircle)
      screen_cutout.dart                 # ScreenCutout sealed hierarchy (NoCutout, DynamicIsland, PunchHole…)
      device_database.dart               # curated list of DeviceProfile instances
    frame/
      screen_clip_painter.dart           # CustomPainter: clips to rounded corners + cutout, fills black
      screen_clip_widget.dart            # widget wrapper for the screen clip
    persistence/
      device_persistence.dart            # saves/loads last-selected device ID to ~/.config/flight_check.json
    ui/
      control_badge.dart                 # top-right badge showing active device name
      control_panel.dart                 # slide-out device picker and shortcuts panel
      preview_overlay.dart               # orchestrates clip + badge + panel
      preview_shortcuts.dart             # keyboard shortcut bindings (Cmd+D/L/[/])
    window/
      window_sizing_service.dart         # interface for window resize operations
      window_manager_sizing_service.dart # implementation using window_manager package
    preview_controller.dart              # ChangeNotifier: active profile, orientation, visibility
    preview_real.dart                    # debug entry point (conditionally imported)
    preview_stub.dart                    # no-op stub for non-desktop / release targets
    theme.dart                           # shared colours and layout constants

example/                                 # runnable Flutter app for manual testing
test/                                    # unit and widget tests
tool/                                    # development utilities (screenshot tooling)
```

---

## Key Data Flow

```
[User selects device in control_panel]
        ↓
PreviewController.setDevice(profile)
        ↓
window_manager resizes OS window to emulated device size × 0.9
        ↓
[onMetricsChanged on real FlutterView]
        ↓
PreviewFlutterView recomputes physicalSize, devicePixelRatio, padding
        ↓
Flutter's _MediaQueryFromView derives correct MediaQueryData automatically
        ↓
app re-lays out at emulated logical size — no widget injection
```
