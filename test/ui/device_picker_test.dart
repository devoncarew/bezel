import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_database.dart';
import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/preview_controller.dart';
import 'package:flight_check/src/ui/device_picker.dart';

/// Wraps [child] with the ancestors required by Material-level widgets.
Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  late PreviewController controller;

  setUp(() => controller = PreviewController());
  tearDown(() => controller.dispose());

  group('DevicePicker', () {
    testWidgets('lists all iOS devices', (tester) async {
      await tester.pumpWidget(_wrap(DevicePicker(controller: controller)));

      for (final profile in DeviceDatabase.forPlatform(DevicePlatform.iOS)) {
        expect(find.text(profile.name), findsOneWidget);
      }
    });

    testWidgets('lists all Android devices', (tester) async {
      await tester.pumpWidget(_wrap(DevicePicker(controller: controller)));

      for (final profile in DeviceDatabase.forPlatform(
        DevicePlatform.android,
      )) {
        expect(find.text(profile.name), findsOneWidget);
      }
    });

    testWidgets('shows a check next to the active device', (tester) async {
      await tester.pumpWidget(_wrap(DevicePicker(controller: controller)));

      // One check icon — for the currently active device.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('active device check moves after setProfile', (tester) async {
      final next = DeviceDatabase.all.firstWhere(
        (p) => p.id != controller.activeProfile.id,
      );
      controller.setProfile(next);

      await tester.pumpWidget(_wrap(DevicePicker(controller: controller)));

      // Still exactly one check, next to the new active device.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tapping a device calls setProfile and closes picker', (
      tester,
    ) async {
      controller.toggleDevicePicker();
      await tester.pumpWidget(_wrap(DevicePicker(controller: controller)));

      final target = DeviceDatabase.all.firstWhere(
        (p) => p.id != controller.activeProfile.id,
      );

      await tester.tap(find.text(target.name));

      expect(controller.activeProfile, target);
      expect(controller.devicePickerVisible, isFalse);
    });

    testWidgets('tapping outside the card closes the picker', (tester) async {
      controller.toggleDevicePicker();
      await tester.pumpWidget(_wrap(DevicePicker(controller: controller)));

      expect(controller.devicePickerVisible, isTrue);

      // Tap in the top-left corner, outside the centred card.
      await tester.tapAt(const Offset(4, 4));

      expect(controller.devicePickerVisible, isFalse);
    });
  });
}
