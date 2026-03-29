import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' show Offset, WidgetsBinding;
import 'package:window_manager/window_manager.dart';

import '../devices/device_profile.dart';
import '../theme.dart';
import 'window_sizing_service.dart';

/// Minimum window dimensions — prevents the window from shrinking to a
/// non-interactive size when a very small device profile is selected.
const ui.Size _kMinWindowSize = ui.Size(300.0, 400.0);

/// Production [WindowSizingService] backed by `window_manager`.
///
/// Awaits [_ready] before making any `window_manager` calls, so it is safe to
/// construct this service before [windowManager.ensureInitialized] resolves.
class WindowManagerSizingService implements WindowSizingService {
  WindowManagerSizingService(this._ready);

  /// A [Future] that resolves once [windowManager.ensureInitialized] has
  /// completed. Typically `PreviewBinding` creates and holds this future.
  final Future<void> _ready;

  DeviceOrientation? _lastOrientation;

  /// Saved window positions, keyed by orientation.
  ///
  /// Populated when the user switches orientation so that switching back
  /// restores the window to where it was before.
  final Map<DeviceOrientation, Offset> _savedPositions = {};

  @override
  Future<void> applyProfile(
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) async {
    await _ready;

    final titleBarHeight = await windowManager.getTitleBarHeight();
    final bottomControlsHeight =
        kPreviewSpacing + kToolbarHeight + kPreviewPadding;
    // The window size includes the title bar; account for it and the bottom
    // toolbar area.
    final heightAdjust = titleBarHeight + bottomControlsHeight;

    final target = computeTargetSize(profile, orientation);
    final screen = _screenLogicalSize();
    final maxHeight = screen.height * 0.9;

    var actual = ui.Size(target.width, target.height + heightAdjust);
    if (actual.height > maxHeight) {
      final availableDeviceHeight = maxHeight.truncateToDouble() - heightAdjust;
      actual = ui.Size(
        target.width * availableDeviceHeight / target.height,
        availableDeviceHeight + heightAdjust,
      );
    }

    // Capture position and size before resizing so we can detect docking and
    // save position for orientation restore.
    final pos = await windowManager.getPosition();
    final oldSize = await windowManager.getSize();

    final orientationChanged =
        _lastOrientation != null && _lastOrientation != orientation;

    // Before switching orientation, save the current position so we can
    // restore it if the user switches back.
    if (orientationChanged) {
      _savedPositions[_lastOrientation!] = pos;
    }

    await windowManager.setMinimumSize(_kMinWindowSize);
    await windowManager.setSize(actual);

    final maxLeft = screen.width - actual.width;
    final maxTop = screen.height - actual.height;

    final Offset newPos;
    final savedPos = orientationChanged ? _savedPositions[orientation] : null;
    if (savedPos != null) {
      // Restore the saved position for this orientation, clamped to screen.
      newPos = Offset(
        savedPos.dx.clamp(0.0, maxLeft),
        savedPos.dy.clamp(0.0, maxTop),
      );
    } else {
      // If the window's right edge was flush with the screen's right edge
      // (within a small tolerance), keep it docked there after the resize.
      const kDockTolerance = 2.0;
      final dockedRight =
          (pos.dx + oldSize.width - screen.width).abs() <= kDockTolerance;
      newPos = Offset(
        dockedRight ? maxLeft : pos.dx.clamp(0.0, maxLeft),
        pos.dy.clamp(0.0, maxTop),
      );
    }

    if (newPos != pos) {
      await windowManager.setPosition(newPos);
    }

    _lastOrientation = orientation;
  }

  /// Computes the ideal window size for [profile] at [orientation] before
  /// screen-size clamping is applied.
  ///
  /// Window width matches the emulated logical width exactly (no bezel padding).
  /// Window dimensions match the emulated logical size exactly.
  ///
  /// Exposed for unit testing without a real window.
  static ui.Size computeTargetSize(
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) {
    final emulated = profile.logicalSizeForOrientation(orientation);

    // We can scale this one of three ways:
    // - at 1.0: logical pixels on the device are logical pixels on the
    //   screen; this works, but large devices clamp and we lose proportionality
    // - at 0.9: device proportionality is retained; most large devices don't
    //   need to clamp
    // - at device physical size: calculate the pixels / inch for the host
    //   screen and pixels / inch for the target device

    const double scale = 0.9;

    return ui.Size(emulated.width * scale, emulated.height * scale);
  }

  /// Returns the logical size of the display the app is currently on.
  ///
  /// Falls back to a safe default if the display is unavailable.
  static ui.Size _screenLogicalSize() {
    final display =
        WidgetsBinding.instance.platformDispatcher.implicitView?.display;
    if (display == null) {
      return const ui.Size(1920, 1080);
    }

    // display.size is in physical pixels; divide by DPR to get logical.
    return display.size / display.devicePixelRatio;
  }
}
