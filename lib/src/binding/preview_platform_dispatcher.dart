import 'dart:isolate' show SendPort;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'preview_flutter_view.dart';
import '../preview_controller.dart';

/// A [ui.PlatformDispatcher] that replaces the implicit view with a
/// [PreviewFlutterView] so that spoofed device metrics propagate through the
/// framework automatically.
///
/// All members except [views], [view], and [implicitView] are delegated to
/// [_real].
class PreviewPlatformDispatcher implements ui.PlatformDispatcher {
  PreviewPlatformDispatcher(this._real, this._controller);

  final ui.PlatformDispatcher _real;
  final PreviewController _controller;

  late final PreviewFlutterView _previewView = PreviewFlutterView(
    _real.views.first,
    _controller,
  );

  // ── Spoofed members ───────────────────────────────────────────────────────

  @override
  Iterable<ui.FlutterView> get views => [_previewView];

  @override
  ui.FlutterView? view({required int id}) =>
      id == _previewView.viewId ? _previewView : null;

  @override
  ui.FlutterView? get implicitView => _previewView;

  // ── Delegated callbacks ───────────────────────────────────────────────────

  @override
  ui.VoidCallback? get onPlatformConfigurationChanged =>
      _real.onPlatformConfigurationChanged;
  @override
  set onPlatformConfigurationChanged(ui.VoidCallback? value) =>
      _real.onPlatformConfigurationChanged = value;

  @override
  ui.FrameCallback? get onBeginFrame => _real.onBeginFrame;
  @override
  set onBeginFrame(ui.FrameCallback? value) => _real.onBeginFrame = value;

  @override
  ui.VoidCallback? get onDrawFrame => _real.onDrawFrame;
  @override
  set onDrawFrame(ui.VoidCallback? value) => _real.onDrawFrame = value;

  @override
  ui.TimingsCallback? get onReportTimings => _real.onReportTimings;
  @override
  set onReportTimings(ui.TimingsCallback? value) =>
      _real.onReportTimings = value;

  @override
  ui.PointerDataPacketCallback? get onPointerDataPacket =>
      _real.onPointerDataPacket;
  @override
  set onPointerDataPacket(ui.PointerDataPacketCallback? value) =>
      _real.onPointerDataPacket = value;

  @override
  ui.KeyDataCallback? get onKeyData => _real.onKeyData;
  @override
  set onKeyData(ui.KeyDataCallback? value) => _real.onKeyData = value;

  @override
  ui.VoidCallback? get onMetricsChanged => _real.onMetricsChanged;

  /// Wraps the framework's [onMetricsChanged] callback to also notify
  /// [PreviewController] listeners, so [ListenableBuilder] widgets rebuild
  /// when the window is resized (not just when controller state changes).
  @override
  set onMetricsChanged(ui.VoidCallback? value) {
    _real.onMetricsChanged = value == null
        ? null
        : () {
            _controller.notifyMetricsChanged();
            value();
          };
  }

  @override
  ui.ViewFocusChangeCallback? get onViewFocusChange => _real.onViewFocusChange;
  @override
  set onViewFocusChange(ui.ViewFocusChangeCallback? value) =>
      _real.onViewFocusChange = value;

  @override
  ui.VoidCallback? get onLocaleChanged => _real.onLocaleChanged;
  @override
  set onLocaleChanged(ui.VoidCallback? value) => _real.onLocaleChanged = value;

  @override
  ui.VoidCallback? get onTextScaleFactorChanged =>
      _real.onTextScaleFactorChanged;
  @override
  set onTextScaleFactorChanged(ui.VoidCallback? value) =>
      _real.onTextScaleFactorChanged = value;

  @override
  ui.VoidCallback? get onPlatformBrightnessChanged =>
      _real.onPlatformBrightnessChanged;
  @override
  set onPlatformBrightnessChanged(ui.VoidCallback? value) =>
      _real.onPlatformBrightnessChanged = value;

  @override
  ui.VoidCallback? get onSystemFontFamilyChanged =>
      _real.onSystemFontFamilyChanged;
  @override
  set onSystemFontFamilyChanged(ui.VoidCallback? value) =>
      _real.onSystemFontFamilyChanged = value;

  @override
  // ignore: deprecated_member_use
  ui.PlatformMessageCallback? get onPlatformMessage => _real.onPlatformMessage;
  @override
  // ignore: deprecated_member_use
  set onPlatformMessage(ui.PlatformMessageCallback? value) =>
      // ignore: deprecated_member_use
      _real.onPlatformMessage = value;

  @override
  ui.VoidCallback? get onSemanticsEnabledChanged =>
      _real.onSemanticsEnabledChanged;
  @override
  set onSemanticsEnabledChanged(ui.VoidCallback? value) =>
      _real.onSemanticsEnabledChanged = value;

