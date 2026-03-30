# Flight Check

Flight Check is a Flutter tool for previewing your app against popular mobile
devices. It lets you know what your app will look like at different screen sizes
without guesswork.

Binding layer emulation means `MediaQuery` and safe areas report what a real
device would. And Flight Check's architecture means that it's tree-shaken out in
release mode.

| iPhone 17 | Pixel 10 | Galaxy S24 |
|:---------:|:--------:|:----------:|
| ![iPhone 17](docs/images/iphone_17.png) | ![Pixel 10](docs/images/pixel_10.png) | ![Galaxy S24](docs/images/galaxy_s24.png) |

## Getting started

Add `flight_check` as a regular dependency:

```
flutter pub add flight_check
```

In your `main.dart`, call `FlightCheck.configure()` (**before** `runApp`):

```dart
import 'package:flight_check/flight_check.dart';

void main() {
  FlightCheck.configure();

  runApp(const MyApp());
}
```

Run your app on MacOS, Linux, or Windows and the preview UI appears
automatically. The call is a no-op in several situations, so you can leave it
in unconditionally:

- **Release / profile builds** — tree-shaken out at compile time
- **iOS / Android** — skipped at runtime so real-device debug sessions are
  unaffected
- **Flutter Web** — excluded via a conditional import

## WidgetsFlutterBinding.ensureInitialized()

If your app is already calling `WidgetsFlutterBinding.ensureInitialized()`,
place the call to `FlightCheck.configure()` before the `WidgetsFlutterBinding`
call; you'll want to initialize Flight Check first.

## Supported devices

| Device | Size | Platform | Device category |
| --- | --- | --- | --- |
| iPhone SE (3rd gen) | 375 × 667 | iOS | Flat-edge, no cutout, small screen — budget / upgrade path |
| iPhone 14 | 390 × 844 | iOS | Notch, 390 × 844 — covers iPhone 12, 13, 14 |
| iPhone 15 | 393 × 852 | iOS | Dynamic Island, 393 × 852 — proxy for iPhone 14 Pro, 15 Pro, 16, 16e, 17 |
| iPhone 15 Pro Max | 430 × 932 | iOS | Dynamic Island, 430 × 932 — covers iPhone 15 Plus, 16 Plus |
| iPhone 17 | 393 × 852 | iOS | Current standard iPhone, 393 × 852 — same geometry as iPhone 15 and 16 |
| iPhone 17 Pro Max | 440 × 956 | iOS | Largest iPhone screen, 440 × 956 |
| Samsung Galaxy A15 | 411 × 892 | Android | Budget Samsung Infinity-U notch, 411 × 892 — covers A15, A25 |
| Samsung Galaxy A55 | 384 × 854 | Android | Mid-range Samsung A-series, ~384 × 854 — covers A54, A55 |
| Samsung Galaxy S24 | 360 × 780 | Android | Flagship Samsung, 360 × 780 — covers S23, S24 |
| Google Pixel 7a | 411 × 914 | Android | Mid-range Pixel, small punch hole — covers Pixel 7a, 8, 8a |
| Google Pixel 10 | 411 × 923 | Android | Large punch hole, 411 × 923 — covers Pixel 9 and 10 |
| Google Pixel 10 Pro | 410 × 914 | Android | High-DPR Pixel (3.125), 410 × 914 |
| iPad mini (A17 Pro) | 744 × 1133 | iOS / tablet | Compact iPad, 744 × 1133 |
| iPad (A16) | 820 × 1180 | iOS / tablet | Standard iPad, 820 × 1180 |

## Keyboard shortcuts

| Action             | MacOS | Linux / Windows |
| ------------------ | ----- | --------------- |
| Toggle orientation | ⌘L    | Ctrl+L          |

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
Some known limitations:

- text-field keyboard shortcuts may not match the host keyboard when the host OS
  and emulated platform differ (e.g. Android on macOS)
- back-navigation assumptions (system back button on Android, swipe-back on iOS)
  cannot be satisfied on desktop
- switching emulator devices will trigger a framework reassemble, resetting
  ephemeral widget state

## License

BSD 3-Clause — see [LICENSE](LICENSE).
