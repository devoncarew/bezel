# Bezel

A Flutter debug-mode tool for previewing your app against popular mobile device
profiles while running on desktop. It spoofs device metrics at the binding layer
— no widget injection — so `MediaQuery`, safe areas, and pixel ratios all report
what a real device would report.

## Getting started

Add `bezel` as a regular dependency:

```
flutter pub add bezel
```

In your `main.dart`, call `Bezel.configure()` **before** `runApp`:

```dart
import 'package:bezel/bezel.dart';

void main() {
  Bezel.configure();

  runApp(const MyApp());
}
```

Run your app on MacOS, Linux, or Windows and the preview UI appears
automatically. The call is a no-op in several situations, so you can leave it
in unconditionally:

- **Release / profile builds** — tree-shaken out at compile time.
- **iOS / Android** — skipped at runtime so real-device debug sessions are
  unaffected.
- **Flutter Web** — excluded via a conditional import.

## WidgetsFlutterBinding.ensureInitialized()

If your app is already calling `WidgetsFlutterBinding.ensureInitialized()`,
place the call to `Bezel.configure()` before the `WidgetsFlutterBinding`
call; you'll want to initialize Bezel first.

## Keyboard shortcuts

| Action | MacOS | Linux / Windows |
| --- | --- | --- |
| Toggle orientation | ⌘L | Ctrl+L |

## Supported devices

| Device | Platform | Logical size |
|---|---|---|
| iPhone SE (3rd gen) | iOS | 375 × 667 |
| iPhone 15 | iOS | 393 × 852 |
| iPhone 15 Pro | iOS | 393 × 852 |
| iPhone 15 Pro Max | iOS | 430 × 932 |
| iPad (10th gen) | iOS | 820 × 1180 |
| iPad mini (6th gen) | iOS | 744 × 1133 |
| Samsung Galaxy S24 | Android | 411 × 915 |
| Samsung Galaxy A15 | Android | 411 × 892 |
| Google Pixel 8a | Android | 411 × 914 |
| Google Pixel 9 | Android | 411 × 923 |
| Google Pixel 10 | Android | 411 × 923 |
| Google Pixel 10 Pro | Android | 410 × 914 |

## Known limitations

- Font hinting and sub-pixel rendering match the host display, not the emulated
  device.
- Platform plugins (maps, camera, webviews) receive spoofed `FlutterView`
  metrics but their native rendering surfaces are unaffected.
- Safe area insets are static per profile; dynamic changes such as keyboard
  appearance are not emulated.
- Cutout dimensions are approximate values sourced from manufacturer
  specifications; they may be off by a few points.
- `MediaQuery.devicePixelRatio` reflects the derived window DPR rather than the
  device's nominal DPR; apps that branch on this value may behave differently
  than on a real device.
- Flutter Web is not supported.

`defaultTargetPlatform` is overridden to match the emulated device's platform,
giving correct scroll physics, page transitions, and haptic feedback patterns.
Known limitations:

- text-field keyboard shortcuts may not match the host keyboard when the host OS
  and emulated platform differ (e.g. Android on macOS)
- back-navigation assumptions (system back button on Android, swipe-back on iOS)
  cannot be satisfied on desktop
- switching platforms triggers a reassemble that resets ephemeral widget state

## License

BSD 3-Clause — see [LICENSE](LICENSE).
