import '../theme.dart';
import 'package:flutter/material.dart';

import '../devices/device_database.dart';
import '../devices/device_profile.dart';
import '../preview_controller.dart';

/// A floating device-picker card rendered directly in the preview overlay's
/// [Stack].
///
/// Rather than using [showDialog] (which requires a [Navigator]/[Overlay]
/// ancestor that the toolbar does not have), [DevicePicker] is a plain widget
/// embedded in the overlay's stack and toggled via [PreviewController].
///
/// Usage in the overlay [Stack]:
/// ```dart
/// if (controller.devicePickerVisible)
///   DevicePicker(controller: controller),
/// ```
class DevicePicker extends StatefulWidget {
  const DevicePicker({super.key, required this.controller});

  final PreviewController controller;

  @override
  State<DevicePicker> createState() => _DevicePickerState();
}

class _DevicePickerState extends State<DevicePicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iOS = DeviceDatabase.all
        .where((d) => d.platform == DevicePlatform.iOS && !d.tablet)
        .toList();
    final android = DeviceDatabase.all
        .where((d) => d.platform == DevicePlatform.android && !d.tablet)
        .toList();
    final tablets = DeviceDatabase.all.where((d) => d.tablet).toList();

    return GestureDetector(
      // Tapping outside the card closes the picker.
      // HitTestBehavior.opaque makes the detector fill its constraints even
      // though its child (Center → card) is smaller.
      behavior: HitTestBehavior.opaque,
      onTap: widget.controller.toggleDevicePicker,
      child: Center(
        child: GestureDetector(
          // Absorb taps inside the card so they don't propagate to the
          // outer dismissal layer.
          onTap: () {},
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 560),
            child: Material(
              color: kPreviewBackground,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                // TabBar requires MaterialLocalizations, which may not be
                // present when the overlay sits outside the user's MaterialApp
                // tree. Provide them explicitly here.
                child: Localizations(
                  locale: const Locale('en'),
                  delegates: const [
                    DefaultMaterialLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                  ],
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
                ), // Localizations
              ),
            ),
          ),
        ),
      ),
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
                  controller.toggleDevicePicker();
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
                        '${w}x$h',
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
