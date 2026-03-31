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
///
/// Animates between open and closed states — the background brightens and the
/// chevron rotates 180° when the panel is open.
class ControlBadge extends StatefulWidget {
  const ControlBadge({super.key, required this.controller});

  final PreviewController controller;

  @override
  State<ControlBadge> createState() => _ControlBadgeState();
}

class _ControlBadgeState extends State<ControlBadge>
    with SingleTickerProviderStateMixin {
  // Matches ControlPanel slide animation duration.
  static const _kDuration = Duration(milliseconds: 200);

  late final AnimationController _anim;
  late final Animation<double> _chevron;
  late final Animation<double> _bgAlpha;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(duration: _kDuration, vsync: this);
    if (widget.controller.devicePickerVisible) _anim.value = 1.0;

    _chevron = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    _bgAlpha = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));

    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (widget.controller.devicePickerVisible) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final dimmed = widget.controller.passthroughMode;
        final foregroundAlpha = dimmed ? 0.5 : 1.0;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.controller.toggleDevicePicker,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: kPreviewBackground.withValues(
                    alpha: dimmed ? 0.4 : _bgAlpha.value,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                  ),
                  border: Border.all(
                    color: kPreviewForeground.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(-2, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 6,
                  top: 5,
                  bottom: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 13,
                      color: kPreviewForeground.withValues(
                        alpha: foregroundAlpha,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.controller.activeProfile.name,
                      style: TextStyle(
                        color: kPreviewForeground.withValues(
                          alpha: foregroundAlpha,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 4),
                    RotationTransition(
                      turns: Tween<double>(
                        begin: 0.0,
                        end: 0.5,
                      ).animate(_chevron),
                      child: Icon(
                        Icons.expand_more,
                        size: 14,
                        color: kPreviewForeground.withValues(
                          alpha: foregroundAlpha,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
