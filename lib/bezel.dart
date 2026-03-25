/// Bezel — Flutter debug-mode device preview tool.
///
/// Add two lines to your `main.dart`:
/// ```dart
/// import 'package:bezel/bezel.dart';
///
/// void main() {
///   Bezel.ensureInitialized();
///   runApp(const MyApp());
/// }
/// ```
library;

import 'src/preview_controller.dart';
import 'src/preview_real.dart' if (dart.library.html) 'src/preview_stub.dart';

/// Entry point for the bezel package.
///
/// Call [ensureInitialized] before [runApp] to activate the device preview.
/// In debug mode this installs [PreviewBinding]; in release/profile mode it
/// is a no-op and is tree-shaken out entirely.
abstract final class Bezel {
  /// Activates the bezel preview in debug mode.
  ///
  /// Safe to call in release/profile builds — the assert ensures the
  /// implementation is unreachable and tree-shaken out entirely.
  static void ensureInitialized() {
    assert(() {
      debugEnsureInitialized();
      return true;
    }());
  }

  /// The active [PreviewController] for the current session.
  ///
  /// Returns `null` in release/profile builds or before [ensureInitialized]
  /// has been called.
  static PreviewController? get controller {
    PreviewController? result;
    assert(() {
      result = debugController;
      return true;
    }());
    return result;
  }
}
