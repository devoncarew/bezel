import 'package:flutter/material.dart';

import '../preview_controller.dart';
import '../theme.dart';
import 'common.dart';

/// Border radius applied to the pill-shaped toolbar container.
const BorderRadius _kPillRadius = BorderRadius.all(Radius.circular(14));

/// Compact pill-shaped toolbar rendered at the bottom of the preview overlay.
///
/// Shows the active device name, an orientation toggle, and a reload button.
class PreviewToolbar extends StatelessWidget {
  const PreviewToolbar({super.key, required this.controller});

  /// The shared controller for this preview session.
  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildToolbar(context),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: RaisedSurface(
        borderRadius: _kPillRadius,
        height: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DeviceNameButton(controller: controller),
              _ToolbarDivider(),
              _OrientationButton(controller: controller),
              // _ReloadButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Device name button ────────────────────────────────────────────────────────

class _DeviceNameButton extends StatelessWidget {
  const _DeviceNameButton({required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: _kPillRadius,
      mouseCursor: SystemMouseCursors.click,
      onTap: controller.toggleDevicePicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140.0),
              child: Text(
                controller.activeProfile.name,
                style: const TextStyle(
                  color: kPreviewForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: kPreviewForeground,
              size: 14.0,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Separator ─────────────────────────────────────────────────────────────────

class _ToolbarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.0,
      height: 14.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      color: const Color(0x55FFFFFF),
    );
  }
}

// ── Orientation toggle ────────────────────────────────────────────────────────

class _OrientationButton extends StatelessWidget {
  const _OrientationButton({required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.screen_rotation),
      color: kPreviewForeground,
      iconSize: 14.0,
      padding: const EdgeInsets.all(4.0),
      constraints: const BoxConstraints(),
      onPressed: controller.toggleOrientation,
    );
  }
}

// ── Reload button ─────────────────────────────────────────────────────────

// class _ReloadButton extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.refresh),
//       color: kPreviewForeground,
//       iconSize: 14.0,
//       padding: const EdgeInsets.all(4.0),
//       constraints: const BoxConstraints(),
//       onPressed: () => WidgetsBinding.instance.reassembleApplication(),
//     );
//   }
// }
