import 'preview_controller.dart';

/// No-op on web — the preview tool does not support Flutter Web.
void debugEnsureInitialized() {}

/// Always `null` on web.
PreviewController? get debugController => null;
