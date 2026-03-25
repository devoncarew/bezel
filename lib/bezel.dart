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

// TODO: export src

/// Entry point for the bezel package.
///
/// Call [ensureInitialized] before [runApp] to activate the device preview.
/// In debug mode this installs [PreviewBinding]; in release/profile mode it
/// is a no-op and is tree-shaken out entirely.
abstract final class Bezel {
  /// Activates the bezel preview in debug mode.
  ///
  /// Safe to call in release/profile builds — the assert ensures the
  /// implementation is unreachable and tree-shaken out.
  static void ensureInitialized() {
    assert(() {
      _debugEnsureInitialized();
      return true;
    }());
  }
}

// Stub implementation until Step 1.7 wires up the real binding.
void _debugEnsureInitialized() {}
