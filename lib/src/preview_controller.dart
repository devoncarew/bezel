import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/painting.dart' show EdgeInsets, Size;

import 'devices/device_database.dart';
import 'devices/device_profile.dart';

/// The single source of truth for the active device preview state.
///
/// Holds the active [DeviceProfile], screen [orientation], and toolbar
/// visibility. Widgets read state via [ListenableBuilder] or
/// [AnimatedBuilder]; the binding layer reacts to changes by re-reporting
/// spoofed metrics to the framework.
class PreviewController extends ChangeNotifier {
  DeviceProfile _activeProfile = DeviceDatabase.defaultProfile;
  DeviceOrientation _orientation = DeviceOrientation.portrait;
  bool _toolbarVisible = true;

  /// The currently active device profile.
  DeviceProfile get activeProfile => _activeProfile;

  /// The current screen orientation.
  DeviceOrientation get orientation => _orientation;

  /// Whether the preview toolbar is visible.
  bool get toolbarVisible => _toolbarVisible;

  /// The emulated logical screen size for the current profile and orientation.
  Size get emulatedLogicalSize =>
      _activeProfile.logicalSizeForOrientation(_orientation);

  /// The emulated safe area insets for the current profile and orientation.
  EdgeInsets get emulatedSafeArea =>
      _activeProfile.safeAreaForOrientation(_orientation);

  /// Switches to [profile] and notifies listeners.
  void setProfile(DeviceProfile profile) {
    if (_activeProfile == profile) return;
    _activeProfile = profile;
    notifyListeners();
  }

  /// Toggles between portrait and landscape and notifies listeners.
  void toggleOrientation() {
    _orientation = switch (_orientation) {
      DeviceOrientation.portrait => DeviceOrientation.landscape,
      DeviceOrientation.landscape => DeviceOrientation.portrait,
    };
    notifyListeners();
  }

  /// Toggles toolbar visibility and notifies listeners.
  void toggleToolbar() {
    _toolbarVisible = !_toolbarVisible;
    notifyListeners();
  }
}
