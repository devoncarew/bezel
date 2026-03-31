import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import '../devices/device_database.dart';
import '../devices/device_profile.dart';
import '../preview_controller.dart';
import '../theme.dart';

/// Width of the control panel card.
const double _kPanelWidth = 280.0;

/// Height reserved for the tabbed device list inside the panel.
const double _kDeviceListHeight = 360.0;

/// Corner radius used for all non-flush panel corners.
const double _kPanelRadius = 10.0;

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
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _animController;
  late final Animation<double> _slideAnim;

  bool _shortcutsExpanded = false;

  @override
  void initState() {
    super.initState();

    final profile = widget.controller.activeProfile;
    final initialIndex = profile.tablet
        ? 2
        : profile.platform == DevicePlatform.android
        ? 1
        : 0;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );

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
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: _buildCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    final iOS = DeviceDatabase.all
        .where((d) => d.platform == DevicePlatform.iOS && !d.tablet)
        .toList();
    final android = DeviceDatabase.all
        .where((d) => d.platform == DevicePlatform.android && !d.tablet)
        .toList();
    final tablets = DeviceDatabase.all.where((d) => d.tablet).toList();

    return SizedBox(
      width: _kPanelWidth,
      child: Material(
        color: kPreviewBackground.withValues(alpha: 0.92),
        borderRadius: _kPanelBorderRadius,
        child: ClipRRect(
          borderRadius: _kPanelBorderRadius,
          // TabBar requires MaterialLocalizations; provide them here so the
          // panel works even when no MaterialApp ancestor exists.
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionRow(
                  controller: widget.controller,
                  shortcutsExpanded: _shortcutsExpanded,
                  onToggleShortcuts: () =>
                      setState(() => _shortcutsExpanded = !_shortcutsExpanded),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: _shortcutsExpanded
                      ? const _ShortcutsSection()
                      : const SizedBox.shrink(),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0x33FFFFFF),
                ),
                SizedBox(
                  height: _kDeviceListHeight,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'iOS'),
                          Tab(text: 'Android'),
                          Tab(text: 'Tablets'),
                        ],
                        labelColor: kPreviewForegroundEmphasis,
                        indicatorColor: kPreviewForegroundEmphasis,
                        unselectedLabelColor: kPreviewForeground,
                        dividerColor: Colors.transparent,
                        tabAlignment: TabAlignment.fill,
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _DeviceList(
                              profiles: iOS,
                              controller: widget.controller,
                            ),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action icon row ───────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.controller,
    required this.shortcutsExpanded,
    required this.onToggleShortcuts,
  });

  final PreviewController controller;
  final bool shortcutsExpanded;
  final VoidCallback onToggleShortcuts;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.screen_rotation),
              color: kPreviewForeground,
              iconSize: 16,
              onPressed: controller.toggleOrientation,
            ),
            IconButton(
              icon: Icon(
                controller.passthroughMode
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              color: controller.passthroughMode
                  ? kPreviewForegroundEmphasis
                  : kPreviewForeground,
              iconSize: 16,
              onPressed: controller.togglePassthrough,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.keyboard_outlined),
              color: shortcutsExpanded
                  ? kPreviewForegroundEmphasis
                  : kPreviewForeground,
              iconSize: 16,
              onPressed: onToggleShortcuts,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Keyboard shortcuts reference ──────────────────────────────────────────────

class _ShortcutsSection extends StatelessWidget {
  const _ShortcutsSection();

  @override
  Widget build(BuildContext context) {
    final modifier = defaultTargetPlatform == TargetPlatform.macOS
        ? '⌘'
        : 'Ctrl+';
    final shortcuts = [
      ('Toggle device picker', '${modifier}D'),
      ('Toggle orientation', '${modifier}L'),
      ('Next device', '$modifier]'),
      ('Previous device', '$modifier['),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0x33FFFFFF)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (label, key) in shortcuts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: kPreviewForeground,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        key,
                        style: const TextStyle(
                          color: kPreviewForeground,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
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
          padding: const EdgeInsets.symmetric(vertical: 8),
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
    final w = size.width.truncate().toString();
    final h = size.height.truncate().toString();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: const TextStyle(
                            color: kPreviewForegroundEmphasis,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$w×$h',
                        style: const TextStyle(
                          color: kPreviewForeground,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (profile.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.description!,
                      style: const TextStyle(
                        color: kPreviewForeground,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check,
                color: kPreviewForegroundEmphasis,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
