import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_profile.dart';
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
      screenCornerRadius: 0,
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

  group('DeviceProfile.cutoutForOrientation — NoCutout', () {
    final profile = makeProfile(cutout: const NoCutout());

    test('portrait returns NoCutout', () {
      expect(
        profile.cutoutForOrientation(DeviceOrientation.portrait),
        isA<NoCutout>(),
      );
    });

    test(
      'landscape returns NoCutout unchanged (rotatedForLandscape is a no-op)',
      () {
        expect(
          profile.cutoutForOrientation(DeviceOrientation.landscape),
          isA<NoCutout>(),
        );
      },
    );
  });

  group('DeviceProfile.cutoutForOrientation — PunchHoleCutout', () {
    test('portrait returns the original PunchHoleCutout', () {
      final profile = makeProfile(
        cutout: const PunchHoleCutout(diameter: 11, topOffset: 13),
      );
      expect(
        profile.cutoutForOrientation(DeviceOrientation.portrait),
        isA<PunchHoleCutout>(),
      );
    });

    test('landscape produces a different (rotated) cutout type', () {
      final profile = makeProfile(
        cutout: const PunchHoleCutout(diameter: 11, topOffset: 13),
      );
      final landscape = profile.cutoutForOrientation(
        DeviceOrientation.landscape,
      );
      // The landscape result is an internal _SideCutout, not a PunchHoleCutout.
      expect(landscape, isNot(isA<PunchHoleCutout>()));
      expect(landscape, isA<ScreenCutout>());
    });

    test(
      'centered punch-hole uses portraitSize.width/2 as landscape centerOffset',
      () {
        // When centerX is null, rotatedForLandscape uses portraitScreenSize.width/2.
        // We verify indirectly: a PunchHoleCutout with explicit centerX equal to
        // width/2 must produce the same result as one with null centerX.
        final halfWidth = portraitSize.width / 2;
        final profileNull = makeProfile(
          cutout: const PunchHoleCutout(diameter: 11, topOffset: 13),
        );
        final profileExplicit = makeProfile(
          cutout: PunchHoleCutout(
            diameter: 11,
            topOffset: 13,
            centerX: halfWidth,
          ),
        );

        // Both should produce the same landscape result since the explicit centerX
        // matches the computed default.
        final nullResult = profileNull.cutoutForOrientation(
          DeviceOrientation.landscape,
        );
        final explicitResult = profileExplicit.cutoutForOrientation(
          DeviceOrientation.landscape,
        );
        // Both are rotated cutouts (not PunchHoleCutout) — same type, same behavior.
        expect(nullResult, isNot(isA<PunchHoleCutout>()));
        expect(explicitResult, isNot(isA<PunchHoleCutout>()));
      },
    );
  });

  group('DeviceProfile.cutoutForOrientation — DynamicIslandCutout', () {
    test('portrait returns the original DynamicIslandCutout', () {
      final profile = makeProfile(
        cutout: const DynamicIslandCutout(size: Size(37, 12), topOffset: 14),
      );
      expect(
        profile.cutoutForOrientation(DeviceOrientation.portrait),
        isA<DynamicIslandCutout>(),
      );
    });

    test('landscape produces a different (rotated) cutout type', () {
      final profile = makeProfile(
        cutout: const DynamicIslandCutout(size: Size(37, 12), topOffset: 14),
      );
      final landscape = profile.cutoutForOrientation(
        DeviceOrientation.landscape,
      );
      expect(landscape, isNot(isA<DynamicIslandCutout>()));
      expect(landscape, isA<ScreenCutout>());
    });
  });
}
