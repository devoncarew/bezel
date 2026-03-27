import 'package:flutter/widgets.dart' show Widget, WidgetsFlutterBinding;
import 'package:window_manager/window_manager.dart';

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
