import 'binding/preview_binding.dart';
import 'preview_controller.dart';

/// Initialises the preview binding. Called only in debug mode via `assert`.
void debugEnsureInitialized() => PreviewBinding.ensureInitialized();

/// Returns the active [PreviewController], or `null` if the binding has not
/// been initialised.
PreviewController? get debugController => PreviewBinding.controller;
