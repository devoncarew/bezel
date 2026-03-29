# Contributing to Flight Check

Thank you for your interest in contributing! This document covers how to get
started, how to submit changes, and the standards we apply to pull requests.

---

## Getting started

1. **Fork** the repository and clone your fork.
2. Make sure you have a recent Flutter SDK installed (`flutter --version`).
3. Run the example app to confirm everything builds:
   ```
   cd example
   flutter run -d macos
   ```
4. Run the test suite from the package root:
   ```
   flutter test
   ```
5. Check analysis and formatting:
   ```
   flutter analyze
   dart format --set-exit-if-changed .
   ```
   All three must be clean before a pull request is accepted.

---

## Submitting a pull request

- Keep PRs focused. One logical change per PR makes review easier.
- Write a clear description: what changed and why.
- Add or update tests for any behaviour you add or change.
- All CI checks (analyze, format, test) must pass.
- The project uses `final` everywhere applicable and `const` constructors
  throughout — please follow the same style. See [CLAUDE.md](CLAUDE.md) for
  full code style guidance.

---

## Reporting bugs

Open a GitHub issue. Include:
- Flutter and Dart SDK versions (`flutter --version`)
- Host OS and version
- What you expected vs. what you saw
- Steps to reproduce, or a minimal reproduction

---

## Adding a new device

Device profiles live in
[`lib/src/devices/device_database.dart`](lib/src/devices/device_database.dart).
Before a new profile can be merged, all of the following must be **manually
verified** against a physical device, the iOS Simulator, or the Android
Emulator — whichever is appropriate for the platform.

Use the `example/` app to check flight_check's reported values. The **Device Info
drawer** (tap the hamburger menu) shows the logical screen size, DPR, and
safe-area insets as flight_check reports them to the app.

### Verification checklist

For each new device, confirm all six items and note the verification source
(physical device, iOS Simulator model name, or Android Emulator AVD name) in
the pull request description.

- [ ] **Logical screen resolution** — the reported width × height (in logical
      pixels) matches the device spec.
- [ ] **Safe area — portrait** — top, bottom, left, and right insets match
      what a Flutter app sees on the real device or simulator in portrait
      orientation.
- [ ] **Safe area — landscape** — same check in landscape orientation.
- [ ] **Cutout — portrait** — the notch, Dynamic Island, or punch-hole is
      clipped at the correct position and has the correct shape and size.
- [ ] **Cutout — landscape** — the cutout migrates to the correct edge with
      the correct position and shape after rotation.
- [ ] **Screen corner radius** — rounded corners clip at the right radius; no
      content is unexpectedly hidden or visible past the screen edge.

### How to verify

1. Run the example app in flight_check targeting the new device profile.
2. Open the iOS Simulator (for iOS) or Android Emulator (for Android) for the
   same device, and run the same example app there.
3. Compare the **Device Info drawer** values between flight_check and the
   simulator/emulator.
4. Visually confirm the cutout shape and position in both orientations.
5. Update the **Verified** column in [`docs/devices.md`](docs/devices.md) once
   the profile passes all checks. Record any discrepancies as follow-up issues.

### Data sources

Preferred sources for cutout geometry and corner radii:

- **Android (Pixel):** AOSP device tree XML —
  `config_mainBuiltInDisplayCutout` and `config_mainDisplayShape`.
  Convert physical-pixel coordinates to logical pixels by dividing by the
  device DPR.
- **Android (Samsung and others):** Community measurements.
  Samsung does not publish device-tree cutout configs; annotate values as
  approximate in the source comment.
- **iOS:** Community-measured values from sources such as
  useyourloaf.com and iosresolution.com.

Add a source comment to each profile explaining where the cutout geometry and
corner radius came from. See existing entries in `device_database.dart` for
the expected style.

---

## Questions

Open a GitHub Discussion or file an issue — we're happy to help.
