import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/window/window_manager_sizing_service.dart';
import 'package:bezel/src/window/window_sizing_service.dart';
import 'package:bezel/src/preview_controller.dart';

/// A [WindowSizingService] that records calls without touching `window_manager`.
class _SpySizingService implements WindowSizingService {
  final List<(DeviceProfile, DeviceOrientation)> calls = [];

  @override
  Future<void> applyProfile(
    DeviceProfile profile,
    DeviceOrientation orientation,
  ) async {
    calls.add((profile, orientation));
  }
}

void main() {
  group('WindowManagerSizingService.computeTargetSize', () {
    test('adds frame padding and toolbar height to portrait emulated size', () {
      final profile = DeviceDatabase.defaultProfile; // iPhone 15: 393×852
      final size = WindowManagerSizingService.computeTargetSize(
        profile,
        DeviceOrientation.portrait,
      );
      expect(size.width, profile.logicalSize.width + 80 * 2);
      expect(size.height, profile.logicalSize.height + 80 + 60);
    });

    test('uses landscape dimensions in landscape orientation', () {
      final profile = DeviceDatabase.defaultProfile;
      final portrait = WindowManagerSizingService.computeTargetSize(
        profile,
        DeviceOrientation.portrait,
      );
      final landscape = WindowManagerSizingService.computeTargetSize(
        profile,
        DeviceOrientation.landscape,
      );
      // Width and height are swapped for landscape.
      expect(landscape.width, portrait.height - 80 - 60 + 80 * 2);
      expect(landscape.height, portrait.width - 80 * 2 + 80 + 60);
    });

    test('target is wider than emulated device', () {
      final profile = DeviceDatabase.defaultProfile;
      final size = WindowManagerSizingService.computeTargetSize(
        profile,
        DeviceOrientation.portrait,
      );
      expect(size.width, greaterThan(profile.logicalSize.width));
      expect(size.height, greaterThan(profile.logicalSize.height));
    });
  });

  group('PreviewController window sizing integration', () {
    late _SpySizingService spy;
    late PreviewController controller;

    setUp(() {
      spy = _SpySizingService();
      controller = PreviewController(windowSizingService: spy);
    });

    tearDown(() => controller.dispose());

    test(
      'setProfile calls applyProfile with new profile and current orientation',
      () {
        final target = DeviceDatabase.all.firstWhere(
          (p) => p.id != DeviceDatabase.defaultProfile.id,
        );
        controller.setProfile(target);
        expect(spy.calls, hasLength(1));
        expect(spy.calls.first, (target, DeviceOrientation.portrait));
      },
    );

    test('setProfile does not call service when profile is unchanged', () {
      controller.setProfile(controller.activeProfile);
      expect(spy.calls, isEmpty);
    });

    test('toggleOrientation calls applyProfile with new orientation', () {
      controller.toggleOrientation();
      expect(spy.calls, hasLength(1));
      expect(spy.calls.first, (
        controller.activeProfile,
        DeviceOrientation.landscape,
      ));
    });

    test('service receives correct orientation after second toggle', () {
      controller.toggleOrientation();
      controller.toggleOrientation();
      expect(spy.calls, hasLength(2));
      expect(spy.calls.last.$2, DeviceOrientation.portrait);
    });

    test('no service: setProfile and toggleOrientation work normally', () {
      final c = PreviewController();
      addTearDown(c.dispose);
      final target = DeviceDatabase.all.firstWhere(
        (p) => p.id != DeviceDatabase.defaultProfile.id,
      );
      c.setProfile(target);
      c.toggleOrientation();
      expect(c.activeProfile, target);
      expect(c.orientation, DeviceOrientation.landscape);
    });
  });

  group('PreviewController.notifyMetricsChanged', () {
    test('notifies listeners', () {
      final controller = PreviewController();
      addTearDown(controller.dispose);
      var count = 0;
      controller.addListener(() => count++);
      controller.notifyMetricsChanged();
      expect(count, 1);
    });
  });
}
