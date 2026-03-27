import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

import 'binding/preview_binding.dart';
import 'preview_controller.dart';

/// Initialises the preview binding. Called only in debug mode via `assert`.
///
/// Does nothing when running on a mobile platform (iOS or Android) — the
/// preview tool is desktop-only and should not interfere with real-device runs.
void debugEnsureInitialized() {
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    return;
  }

  PreviewBinding.ensureInitialized();
}

/// Returns the active [PreviewController], or `null` if the binding has not
/// been initialized (or was skipped on a mobile platform).
PreviewController? get debugController => PreviewBinding.controller;
