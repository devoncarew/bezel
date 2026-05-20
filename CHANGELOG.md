## 1.2.1

- Add Google Pixel 10a profile (covers Pixel 9a and 10a; 44dp corner radius,
  411×923dp).
- Rename the `pixel_7a` profile to `pixel_8a` (id, name, and display name now
  reflect the latest in that series; geometry is unchanged).

## 1.2.0

- Require Flutter 3.44.0.
- Implement `FlutterView.displayCornerRadii` to spoof Android corner radii.
  Returns physical-pixel radii derived from the active profile's
  `CircularBorder` radius; returns `null` for iOS profiles, matching Android API
  31+ semantics.

## 1.1.0

- Added `shortName` field to `DeviceProfile` for compact display in the control
  badge (e.g. `'Pixel 10'` instead of `'Google Pixel 10'`). The badge shows the
  short name when the panel is closed, and the full name when it is open.
- Added brightness (dark/light) toggle to the control panel (`⌘B` / `Ctrl+B`).
  The emulated device always reports an explicit brightness — dark by default —
  independent of the host system setting. The choice persists between sessions.

## 1.0.0

Initial release of Flight Check — a Flutter debug-mode tool for previewing your
app against popular mobile device profiles while running on desktop.

Spoofs device metrics at the binding layer (logical size, safe area insets,
device pixel ratio) without injecting wrapper widgets. Auto-resizes the desktop
window to fit the emulated device and provides a floating badge + slide-out
panel for device selection and orientation toggle.

**Initial device profiles:**

- iPhone SE (3rd gen), iPhone 14, iPhone 15, iPhone 15 Pro Max
- iPhone 17, iPhone 17 Air, iPhone 17 Pro, iPhone 17 Pro Max
- Google Pixel 7a, Pixel 10, Pixel 10 Pro
- Samsung Galaxy A15, A16, A55, A56, S25, S26
- iPad mini (A17 Pro), iPad (A16)
