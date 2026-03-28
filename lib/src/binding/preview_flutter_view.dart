import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show EdgeInsets;

import '../preview_controller.dart';
import '../theme.dart' show kPreviewPadding, kToolbarHeight;

/// A [ui.FlutterView] that reports spoofed metrics for the active device
/// profile, delegating everything else to the real underlying view.
///
/// Installed by [PreviewPlatformDispatcher]. The framework's
/// `_MediaQueryFromView` widget reads from this view, so spoofing here
/// propagates correct [MediaQueryData] to the widget tree without any widget
/// injection.
class PreviewFlutterView implements ui.FlutterView {
  PreviewFlutterView(this._real, this._controller);

  final ui.FlutterView _real;
  final PreviewController _controller;

  // ── Spoofed members ───────────────────────────────────────────────────────

  /// Returns a DPR scaled to the area the emulator can actually draw into.
  ///
  /// Subtracts the overlay chrome (padding + toolbar) from the real physical
  /// window size before dividing by the emulated logical size. This matches the
  /// window sizing formula in [WindowManagerSizingService.computeTargetSize],
  /// so the emulator fills the available space at exactly the right scale.
  @override
  double get devicePixelRatio {
    final realDpr = _real.devicePixelRatio;
    final available = ui.Size(
      _real.physicalSize.width - 2 * kPreviewPadding * realDpr,
      _real.physicalSize.height -
          (3 * kPreviewPadding + kToolbarHeight) * realDpr,
    );
    return math.min(
      available.width / _controller.emulatedLogicalSize.width,
      available.height / _controller.emulatedLogicalSize.height,
    );
  }

  /// Reports the emulated device's physical dimensions at the current effective
  /// DPR, decoupling the app's logical layout from the actual window size.
  ///
  /// Both axes use the same DPR (derived from the width), so the app always
  /// sees exactly [PreviewController.emulatedLogicalSize] regardless of how
  /// the window is resized. Resizing changes the DPR only — content does not
  /// reflow.
  @override
  ui.Size get physicalSize {
    final dpr = devicePixelRatio;
    return ui.Size(
      _controller.emulatedLogicalSize.width * dpr,
      _controller.emulatedLogicalSize.height * dpr,
    );
  }

  @override
  ui.ViewPadding get padding {
    final dpr = devicePixelRatio;
    return _EdgeInsetsViewPadding(_controller.emulatedSafeArea * dpr);
  }

  @override
  ui.ViewPadding get viewPadding {
    final dpr = devicePixelRatio;
    return _EdgeInsetsViewPadding(_controller.emulatedSafeArea * dpr);
  }

  @override
  ui.ViewPadding get viewInsets => ui.ViewPadding.zero;

  // ── Delegated members ─────────────────────────────────────────────────────

  @override
  ui.PlatformDispatcher get platformDispatcher => _real.platformDispatcher;

  @override
  ui.ViewConstraints get physicalConstraints => _real.physicalConstraints;

  @override
  ui.ViewPadding get systemGestureInsets => _real.systemGestureInsets;

  @override
  ui.GestureSettings get gestureSettings => _real.gestureSettings;

  @override
  List<ui.DisplayFeature> get displayFeatures => _real.displayFeatures;

  @override
  int get viewId => _real.viewId;

  @override
  ui.Display get display => _real.display;

  @override
  void render(ui.Scene scene, {ui.Size? size}) =>
      _real.render(scene, size: size);

  @override
  void updateSemantics(ui.SemanticsUpdate update) =>
      _real.updateSemantics(update);
}

/// Adapts a Flutter [EdgeInsets] to the [ui.ViewPadding] interface.
final class _EdgeInsetsViewPadding implements ui.ViewPadding {
  const _EdgeInsetsViewPadding(this._insets);

  final EdgeInsets _insets;

  @override
  double get left => _insets.left;

  @override
  double get top => _insets.top;

  @override
  double get right => _insets.right;

  @override
  double get bottom => _insets.bottom;
}
