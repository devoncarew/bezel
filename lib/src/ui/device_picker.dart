import 'package:flutter/material.dart';

import '../devices/device_database.dart';
import '../devices/device_profile.dart';
import '../preview_controller.dart';

/// Foreground colour for section headers and items.
const _kForegroundColor = Color(0xFFFFFFFF);

/// Muted colour used for section header labels.
const _kHeaderColor = Color(0x99FFFFFF);

/// Background colour of the picker card.
const _kCardColor = Color(0xE61A1A1A);

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
class DevicePicker extends StatelessWidget {
  const DevicePicker({super.key, required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    final iOS = DeviceDatabase.forPlatform(DevicePlatform.iOS);
    final android = DeviceDatabase.forPlatform(DevicePlatform.android);

    return GestureDetector(
      // Tapping outside the card closes the picker.
      // HitTestBehavior.opaque makes the detector fill its constraints even
      // though its child (Center → card) is smaller.
      behavior: HitTestBehavior.opaque,
      onTap: controller.toggleDevicePicker,
      child: Center(
        child: GestureDetector(
          // Absorb taps inside the card so they don't propagate to the
          // outer dismissal layer.
          onTap: () {},
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 480),
            child: Material(
              color: _kCardColor,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeader(label: 'iOS'),
                      for (final profile in iOS)
                        _DeviceItem(
                          profile: profile,
                          isActive: profile.id == controller.activeProfile.id,
                          onTap: () {
                            controller.setProfile(profile);
                            controller.toggleDevicePicker();
                          },
                        ),
                      const _SectionHeader(label: 'Android'),
                      for (final profile in android)
                        _DeviceItem(
                          profile: profile,
                          isActive: profile.id == controller.activeProfile.id,
                          onTap: () {
                            controller.setProfile(profile);
                            controller.toggleDevicePicker();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: _kHeaderColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                profile.name,
                style: const TextStyle(color: _kForegroundColor, fontSize: 14),
              ),
            ),
            if (isActive)
              const Icon(Icons.check, color: _kForegroundColor, size: 16),
          ],
        ),
      ),
    );
  }
}
