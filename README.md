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

In your `main.dart`, call `Bezel.ensureInitialized()` **before** `runApp`:

```dart
import 'package:bezel/bezel.dart';

void main() {
  Bezel.ensureInitialized();

  runApp(const MyApp());
}
```

Run your app on macOS, Linux, or Windows and the preview UI appears
automatically. The call is a no-op in profile and release builds, so no code
change is needed before shipping.

## WidgetsFlutterBinding.ensureInitialized()

If your app is already calling `WidgetsFlutterBinding.ensureInitialized()`,
place the call to `Bezel.ensureInitialized()` before the `WidgetsFlutterBinding`
call; you'll want to initialize Bezel first (and, you'll want to keep the call
to WidgetsFlutterBinding so that your app keeps working in release mode).

## Keyboard shortcuts

| Action | MacOS | Linux / Windows |
| --- | --- | --- |
| Toggle toolbar | ⌘\\ | Ctrl+\\ |
| Toggle orientation | ⌘L | Ctrl+L |
| Reload | ⌘R | Ctrl+R |

## Supported devices

| Device | Platform | Logical size | DPR |
|---|---|---|---|
| iPhone SE (3rd gen) | iOS | 375 × 667 | 2.0 |
| iPhone 15 | iOS | 393 × 852 | 3.0 |
| iPhone 15 Pro | iOS | 393 × 852 | 3.0 |
| iPhone 15 Pro Max | iOS | 430 × 932 | 3.0 |
| iPad (10th gen) | iOS | 820 × 1180 | 2.0 |
| iPad mini (6th gen) | iOS | 744 × 1133 | 2.0 |
| Samsung Galaxy S24 | Android | 411 × 915 | 3.0 |
| Google Pixel 7a | Android | 411 × 914 | 2.625 |
| Google Pixel 8 | Android | 411 × 914 | 2.625 |
| Google Pixel 8 Pro | Android | 448 × 998 | 3.0 |

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

## License

BSD 3-Clause — see [LICENSE](LICENSE).
