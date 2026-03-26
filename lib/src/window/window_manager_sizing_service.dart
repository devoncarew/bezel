import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:window_manager/window_manager.dart';

import '../devices/device_profile.dart';
import 'window_sizing_service.dart';

/// Extra horizontal padding added around the emulated logical size to
/// accommodate the device frame chrome on each side.
const double _kFramePadding = 80.0;

/// Extra vertical padding at the top for the floating toolbar (step 2.5).
const double _kToolbarHeight = 60.0;

/// Minimum window dimensions — prevents the window from shrinking to a
/// non-interactive size when a very small device profile is selected.
const ui.Size _kMinWindowSize = ui.Size(300.0, 400.0);

/// Production [WindowSizingService] backed by `window_manager`.
///
/// Awaits [_ready] before making any `window_manager` calls, so it is safe to
/// construct this service before [windowManager.ensureInitialized] resolves.
class WindowManagerSizingService implements WindowSizingService {
  const WindowManagerSizingService(this._ready);

  /// A [Future] that resolves once [windowManager.ensureInitialized] has
  /// completed. Typically `PreviewBinding` creates and holds this future.
  final Future<void> _ready;

  @override
  Future<void> applyProfile(
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) async {
    await _ready;

    final target = computeTargetSize(profile, orientation);
    final screen = _screenLogicalSize();

    final clamped = ui.Size(
      target.width.clamp(_kMinWindowSize.width, screen.width * 0.9),
      target.height.clamp(_kMinWindowSize.height, screen.height * 0.9),
    );

    await windowManager.setMinimumSize(_kMinWindowSize);
    await windowManager.setSize(clamped);
  }

  /// Computes the ideal window size for [profile] at [orientation] before
  /// screen-size clamping is applied.
  ///
  /// Exposed for unit testing without a real window.
  static ui.Size computeTargetSize(
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) {
    final emulated = profile.logicalSizeForOrientation(orientation);
    return ui.Size(
      emulated.width + _kFramePadding * 2,
      emulated.height + _kFramePadding + _kToolbarHeight,
    );
  }

  /// Returns the logical size of the display the app is currently on.
  ///
  /// Falls back to a safe default if the display is unavailable.
  static ui.Size _screenLogicalSize() {
    final display =
        WidgetsBinding.instance.platformDispatcher.implicitView?.display;
    if (display == null) return const ui.Size(1920, 1080);
    // display.size is in physical pixels; divide by DPR to get logical.
    return display.size / display.devicePixelRatio;
  }
}
