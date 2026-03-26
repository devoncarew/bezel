import 'package:flutter/widgets.dart' show Widget, WidgetsFlutterBinding;

import '../preview_controller.dart';
import '../ui/preview_overlay.dart';
import 'preview_platform_dispatcher.dart';

/// A custom binding that installs [PreviewPlatformDispatcher], causing the
/// framework to receive spoofed device metrics for the active [DeviceProfile].
///
/// Installed by calling [ensureInitialized] before [runApp]. In release and
/// profile builds the call is inside an `assert`, so the binding — and all
/// preview code — is tree-shaken out entirely.
class PreviewBinding extends WidgetsFlutterBinding {
  PreviewBinding._();

  static PreviewBinding? _instance;

  final PreviewController _controller = PreviewController();

  // Mirrors the pattern used by TestWidgetsFlutterBinding.
  @override
  PreviewPlatformDispatcher get platformDispatcher => _previewDispatcher;

  late final PreviewPlatformDispatcher _previewDispatcher =
      PreviewPlatformDispatcher(super.platformDispatcher, _controller);

  /// The shared [PreviewController] for this session.
  ///
  /// Throws if [ensureInitialized] has not yet been called.
  static PreviewController get controller {
    assert(
      _instance != null,
      'PreviewBinding.ensureInitialized() must be called before accessing controller.',
    );
    return _instance!._controller;
  }

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
