import '../devices/device_profile.dart';

/// Resizes the desktop window to match an emulated device profile.
///
/// The production implementation ([WindowManagerSizingService]) uses the
/// `window_manager` package. Tests inject a mock at this boundary — do not
/// depend on `window_manager` in widget tests.
abstract interface class WindowSizingService {
  /// Resize the window to fit [profile] at [orientation].
  ///
  /// If the computed target size would exceed the available screen area the
  /// implementation must clamp to 90 % of that area. The overlay scale factor
  /// in [PreviewOverlay] handles the rest.
  Future<void> applyProfile(
    DeviceProfile profile,
    DeviceOrientation orientation,
  );
}
