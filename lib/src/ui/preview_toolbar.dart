import 'package:flutter/material.dart';

import '../preview_controller.dart';

/// Border radius applied to the pill-shaped toolbar container.
const _kPillRadius = BorderRadius.all(Radius.circular(28.0));

/// Background colour of the toolbar pill — semi-transparent dark.
const _kBackgroundColor = Color(0xCC1A1A1A);

/// Colour applied to toolbar icons and text.
const _kForegroundColor = Color(0xFFFFFFFF);

/// Floating pill-shaped toolbar rendered at the top of the preview overlay.
///
/// Shows the active device name (tapping will open the device picker — step
/// 2.6), an orientation toggle, a reassemble button, and a passthrough-mode
/// toggle.
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
      child: Container(
        decoration: const BoxDecoration(
          color: _kBackgroundColor,
          borderRadius: _kPillRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DeviceNameButton(controller: controller),
            _ToolbarDivider(),
            _OrientationButton(controller: controller),
            _ReassembleButton(),
            _PassthroughButton(controller: controller),
          ],
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
      onTap: () {
        // Step 2.6 will replace this with the real device picker.
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160.0),
          child: Text(
            controller.activeProfile.name,
            style: const TextStyle(
              color: _kForegroundColor,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
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
      height: 24.0,
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
      color: _kForegroundColor,
      iconSize: 20.0,
      onPressed: controller.toggleOrientation,
    );
  }
}

// ── Reassemble button ─────────────────────────────────────────────────────────

class _ReassembleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      color: _kForegroundColor,
      iconSize: 20.0,
      onPressed: () => WidgetsBinding.instance.reassembleApplication(),
    );
  }
}

// ── Passthrough toggle ────────────────────────────────────────────────────────

class _PassthroughButton extends StatelessWidget {
  const _PassthroughButton({required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        controller.passthroughMode ? Icons.crop_free : Icons.phone_android,
      ),
      color: controller.passthroughMode
          ? _kForegroundColor.withAlpha(0x99)
          : _kForegroundColor,
      iconSize: 20.0,
      onPressed: controller.togglePassthrough,
    );
  }
}
