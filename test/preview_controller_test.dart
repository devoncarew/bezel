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

    test('toolbarVisible is true', () {
      expect(controller.toolbarVisible, isTrue);
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

  group('toggleToolbar', () {
    test('hides the toolbar', () {
      controller.toggleToolbar();
      expect(controller.toolbarVisible, isFalse);
    });

    test('shows the toolbar again', () {
      controller.toggleToolbar();
      controller.toggleToolbar();
      expect(controller.toolbarVisible, isTrue);
    });

    test('notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.toggleToolbar();
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
