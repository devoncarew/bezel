import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/painting.dart' show EdgeInsets, Size;

import 'devices/device_database.dart';
import 'devices/device_profile.dart';
import 'window/window_sizing_service.dart';

/// The single source of truth for the active device preview state.
///
/// Holds the active [DeviceProfile], screen [orientation], and toolbar
/// visibility. Widgets read state via [ListenableBuilder] or
/// [AnimatedBuilder]; the binding layer reacts to changes by re-reporting
/// spoofed metrics to the framework.
class PreviewController extends ChangeNotifier {
  PreviewController({WindowSizingService? windowSizingService})
    : _windowSizingService = windowSizingService;

  WindowSizingService? _windowSizingService;

  /// Installs the [WindowSizingService] after construction.
  ///
  /// Called by [PreviewBinding] once `window_manager` is ready. Must only be
  /// called once.
  set windowSizingService(WindowSizingService service) {
    assert(_windowSizingService == null, 'windowSizingService already set');
    _windowSizingService = service;
  }

  DeviceProfile _activeProfile = DeviceDatabase.defaultProfile;
  DeviceOrientation _orientation = DeviceOrientation.portrait;

  bool _passthroughMode = false;
  bool _devicePickerVisible = false;

  /// The currently active device profile.
  DeviceProfile get activeProfile => _activeProfile;

  /// The current screen orientation.
  DeviceOrientation get orientation => _orientation;

  /// Whether passthrough mode is active.
  ///
  /// When true, the device frame is hidden and the app is shown at its natural
  /// window size. Toggling back to false re-activates the preview.
  bool get passthroughMode => _passthroughMode;

  /// Whether the device picker is currently open.
  bool get devicePickerVisible => _devicePickerVisible;

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
    _windowSizingService?.applyProfile(profile, _orientation);
  }

  /// Toggles between portrait and landscape and notifies listeners.
  void toggleOrientation() {
    _orientation = switch (_orientation) {
      DeviceOrientation.portrait => DeviceOrientation.landscape,
      DeviceOrientation.landscape => DeviceOrientation.portrait,
    };
    notifyListeners();
    _windowSizingService?.applyProfile(_activeProfile, _orientation);
  }

  /// Called by the binding layer when window metrics change (e.g. window
  /// resize). Notifies listeners so that [ListenableBuilder] widgets rebuild
  /// in response to window-size changes, in addition to controller-state
  /// changes.
  void notifyMetricsChanged() => notifyListeners();

  /// Toggles passthrough mode and notifies listeners.
  void togglePassthrough() {
    _passthroughMode = !_passthroughMode;
    notifyListeners();
  }

  /// Toggles the device picker visibility and notifies listeners.
  void toggleDevicePicker() {
    _devicePickerVisible = !_devicePickerVisible;
    notifyListeners();
  }
}
