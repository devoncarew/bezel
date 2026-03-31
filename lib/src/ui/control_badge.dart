import 'package:flutter/material.dart';

import '../preview_controller.dart';
import '../theme.dart';

/// Semi-transparent badge anchored to the top-right corner of the preview
/// window.
///
/// Shaped as an inverted tab: flush with the top and right window edges,
/// with a single rounded corner at the bottom-left. Tapping toggles the
/// device picker panel.
///
/// Stays visible in passthrough mode (dimmed) so users can always return to
/// the preview without needing a keyboard shortcut.
class ControlBadge extends StatelessWidget {
  const ControlBadge({super.key, required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final dimmed = controller.passthroughMode;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: controller.toggleDevicePicker,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
          ),
          child: ColoredBox(
            color: kPreviewBackground.withValues(alpha: dimmed ? 0.4 : 0.8),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 4,
                bottom: 5,
              ),
              child: Row(
                children: [
                  Icon(
                    controller.activeProfile.icon,
                    size: 12,
                    color: kPreviewForeground.withValues(
                      alpha: dimmed ? 0.5 : 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    controller.activeProfile.name,
                    style: TextStyle(
                      color: kPreviewForeground.withValues(
                        alpha: dimmed ? 0.5 : 1.0,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
