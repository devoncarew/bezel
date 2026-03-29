import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_database.dart';
import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/devices/screen_cutout.dart';
import 'package:flight_check/src/frame/screen_clip_painter.dart';

void main() {
  // A helper that builds a DeviceProfile for a given cutout.
  DeviceProfile makeProfile({
    ScreenCutout cutout = const NoCutout(),
    Size logicalSize = const Size(390, 844),
  }) {
    return DeviceProfile(
      id: 'test',
      name: 'Test',
      platform: DevicePlatform.iOS,
      logicalSize: logicalSize,
      safeAreaPortrait: const EdgeInsets.only(top: 59, bottom: 34),
      safeAreaLandscape: const EdgeInsets.only(left: 59, right: 59, bottom: 21),
      screenCornerRadius: 0,
      cutout: cutout,
    );
  }

  group('ScreenClipPainter.screenRectForSize', () {
    test('screen rect equals full painter bounds', () {
      const painterSize = Size(390, 844);
      for (final profile in DeviceDatabase.all) {
        final rect = ScreenClipPainter.screenRectForSize(
          painterSize,
          profile,
          DeviceOrientation.portrait,
        );
        expect(rect, equals(Offset.zero & painterSize));
      }
    });

    test('screen rect from a real database profile has a non-zero area', () {
      for (final profile in DeviceDatabase.all) {
        for (final orientation in DeviceOrientation.values) {
          const size = Size(400, 800);
          final rect = ScreenClipPainter.screenRectForSize(
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

  group('ScreenClipPainter.buildClipPath teardrop', () {
    // Screen geometry matching the Galaxy A15 profile.
    const screenSize = Size(411, 892);
    const cutout = TeardropCutout(
      width: 44,
      height: 31,
      bottomRadius: 22,
      sideRadius: 7,
    );

    late Path clipPath;

    setUp(() {
      final profile = makeProfile(cutout: cutout, logicalSize: screenSize);
      clipPath = ScreenClipPainter.buildClipPath(
        screenSize,
        profile,
        DeviceOrientation.portrait,
      );
    });

    test('clip path has screen-sized bounds', () {
      final bounds = clipPath.getBounds();
      expect(bounds.width, closeTo(screenSize.width, 1.0));
      expect(bounds.height, closeTo(screenSize.height, 1.0));
    });

    test('center of notch body is clipped out', () {
      // 15 dp down at the horizontal center — well inside the teardrop body.
      final cx = screenSize.width / 2;
      expect(
        clipPath.contains(Offset(cx, 15)),
        isFalse,
        reason: 'notch body center should be outside the clip path',
      );
    });

    test('far below notch is visible', () {
      final cx = screenSize.width / 2;
      expect(
        clipPath.contains(Offset(cx, 50)),
        isTrue,
        reason: 'below the notch should be inside the clip path',
      );
    });

    test('screen sides at notch depth are visible', () {
      // Left and right edges at the same y as the notch — outside the notch width.
      expect(
        clipPath.contains(const Offset(10, 15)),
        isTrue,
        reason: 'left edge at notch depth should be visible',
      );
      expect(
        clipPath.contains(Offset(screenSize.width - 10, 15)),
        isTrue,
        reason: 'right edge at notch depth should be visible',
      );
    });
  });

  group('ScreenClipPainter rendering', () {
    // Verify that every real database profile renders without throwing.
    for (final profile in DeviceDatabase.all) {
      testWidgets('renders ${profile.id} without throwing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 390,
              height: 844,
              child: CustomPaint(
                painter: ScreenClipPainter(
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
      final profile = makeProfile(cutout: const NoCutout());
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 844,
            child: CustomPaint(
              painter: ScreenClipPainter(
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
              painter: ScreenClipPainter(
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
