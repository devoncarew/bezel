import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/preview_controller.dart';

void main() {
  late PreviewController controller;

  setUp(() {
    controller = PreviewController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('initial state', () {
    test('activeProfile is the default profile', () {
      expect(controller.activeProfile, DeviceDatabase.defaultProfile);
    });

    test('orientation is portrait', () {
      expect(controller.orientation, DeviceOrientation.portrait);
    });
  });

  group('setProfile', () {
    test('updates activeProfile', () {
      final target = DeviceDatabase.all.firstWhere(
        (p) => p.id != DeviceDatabase.defaultProfile.id,
      );
      controller.setProfile(target);
      expect(controller.activeProfile, target);
    });

    test('notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      final target = DeviceDatabase.all.firstWhere(
        (p) => p.id != DeviceDatabase.defaultProfile.id,
      );
      controller.setProfile(target);

      expect(notified, isTrue);
    });

    test('does not notify when profile is unchanged', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.setProfile(controller.activeProfile);
      expect(count, 0);
    });
  });

  group('toggleOrientation', () {
    test('switches portrait to landscape', () {
      expect(controller.orientation, DeviceOrientation.portrait);
      controller.toggleOrientation();
      expect(controller.orientation, DeviceOrientation.landscape);
    });

    test('switches landscape back to portrait', () {
      controller.toggleOrientation();
      controller.toggleOrientation();
      expect(controller.orientation, DeviceOrientation.portrait);
    });

    test('notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.toggleOrientation();
      expect(notified, isTrue);
    });
  });

  group('togglePassthrough', () {
    test('passthroughMode starts false', () {
      expect(controller.passthroughMode, isFalse);
    });

    test('activates passthrough', () {
      controller.togglePassthrough();
      expect(controller.passthroughMode, isTrue);
    });

    test('deactivates passthrough on second call', () {
      controller.togglePassthrough();
      controller.togglePassthrough();
      expect(controller.passthroughMode, isFalse);
    });

    test('notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.togglePassthrough();
      expect(notified, isTrue);
    });
  });

  group('toggleDevicePicker', () {
    test('devicePickerVisible starts false', () {
      expect(controller.devicePickerVisible, isFalse);
    });

    test('opens the picker', () {
      controller.toggleDevicePicker();
      expect(controller.devicePickerVisible, isTrue);
    });

    test('closes the picker on second call', () {
      controller.toggleDevicePicker();
      controller.toggleDevicePicker();
      expect(controller.devicePickerVisible, isFalse);
    });

    test('notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.toggleDevicePicker();
      expect(notified, isTrue);
    });
  });

  group('emulatedLogicalSize', () {
    test('matches portrait logical size in portrait orientation', () {
      expect(
        controller.emulatedLogicalSize,
        controller.activeProfile.logicalSizeForOrientation(
          DeviceOrientation.portrait,
        ),
      );
    });

    test('matches landscape logical size after toggleOrientation', () {
      controller.toggleOrientation();
      expect(
        controller.emulatedLogicalSize,
        controller.activeProfile.logicalSizeForOrientation(
          DeviceOrientation.landscape,
        ),
      );
    });
  });

  group('emulatedSafeArea', () {
    test('matches portrait safe area in portrait orientation', () {
      expect(
        controller.emulatedSafeArea,
        controller.activeProfile.safeAreaForOrientation(
          DeviceOrientation.portrait,
        ),
      );
    });

    test('matches landscape safe area after toggleOrientation', () {
      controller.toggleOrientation();
      expect(
        controller.emulatedSafeArea,
        controller.activeProfile.safeAreaForOrientation(
          DeviceOrientation.landscape,
        ),
      );
    });
  });
}
