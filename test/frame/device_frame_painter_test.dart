import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/devices/screen_cutout.dart';
import 'package:bezel/src/frame/device_frame_painter.dart';

void main() {
  // A helper that builds a DeviceProfile for a given frame style and cutout.
  DeviceProfile makeProfile({
    required DeviceFrameStyle frameStyle,
    ScreenCutout cutout = const NoCutout(),
    Size logicalSize = const Size(390, 844),
  }) {
    return DeviceProfile(
      id: 'test',
      name: 'Test',
      platform: DevicePlatform.iOS,
      logicalSize: logicalSize,
      devicePixelRatio: 3.0,
      safeAreaPortrait: const EdgeInsets.only(top: 59, bottom: 34),
      safeAreaLandscape: const EdgeInsets.only(left: 59, right: 59, bottom: 21),
      frameStyle: frameStyle,
      cutout: cutout,
    );
  }

  group('DeviceFramePainter.screenRectForSize', () {
    test('screen rect is contained within painter bounds', () {
      const painterSize = Size(390, 844);
      for (final style in DeviceFrameStyle.values) {
        final profile = makeProfile(frameStyle: style);
        final rect = DeviceFramePainter.screenRectForSize(
          painterSize,
          profile,
          DeviceOrientation.portrait,
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(painterSize.width));
        expect(rect.bottom, lessThanOrEqualTo(painterSize.height));
      }
    });

    test('classic portrait has larger top and bottom bezels than sides', () {
      const painterSize = Size(390, 844);
      final profile = makeProfile(frameStyle: DeviceFrameStyle.classic);
      final rect = DeviceFramePainter.screenRectForSize(
        painterSize,
        profile,
        DeviceOrientation.portrait,
      );
      final topBezel = rect.top;
      final bottomBezel = painterSize.height - rect.bottom;
      final sideBezel = rect.left;

      expect(topBezel, greaterThan(sideBezel));
      expect(bottomBezel, greaterThan(topBezel));
    });

    test(
      'classic landscape has larger left and right bezels than top/bottom',
      () {
        const painterSize = Size(844, 390);
        final profile = makeProfile(frameStyle: DeviceFrameStyle.classic);
        final rect = DeviceFramePainter.screenRectForSize(
          painterSize,
          profile,
          DeviceOrientation.landscape,
        );
        final leftBezel = rect.left;
        final rightBezel = painterSize.width - rect.right;
        final topBezel = rect.top;

        expect(leftBezel, greaterThan(topBezel));
        expect(rightBezel, greaterThan(leftBezel));
      },
    );

    test('modern styles have uniform small bezels in portrait', () {
      const painterSize = Size(390, 844);
      for (final style in [
        DeviceFrameStyle.dynamicIsland,
        DeviceFrameStyle.punchHole,
        DeviceFrameStyle.notch,
      ]) {
        final profile = makeProfile(frameStyle: style);
        final rect = DeviceFramePainter.screenRectForSize(
          painterSize,
          profile,
          DeviceOrientation.portrait,
        );
        // All four bezels should be equal for modern styles.
        expect(
          rect.left,
          equals(painterSize.width - rect.right),
          reason: 'style=$style left/right bezels differ',
        );
        expect(
          rect.top,
          equals(painterSize.height - rect.bottom),
          reason: 'style=$style top/bottom bezels differ',
        );
        expect(
          rect.left,
          equals(rect.top),
          reason: 'style=$style side/top bezels differ',
        );
      }
    });

    test('screen rect from a real database profile has a non-zero area', () {
      for (final profile in DeviceDatabase.all) {
        for (final orientation in DeviceOrientation.values) {
          const size = Size(400, 800);
          final rect = DeviceFramePainter.screenRectForSize(
            size,
            profile,
            orientation,
          );
          expect(
            rect.width,
            greaterThan(0),
            reason: '${profile.id} $orientation width=0',
          );
          expect(
            rect.height,
            greaterThan(0),
            reason: '${profile.id} $orientation height=0',
          );
        }
      }
    });
  });

  group('DeviceFramePainter rendering', () {
    // Verify that painting all four frame styles does not throw, and that the
    // CustomPaint widget builds without error.
    for (final style in DeviceFrameStyle.values) {
      testWidgets('renders $style without throwing', (tester) async {
        final profile = makeProfile(frameStyle: style);
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 390,
              height: 844,
              child: CustomPaint(
                painter: DeviceFramePainter(
                  profile: profile,
                  orientation: DeviceOrientation.portrait,
                ),
              ),
            ),
          ),
        );
        // No exception thrown → pass.
      });
    }

    testWidgets('NoCutout profile renders without exception', (tester) async {
      final profile = makeProfile(
        frameStyle: DeviceFrameStyle.classic,
        cutout: const NoCutout(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 844,
            child: CustomPaint(
              painter: DeviceFramePainter(
                profile: profile,
                orientation: DeviceOrientation.portrait,
              ),
            ),
          ),
        ),
      );
      // No exception thrown → pass.
    });

    testWidgets('DynamicIsland profile renders landscape without exception', (
      tester,
    ) async {
      final profile = DeviceDatabase.findById('iphone_15')!;
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 844,
            height: 390,
            child: CustomPaint(
              painter: DeviceFramePainter(
                profile: profile,
                orientation: DeviceOrientation.landscape,
              ),
            ),
          ),
        ),
      );
      // No exception thrown → pass.
    });
  });
}
