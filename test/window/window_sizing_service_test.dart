import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_database.dart';
import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/window/window_manager_sizing_service.dart';
import 'package:flight_check/src/window/window_sizing_service.dart';
import 'package:flight_check/src/preview_controller.dart';

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
    test('portrait target is scaled version of device logical size', () {
      final profile = DeviceDatabase.defaultProfile;
      final size = WindowManagerSizingService.computeTargetSize(
        profile,
        DeviceOrientation.portrait,
      );
      expect(size.width, inInclusiveRange(profile.logicalSize.width * 0.88, profile.logicalSize.width));
      expect(size.height, inInclusiveRange(profile.logicalSize.height * 0.88, profile.logicalSize.height));
    });

    test('landscape target uses swapped emulated dimensions', () {
      final profile = DeviceDatabase.defaultProfile;
      final landscape = WindowManagerSizingService.computeTargetSize(
        profile,
        DeviceOrientation.landscape,
      );
      expect(landscape.width, inInclusiveRange(profile.logicalSize.height * 0.88, profile.logicalSize.height));
      expect(landscape.height, inInclusiveRange(profile.logicalSize.width * 0.88, profile.logicalSize.width));
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
