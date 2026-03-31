import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/devices/screen_border.dart';
import 'package:flight_check/src/devices/screen_cutout.dart';

void main() {
  // A reusable portrait size for rotation math checks.
  const portraitSize = Size(390, 844);

  DeviceProfile makeProfile({required ScreenCutout cutout}) {
    return DeviceProfile(
      id: 'test',
      name: 'Test Device',
      platform: DevicePlatform.iOS,
      logicalSize: portraitSize,
      safeAreaPortrait: const EdgeInsets.only(top: 59, bottom: 34),
      safeAreaLandscape: const EdgeInsets.only(left: 59, right: 59, bottom: 21),
      screenBorder: const CircularBorder(0),
      cutout: cutout,
    );
  }

  group('DeviceProfile.logicalSizeForOrientation', () {
    final profile = makeProfile(cutout: const NoCutout());

    test('portrait returns logicalSize unchanged', () {
      expect(
        profile.logicalSizeForOrientation(DeviceOrientation.portrait),
        portraitSize,
      );
    });

    test('landscape swaps width and height', () {
      final landscape = profile.logicalSizeForOrientation(
        DeviceOrientation.landscape,
      );
      expect(landscape.width, portraitSize.height);
      expect(landscape.height, portraitSize.width);
    });
  });

  group('DeviceProfile.safeAreaForOrientation', () {
    final profile = makeProfile(cutout: const NoCutout());

    test('portrait returns safeAreaPortrait', () {
      expect(
        profile.safeAreaForOrientation(DeviceOrientation.portrait),
        const EdgeInsets.only(top: 59, bottom: 34),
      );
    });

    test('landscape returns safeAreaLandscape', () {
      expect(
        profile.safeAreaForOrientation(DeviceOrientation.landscape),
        const EdgeInsets.only(left: 59, right: 59, bottom: 21),
      );
    });
  });

  group('ScreenCutout.buildPath', () {
    final screenRect = Offset.zero & portraitSize;

    test('NoCutout returns an empty path', () {
      final path = const NoCutout().buildPath(screenRect);
      expect(path.getBounds(), Rect.zero);
    });

    test('PunchHoleCutout returns a non-empty circular path', () {
      const cutout = PunchHoleCutout(diameter: 11, topOffset: 13);
      final path = cutout.buildPath(screenRect);
      final bounds = path.getBounds();
      expect(bounds.width, closeTo(11, 0.1));
      expect(bounds.height, closeTo(11, 0.1));
      // Centered horizontally on the screen.
      expect(bounds.center.dx, closeTo(portraitSize.width / 2, 0.1));
    });

    test('DynamicIslandCutout returns a pill-shaped path', () {
      const cutout = DynamicIslandCutout(size: Size(126, 37), topOffset: 11);
      final path = cutout.buildPath(screenRect);
      final bounds = path.getBounds();
      expect(bounds.width, closeTo(126, 0.1));
      expect(bounds.height, closeTo(37, 0.1));
      // Centered horizontally.
      expect(bounds.center.dx, closeTo(portraitSize.width / 2, 0.1));
    });

    test('NotchCutout returns a non-empty path at top center', () {
      const cutout = NotchCutout(size: Size(200, 30));
      final path = cutout.buildPath(screenRect);
      final bounds = path.getBounds();
      expect(bounds.width, closeTo(200, 0.1));
      expect(bounds.height, closeTo(30, 0.1));
      expect(bounds.center.dx, closeTo(portraitSize.width / 2, 0.1));
    });

    test('TeardropCutout returns a non-empty path at top center', () {
      const cutout = TeardropCutout(
        width: 44,
        height: 30,
        bottomRadius: 22,
        sideRadius: 13,
      );
      final path = cutout.buildPath(screenRect);
      final bounds = path.getBounds();
      // Wider than the notch width due to concave ears extending outward.
      expect(bounds.width, greaterThan(44));
      expect(bounds.height, closeTo(30, 0.1));
      expect(bounds.center.dx, closeTo(portraitSize.width / 2, 0.1));
    });

    test('PunchHoleCutout with explicit centerX positions correctly', () {
      const cutout = PunchHoleCutout(diameter: 11, topOffset: 13, centerX: 100);
      final path = cutout.buildPath(screenRect);
      final bounds = path.getBounds();
      expect(bounds.center.dx, closeTo(100, 0.1));
    });
  });
}
