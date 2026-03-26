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
/// The menu rebuilds via [ListenableBuilder] whenever [controller] notifies,
/// so the active-profile check-mark tracks the controller state in real time.
class MacosPreviewMenu extends StatelessWidget {
  const MacosPreviewMenu({
    super.key,
    required this.controller,
    required this.child,
  });

  /// The shared controller for this preview session.
  final PreviewController controller;

  /// The widget tree to render as the [PlatformMenuBar.body].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      return child;
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildMenuBar(),
    );
  }

  Widget _buildMenuBar() {
    final active = controller.activeProfile;
    final iOSProfiles = DeviceDatabase.forPlatform(DevicePlatform.iOS);
    final androidProfiles = DeviceDatabase.forPlatform(DevicePlatform.android);

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Preview',
          menus: [
            // Device submenu — iOS and Android profiles in separate groups so
            // a divider separates the two platforms.
            PlatformMenu(
              label: 'Device',
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    for (final p in iOSProfiles)
                      PlatformMenuItem(
                        label: _labelFor(p, active),
                        onSelected: () => controller.setProfile(p),
                      ),
                  ],
                ),
                PlatformMenuItemGroup(
                  members: [
                    for (final p in androidProfiles)
                      PlatformMenuItem(
                        label: _labelFor(p, active),
                        onSelected: () => controller.setProfile(p),
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
                  onSelected: controller.toggleOrientation,
                ),
                PlatformMenuItem(
                  label: 'Reassemble',
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
      ],
      child: child,
    );
  }

  /// Returns the display label for [profile], prefixed with a check-mark when
  /// it matches [active] and with a non-breaking space prefix otherwise, so
  /// the names align in the native menu.
  static String _labelFor(DeviceProfile profile, DeviceProfile active) {
    return profile == active ? '\u2713 ${profile.name}' : '   ${profile.name}';
  }
}
