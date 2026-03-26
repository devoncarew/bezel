import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/devices/screen_cutout.dart';
import 'package:bezel/src/frame/screen_clip_painter.dart';

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
      devicePixelRatio: 3.0,
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
