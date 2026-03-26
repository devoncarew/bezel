import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../devices/device_database.dart';
import '../devices/device_profile.dart';
import '../preview_controller.dart';

/// Adds a native "Preview" menu to the macOS menu bar.
///
/// On non-macOS platforms this widget is transparent — it returns [child]
/// unchanged. On macOS it wraps [child] in a [PlatformMenuBar] that installs a
/// "Preview" top-level menu with:
/// - A "Device" submenu listing all profiles grouped by platform, with a
///   check-mark (✓) prefix on the active profile.
/// - A "Toggle Orientation" item bound to ⌘L.
/// - A "Reassemble" item bound to ⌘R.
///
/// The widget is a [StatefulWidget] so that the native menu list is only
/// rebuilt when the **active profile** changes. Rebuilding [PlatformMenuBar]
/// on every controller notification (e.g. window-resize metrics events) would
/// call `setMenus` on the platform delegate while a menu is open, causing macOS
/// to dismiss it immediately.
class MacosPreviewMenu extends StatefulWidget {
  const MacosPreviewMenu({
    super.key,
    required this.controller,
    required this.child,
  });

  /// The shared controller for this preview session.
  final PreviewController controller;

  /// The widget tree to render as the [PlatformMenuBar.child].
  final Widget child;

  @override
  State<MacosPreviewMenu> createState() => _MacosPreviewMenuState();
}

class _MacosPreviewMenuState extends State<MacosPreviewMenu> {
  /// The last active profile seen; used to detect when a menu rebuild is
  /// actually needed.
  late DeviceProfile _activeProfile;

  /// The current menus list passed to [PlatformMenuBar]. Only recreated when
  /// [_activeProfile] changes.
  late List<PlatformMenuItem> _menus;

  @override
  void initState() {
    super.initState();
    _activeProfile = widget.controller.activeProfile;
    _menus = _buildMenus(_activeProfile);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final current = widget.controller.activeProfile;
    if (current == _activeProfile) return;
    setState(() {
      _activeProfile = current;
      _menus = _buildMenus(current);
    });
  }

  /// Builds the full [PlatformMenuItem] tree for the given [active] profile.
  List<PlatformMenuItem> _buildMenus(DeviceProfile active) {
    final iOSProfiles = DeviceDatabase.forPlatform(DevicePlatform.iOS);
    final androidProfiles = DeviceDatabase.forPlatform(DevicePlatform.android);

    return [
      PlatformMenu(
        label: 'Preview',
        menus: [
          // Device submenu — iOS and Android profiles in separate groups so
          // a native divider separates the two platforms.
          PlatformMenu(
            label: 'Device',
            menus: [
              PlatformMenuItemGroup(
                members: [
                  for (final p in iOSProfiles)
                    PlatformMenuItem(
                      label: _labelFor(p, active),
                      onSelected: () => widget.controller.setProfile(p),
                    ),
                ],
              ),
              PlatformMenuItemGroup(
                members: [
                  for (final p in androidProfiles)
                    PlatformMenuItem(
                      label: _labelFor(p, active),
                      onSelected: () => widget.controller.setProfile(p),
                    ),
                ],
              ),
            ],
          ),
          // Orientation and reassemble actions in a second group so they are
          // separated from the device submenu by a divider.
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Toggle Orientation',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyL,
                  meta: true,
                ),
                onSelected: widget.controller.toggleOrientation,
              ),
              PlatformMenuItem(
                label: 'Reload',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyR,
                  meta: true,
                ),
                onSelected: () =>
                    WidgetsBinding.instance.reassembleApplication(),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      return widget.child;
    }
    return PlatformMenuBar(menus: _menus, child: widget.child);
  }

  /// Returns the display label for [profile], prefixed with a check-mark when
  /// it matches [active] and with spaces otherwise, so the names align.
  static String _labelFor(DeviceProfile profile, DeviceProfile active) {
    return profile == active ? '\u2713 ${profile.name}' : '   ${profile.name}';
  }
}
