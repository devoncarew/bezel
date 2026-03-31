/// Flight Check — Flutter debug-mode device preview tool.
///
/// Add two lines to your `main.dart`:
///
/// ```dart
/// import 'package:flight_check/flight_check.dart';
///
/// void main() {
///   FlightCheck.configure();
///
///   runApp(const MyApp());
/// }
/// ```
library;

import 'src/preview_controller.dart';
import 'src/preview_real.dart' if (dart.library.html) 'src/preview_stub.dart';

/// Entry point for the flight_check package.
///
/// Call [configure] before [runApp] to activate the device preview.
/// The call is a no-op — and safe to leave in unconditionally — in three cases:
///
/// - **Release / profile builds**: the `assert` wrapper tree-shakes out all
///   preview code at compile time.
/// - **Mobile targets (iOS / Android)**: checked at runtime so the tool never
///   interferes with real-device runs during development.
/// - **Flutter Web**: excluded via a conditional import.
abstract final class FlightCheck {
  /// Activates the Flight Check preview.
  ///
  /// Safe to call unconditionally — it is a no-op in release/profile builds,
  /// on iOS/Android devices, and on Flutter Web.
  static void configure() {
    assert(() {
      debugEnsureInitialized();
      return true;
    }());
  }

  /// The active [PreviewController] for the current session.
  ///
  /// Returns `null` in release/profile builds, on iOS/Android, on Flutter Web,
  /// or before [configure] has been called.
  static PreviewController? get controller {
    PreviewController? result;
    assert(() {
      result = debugController;
      return true;
    }());
    return result;
  }
}
