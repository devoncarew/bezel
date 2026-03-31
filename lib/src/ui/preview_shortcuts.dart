import 'dart:io' show Platform;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../preview_controller.dart';

// ── Intents ───────────────────────────────────────────────────────────────────

/// Fired by `Cmd+D` / `Ctrl+D` — toggles the device picker panel.
class ToggleDevicePickerIntent extends Intent {
  const ToggleDevicePickerIntent();
}

/// Fired by `Cmd+L` / `Ctrl+L` — toggles portrait ↔ landscape.
class ToggleOrientationIntent extends Intent {
  const ToggleOrientationIntent();
}

/// Fired by `Cmd+]` / `Ctrl+]` — advances to the next device.
class NextDeviceIntent extends Intent {
  const NextDeviceIntent();
}

/// Fired by `Cmd+[` / `Ctrl+[` — goes back to the previous device.
class PreviousDeviceIntent extends Intent {
  const PreviousDeviceIntent();
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Wraps [child] in a [Shortcuts] + [Actions] pair that handles the four
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
    final useMeta = Platform.isMacOS;

    return Shortcuts(
      shortcuts: {
        SingleActivator(
          LogicalKeyboardKey.keyD,
          meta: useMeta,
          control: !useMeta,
        ): const ToggleDevicePickerIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyL,
          meta: useMeta,
          control: !useMeta,
        ): const ToggleOrientationIntent(),
        SingleActivator(
          LogicalKeyboardKey.bracketRight,
          meta: useMeta,
          control: !useMeta,
        ): const NextDeviceIntent(),
        SingleActivator(
          LogicalKeyboardKey.bracketLeft,
          meta: useMeta,
          control: !useMeta,
        ): const PreviousDeviceIntent(),
      },
      child: Actions(
        actions: {
          ToggleDevicePickerIntent: CallbackAction<ToggleDevicePickerIntent>(
            onInvoke: (_) => controller.toggleDevicePicker(),
          ),
          ToggleOrientationIntent: CallbackAction<ToggleOrientationIntent>(
            onInvoke: (_) => controller.toggleOrientation(),
          ),
          NextDeviceIntent: CallbackAction<NextDeviceIntent>(
            onInvoke: (_) => controller.cycleDevice(1),
          ),
          PreviousDeviceIntent: CallbackAction<PreviousDeviceIntent>(
            onInvoke: (_) => controller.cycleDevice(-1),
          ),
        },
        child: child,
      ),
    );
  }
}
