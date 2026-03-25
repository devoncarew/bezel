import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show EdgeInsets;

import '../preview_controller.dart';

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

  @override
  double get devicePixelRatio => _controller.activeProfile.devicePixelRatio;

  @override
  ui.Size get physicalSize =>
      _controller.emulatedLogicalSize *
      _controller.activeProfile.devicePixelRatio;

  @override
  ui.ViewPadding get padding =>
      _EdgeInsetsViewPadding(_controller.emulatedSafeArea);

  @override
  ui.ViewPadding get viewPadding =>
      _EdgeInsetsViewPadding(_controller.emulatedSafeArea);

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
