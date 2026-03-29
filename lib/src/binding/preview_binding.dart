import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/widgets.dart' show Widget, WidgetsFlutterBinding;
import 'package:window_manager/window_manager.dart';

import '../devices/device_database.dart';
import '../devices/device_profile.dart' show DeviceOrientation, DevicePlatform;
import '../persistence/device_persistence.dart';
import '../preview_controller.dart';
import '../ui/preview_overlay.dart';
import '../window/window_manager_sizing_service.dart';
import 'preview_platform_dispatcher.dart';

/// A custom binding that installs [PreviewPlatformDispatcher], causing the
/// framework to receive spoofed device metrics for the active [DeviceProfile].
///
/// Installed by calling [ensureInitialized] before [runApp]. The binding is
/// never installed in release/profile builds (tree-shaken out entirely) or
/// when running on a real mobile device (iOS/Android).
///
/// ## Platform emulation
///
/// In addition to spoofing screen metrics, the binding sets
/// [debugDefaultTargetPlatformOverride] to match the emulated device's
/// platform (iOS or Android). This gives "pretty good" platform fidelity:
///
/// **Works well:**
/// - Scroll physics: iOS gets elastic `BouncingScrollPhysics`; Android gets
///   `ClampingScrollPhysics` with a stretch/glow overscroll indicator.
/// - Page transitions: iOS uses the Cupertino slide-from-right transition;
///   Android uses the Material zoom transition.
/// - Haptic / sound feedback patterns.
/// - Text selection toolbar items (iOS adds "Look Up" / "Search Web"; Android
///   has different ordering and a Cut shortcut).
/// - `ThemeData` platform value — correct from startup because the override is
///   applied before `runApp`.
///
/// **Known fidelity limitations:**
/// - **Keyboard shortcuts**: `DefaultTextEditingShortcuts` maps Cmd+key for
///   iOS/macOS and Ctrl+key for Android/Linux/Windows. Overriding to Android
///   on macOS (or iOS on Linux/Windows) breaks text-field shortcuts, because
///   the shortcut set no longer matches the host keyboard.
/// - **Back navigation**: Android code assumes a system back button; iOS code
///   assumes a swipe-back gesture. Neither is available on desktop.
/// - **Visual density**: switching platforms triggers a reassemble so
///   `ThemeData` rebuilds, but any in-flight animations or ephemeral widget
///   state is reset.
/// - **Accessibility**: VoiceOver / TalkBack may receive semantics intended
///   for the other platform. Not a concern for a dev tool.
class PreviewBinding extends WidgetsFlutterBinding {
  // _controller must be a field declaration (not assigned in the constructor
  // body) so that it is available when super() calls initInstances(), which
  // accesses platformDispatcher → _previewDispatcher → _controller.
  final PreviewController _controller = PreviewController();

  PreviewBinding._() {
    // Constructor body runs after super()/initInstances(), so _controller is
    // already in use. Wire up the sizing service here — the service awaits its
    // own ready-future before making any window_manager calls.
    _controller.windowSizingService = WindowManagerSizingService(
      windowManager.ensureInitialized(),
    );

    // Restore the last-selected device and orientation, if any.
    final savedId = loadLastDeviceId();
    if (savedId != null) {
      final profile = DeviceDatabase.findById(savedId);
      if (profile != null) _controller.setProfile(profile);
    }
    final savedOrientation = loadLastOrientation();
    if (savedOrientation != null &&
        savedOrientation != _controller.orientation) {
      _controller.toggleOrientation();
    }

    // Apply the platform override now, before runApp, so that ThemeData is
    // constructed with the correct platform value from the start.
    _lastEmulatedPlatform = _controller.activeProfile.platform;
    _applyPlatformOverride(_lastEmulatedPlatform!);

    // React to controller changes: persist device ID and update platform.
    _controller.addListener(_onControllerChanged);
  }

  String? _lastSavedProfileId;
  DeviceOrientation? _lastSavedOrientation;
  DevicePlatform? _lastEmulatedPlatform;

  void _onControllerChanged() {
    // Persist device ID and orientation when either changes.
    final id = _controller.activeProfile.id;
    final orientation = _controller.orientation;
    if (id != _lastSavedProfileId || orientation != _lastSavedOrientation) {
      _lastSavedProfileId = id;
      _lastSavedOrientation = orientation;
      saveSettings(deviceId: id, orientation: orientation);
    }

    // Update the platform override when the emulated platform changes (e.g.
    // switching from an iOS device to an Android device). A reassemble is
    // required so that ThemeData — which caches `defaultTargetPlatform` at
    // construction time — rebuilds with the new platform value. This resets
    // ephemeral widget state (scroll positions, text field contents, etc.),
    // which is acceptable for a platform switch.
    final platform = _controller.activeProfile.platform;
    if (platform != _lastEmulatedPlatform) {
      _lastEmulatedPlatform = platform;
      _applyPlatformOverride(platform);
      reassembleApplication();
    }
  }

  /// Sets [debugDefaultTargetPlatformOverride] to match [platform].
  static void _applyPlatformOverride(DevicePlatform platform) {
    debugDefaultTargetPlatformOverride = switch (platform) {
      DevicePlatform.iOS => TargetPlatform.iOS,
      DevicePlatform.android => TargetPlatform.android,
    };
  }

  static PreviewBinding? _instance;

  // Mirrors the pattern used by TestWidgetsFlutterBinding.
  @override
  PreviewPlatformDispatcher get platformDispatcher => _previewDispatcher;

  late final PreviewPlatformDispatcher _previewDispatcher =
      PreviewPlatformDispatcher(super.platformDispatcher, _controller);

  /// The shared [PreviewController] for this session.
  ///
  /// Returns `null` if [ensureInitialized] has not been called, or was skipped
  /// because the app is running on a mobile platform.
  static PreviewController? get controller => _instance?._controller;

  /// Injects [PreviewOverlay] inside the [View] widget so that [LayoutBuilder]
  /// receives real layout constraints from the render tree.
  ///
  /// [attachRootWidget] is called with `View(child: app)` already assembled,
  /// so overriding it would place [PreviewOverlay] *above* the [View] — outside
  /// the render context. Overriding [wrapWithDefaultView] instead inserts the
  /// overlay as the direct child of [View], where it is laid out normally.
  @override
  Widget wrapWithDefaultView(Widget rootWidget) {
    return super.wrapWithDefaultView(
      PreviewOverlay(controller: _controller, child: rootWidget),
    );
  }

  /// Initialises the preview binding.
  ///
  /// Follows the same pattern as [WidgetsFlutterBinding.ensureInitialized].
  /// Safe to call multiple times — subsequent calls return the existing
  /// instance.
  static PreviewBinding ensureInitialized() {
    _instance ??= PreviewBinding._();
    return _instance!;
  }
}