  @override
  ui.SemanticsActionEventCallback? get onSemanticsActionEvent =>
      _real.onSemanticsActionEvent;
  @override
  set onSemanticsActionEvent(ui.SemanticsActionEventCallback? value) =>
      _real.onSemanticsActionEvent = value;

  @override
  ui.VoidCallback? get onAccessibilityFeaturesChanged =>
      _real.onAccessibilityFeaturesChanged;
  @override
  set onAccessibilityFeaturesChanged(ui.VoidCallback? value) =>
      _real.onAccessibilityFeaturesChanged = value;

  @override
  ui.ErrorCallback? get onError => _real.onError;
  @override
  set onError(ui.ErrorCallback? value) => _real.onError = value;

  @override
  ui.VoidCallback? get onFrameDataChanged => _real.onFrameDataChanged;
  @override
  set onFrameDataChanged(ui.VoidCallback? value) =>
      _real.onFrameDataChanged = value;

  // ── Delegated getters ─────────────────────────────────────────────────────

  @override
  Iterable<ui.Display> get displays => _real.displays;

  @override
  int? get engineId => _real.engineId;

  @override
  ui.FrameData get frameData => _real.frameData;

  @override
  ui.Locale get locale => _real.locale;

  @override
  List<ui.Locale> get locales => _real.locales;

  @override
  String get initialLifecycleState => _real.initialLifecycleState;

  @override
  bool get alwaysUse24HourFormat => _real.alwaysUse24HourFormat;

  @override
  double? get lineHeightScaleFactorOverride =>
      _real.lineHeightScaleFactorOverride;

  @override
  double? get letterSpacingOverride => _real.letterSpacingOverride;

  @override
  double? get wordSpacingOverride => _real.wordSpacingOverride;

  @override
  double? get paragraphSpacingOverride => _real.paragraphSpacingOverride;

  @override
  double get textScaleFactor => _real.textScaleFactor;

  @override
  bool get nativeSpellCheckServiceDefined =>
      _real.nativeSpellCheckServiceDefined;

  @override
  bool get supportsShowingSystemContextMenu =>
      _real.supportsShowingSystemContextMenu;

  @override
  bool get brieflyShowPassword => _real.brieflyShowPassword;

  @override
  ui.Brightness get platformBrightness => _real.platformBrightness;

  @override
  String? get systemFontFamily => _real.systemFontFamily;

  @override
  bool get semanticsEnabled => _real.semanticsEnabled;

  @override
  ui.AccessibilityFeatures get accessibilityFeatures =>
      _real.accessibilityFeatures;

  @override
  String get defaultRouteName => _real.defaultRouteName;

  // ── Delegated methods ─────────────────────────────────────────────────────

  @override
  void requestViewFocusChange({
    required int viewId,
    required ui.ViewFocusState state,
    required ui.ViewFocusDirection direction,
  }) => _real.requestViewFocusChange(
    viewId: viewId,
    state: state,
    direction: direction,
  );

  @override
  ui.Locale? computePlatformResolvedLocale(List<ui.Locale> supportedLocales) =>
      _real.computePlatformResolvedLocale(supportedLocales);

  @override
  void setApplicationLocale(ui.Locale locale) =>
      _real.setApplicationLocale(locale);

  @override
  void sendPlatformMessage(
    String name,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) => _real.sendPlatformMessage(name, data, callback);

  @override
  void sendPortPlatformMessage(
    String name,
    ByteData? data,
    int identifier,
    SendPort port,
  ) => _real.sendPortPlatformMessage(name, data, identifier, port);

  @override
  void registerBackgroundIsolate(ui.RootIsolateToken token) =>
      _real.registerBackgroundIsolate(token);

  @override
  void setSemanticsTreeEnabled(bool enabled) =>
      _real.setSemanticsTreeEnabled(enabled);

  @override
  void setIsolateDebugName(String name) => _real.setIsolateDebugName(name);

  @override
  void requestDartPerformanceMode(ui.DartPerformanceMode mode) =>
      _real.requestDartPerformanceMode(mode);

  @override
  ByteData? getPersistentIsolateData() => _real.getPersistentIsolateData();

  @override
  void scheduleFrame() => _real.scheduleFrame();

  @override
  void scheduleWarmUpFrame({
    required ui.VoidCallback beginFrame,
    required ui.VoidCallback drawFrame,
  }) => _real.scheduleWarmUpFrame(beginFrame: beginFrame, drawFrame: drawFrame);

  @override
  // ignore: deprecated_member_use
  void updateSemantics(ui.SemanticsUpdate update) =>
      // ignore: deprecated_member_use
      _real.updateSemantics(update);

  @override
  double scaleFontSize(double unscaledFontSize) =>
      _real.scaleFontSize(unscaledFontSize);
}
