import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../preview_controller.dart';

// ── Intents ───────────────────────────────────────────────────────────────────

/// Fired by `Ctrl+\` / `Cmd+\` — toggles toolbar visibility.
class ToggleToolbarIntent extends Intent {
  const ToggleToolbarIntent();
}

/// Fired by `Ctrl+L` / `Cmd+L` — toggles portrait ↔ landscape.
class ToggleOrientationIntent extends Intent {
  const ToggleOrientationIntent();
}

/// Fired by `Ctrl+R` / `Cmd+R` — reassembles the application.
class ReassembleIntent extends Intent {
  const ReassembleIntent();
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Wraps [child] in a [Shortcuts] + [Actions] pair that handles the three
/// preview keyboard shortcuts.
///
/// Uses `meta` (⌘) on macOS and `control` on all other platforms.
class PreviewShortcuts extends StatelessWidget {
  const PreviewShortcuts({
    super.key,
    required this.controller,
    required this.child,
  });

  final PreviewController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final useMeta = defaultTargetPlatform == TargetPlatform.macOS;

    return Shortcuts(
      shortcuts: {
        SingleActivator(
          LogicalKeyboardKey.backslash,
          meta: useMeta,
          control: !useMeta,
        ): const ToggleToolbarIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyL,
          meta: useMeta,
          control: !useMeta,
        ): const ToggleOrientationIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyR,
          meta: useMeta,
          control: !useMeta,
        ): const ReassembleIntent(),
      },
      child: Actions(
        actions: {
          ToggleToolbarIntent: CallbackAction<ToggleToolbarIntent>(
            onInvoke: (_) => controller.toggleToolbar(),
          ),
          ToggleOrientationIntent: CallbackAction<ToggleOrientationIntent>(
            onInvoke: (_) => controller.toggleOrientation(),
          ),
          ReassembleIntent: CallbackAction<ReassembleIntent>(
            onInvoke: (_) => WidgetsBinding.instance.reassembleApplication(),
          ),
        },
        child: child,
      ),
    );
  }
}
