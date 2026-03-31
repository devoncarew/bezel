import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../devices/device_database.dart';
import '../devices/device_profile.dart';
import '../preview_controller.dart';
import '../theme.dart';

/// Width of the control panel card.
const double _kPanelWidth = 332;

/// Width of the control panel card.
const double _kPanelHeight = 565;

/// Corner radius used for all non-flush panel corners.
const double _kPanelRadius = 10;

/// Shape for the panel: top-right corner is flush with the window edge (same
/// as the badge), all other corners are rounded.
const _kPanelBorderRadius = BorderRadius.only(
  topLeft: Radius.circular(_kPanelRadius),
  bottomLeft: Radius.circular(_kPanelRadius),
  bottomRight: Radius.circular(_kPanelRadius),
);

/// Floating panel that slides down from the [ControlBadge] in the top-right
/// corner of the preview window.
///
/// Contains:
/// 1. An action icon row (orientation toggle, passthrough toggle, shortcuts).
/// 2. An expandable keyboard shortcuts reference.
/// 3. A tabbed device list (iOS / Android / Tablets).
///
/// Visibility is driven by [PreviewController.devicePickerVisible]. The widget
/// wraps a full-window backdrop so tapping outside the card dismisses it.
class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key, required this.controller});

  final PreviewController controller;

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _slideAnim;

  late int _selectedTab;

  @override
  void initState() {
    super.initState();

    final profile = widget.controller.activeProfile;
    _selectedTab = profile.tablet
        ? 2
        : profile.platform == DevicePlatform.android
        ? 1
        : 0;

    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    if (widget.controller.devicePickerVisible) {
      _animController.value = 1.0;
    }

    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (widget.controller.devicePickerVisible) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.sizeOf(context).height - kControlBadgeHeight * 2 - 16;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) =>
          IgnorePointer(ignoring: _animController.isDismissed, child: child!),
      child: Stack(
        children: [
          // Full-window backdrop — tap to dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.controller.toggleDevicePicker,
            ),
          ),

          // Panel card anchored below the badge, slides in from the right.
          // ClipRect prevents the card from being visible while off-screen.
          Positioned(
            top: kControlBadgeHeight,
            right: 0,
            child: ClipRect(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(_slideAnim),
                child: SizedBox(
                  height: math.min(maxHeight, _kPanelHeight),
                  child: _buildContents(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContents(BuildContext context) {
    final iOS = DeviceDatabase.all
        .where((d) => d.platform == DevicePlatform.iOS && !d.tablet)
        .toList();
    final android = DeviceDatabase.all
        .where((d) => d.platform == DevicePlatform.android && !d.tablet)
        .toList();
    final tablets = DeviceDatabase.all.where((d) => d.tablet).toList();

    // SegmentedButton requires MaterialLocalizations; provide them here so the
    // panel works even when no MaterialApp ancestor exists.
    return SizedBox(
      width: _kPanelWidth,
      child: Localizations(
        locale: const Locale('en'),
        delegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Material(
          color: kPreviewBackground,
          borderRadius: _kPanelBorderRadius,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ActionRow(controller: widget.controller),
              const Divider(height: 1, thickness: 1, color: Color(0x33FFFFFF)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _createSegmentedButton(),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, thickness: 1, color: Color(0x33FFFFFF)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: IndexedStack(
                    index: _selectedTab,
                    alignment: AlignmentDirectional.topStart,
                    children: [
                      _DeviceList(profiles: iOS, controller: widget.controller),
                      _DeviceList(
                        profiles: android,
                        controller: widget.controller,
                      ),
                      _DeviceList(
                        profiles: tablets,
                        controller: widget.controller,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0x33FFFFFF)),
              // Footer area.
              Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 12,
                  left: 8,
                  right: 8,
                ),
                child: Row(
                  children: [
                    _ShortcutButton(
                      icon: Icons.devices,
                      binding: '${Platform.isMacOS ? '⌘' : 'Ctrl-'}D',
                      tooltip: 'Toggle device picker',
                      onTap: widget.controller.toggleDevicePicker,
                    ),
                    const Expanded(child: SizedBox(width: 16)),
                    _ShortcutButton(
                      icon: Icons.skip_previous,
                      binding: '${Platform.isMacOS ? '⌘' : 'Ctrl-'}[',
                      tooltip: 'Previous device',
                      onTap: () => widget.controller.cycleDevice(-1),
                    ),
                    const SizedBox(width: 8),
                    _ShortcutButton(
                      icon: Icons.skip_next,
                      binding: '${Platform.isMacOS ? '⌘' : 'Ctrl-'}]',
                      tooltip: 'Next device',
                      onTap: () => widget.controller.cycleDevice(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SegmentedButton<int> _createSegmentedButton() {
    return SegmentedButton<int>(
      expandedInsets: EdgeInsets.zero,
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('iOS'),
          icon: Icon(Icons.phone_iphone),
        ),
        ButtonSegment(
          value: 1,
          label: Text('Android'),
          icon: Icon(Icons.phone_android),
        ),
        ButtonSegment(
          value: 2,
          label: Text('Tablets'),
          icon: Icon(Icons.tablet),
        ),
      ],
      selected: {_selectedTab},
      onSelectionChanged: (s) => setState(() => _selectedTab = s.first),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? kPreviewForegroundEmphasis
              : kPreviewForeground,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0x33FFFFFF)
              : Colors.transparent,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: kPreviewForeground.withValues(alpha: 0.3)),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
      ),
      showSelectedIcon: false,
    );
  }
}

// ── Action icon row ───────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Flight Check',
              textAlign: TextAlign.center,
              style: TextStyle(color: kPreviewForegroundEmphasis),
            ),
          ),
          _ShortcutButton(
            icon: Icons.screen_rotation,
            binding: '${Platform.isMacOS ? '⌘' : 'Ctrl-'}L',
            tooltip: 'Toggle orientation',
            onTap: controller.toggleOrientation,
          ),
        ],
      ),
    );
  }
}

TextStyle _monospace() {
  return const TextStyle(
    color: kPreviewForeground,
    fontSize: 12,
    fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New'],
  );
}

// ── Device list (one per tab) ─────────────────────────────────────────────────

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.profiles, required this.controller});

  final List<DeviceProfile> profiles;
  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final profile in profiles)
              _DeviceItem(
                profile: profile,
                isActive: profile.id == controller.activeProfile.id,
                onTap: () {
                  controller.setProfile(profile);
                },
              ),
          ],
        );
      },
    );
  }
}

// ── Device item ───────────────────────────────────────────────────────────────

class _DeviceItem extends StatelessWidget {
  const _DeviceItem({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final DeviceProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = profile.logicalSize;
    final w = size.width.truncate();
    final h = size.height.truncate();

    const activeBg = Color(0x22FFFFFF);
    const borderColor = Color(0x18FFFFFF);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? activeBg : null,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    profile.name,
                    style: const TextStyle(
                      color: kPreviewForegroundEmphasis,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$w×$h',
                  style: const TextStyle(
                    color: kPreviewForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (profile.description != null) ...[
              const SizedBox(height: 2),
              Text(
                profile.description!,
                style: const TextStyle(color: kPreviewForeground),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shortcut button ───────────────────────────────────────────────────────────

/// A compact bordered button that pairs an [icon] with a keyboard [binding]
/// label, used in the control panel footer.
class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.icon,
    required this.binding,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final String binding;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: kPreviewForeground.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kPreviewForeground, size: 16),
            const SizedBox(width: 6),
            Text(binding, style: _monospace()),
          ],
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
