import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../preview_controller.dart';

// ── Intents ───────────────────────────────────────────────────────────────────

/// Fired by `Ctrl+L` / `Cmd+L` — toggles portrait ↔ landscape.
class ToggleOrientationIntent extends Intent {
  const ToggleOrientationIntent();
}

// /// Fired by `Ctrl+R` / `Cmd+R` — reassembles the application.
// class ReloadIntent extends Intent {
//   const ReloadIntent();
// }

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
          LogicalKeyboardKey.keyL,
          meta: useMeta,
          control: !useMeta,
        ): const ToggleOrientationIntent(),
        // SingleActivator(
        //   LogicalKeyboardKey.keyR,
        //   meta: useMeta,
        //   control: !useMeta,
        // ): const ReloadIntent(),
      },
      child: Actions(
        actions: {
          ToggleOrientationIntent: CallbackAction<ToggleOrientationIntent>(
            onInvoke: (_) => controller.toggleOrientation(),
          ),
          // ReloadIntent: CallbackAction<ReloadIntent>(
          //   onInvoke: (_) => WidgetsBinding.instance.reassembleApplication(),
          // ),
        },
        child: child,
      ),
    );
  }
}
