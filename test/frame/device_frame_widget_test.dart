import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/frame/device_frame_painter.dart';
import 'package:bezel/src/frame/device_frame_widget.dart';

void main() {
  group('DeviceFrameWidget', () {
    testWidgets('child size matches screenRectForSize', (tester) async {
      final profile = DeviceDatabase.findById('iphone_15')!;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DeviceFrameWidget(
            profile: profile,
            orientation: DeviceOrientation.portrait,
            child: const ColoredBox(
              color: Color(0xFF0000FF),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      // Use the actual rendered frame size so the test is independent of the
      // test viewport dimensions.
      final frameBox = tester.renderObject<RenderBox>(
        find.byType(DeviceFrameWidget),
      );
      final expectedScreen = DeviceFramePainter.screenRectForSize(
        frameBox.size,
        profile,
        DeviceOrientation.portrait,
      );

      final childBox = tester.renderObject<RenderBox>(find.byType(ColoredBox));
      expect(childBox.size.width, closeTo(expectedScreen.width, 0.5));
      expect(childBox.size.height, closeTo(expectedScreen.height, 0.5));
    });

    testWidgets('child is smaller than the full frame (bezels are present)', (
      tester,
    ) async {
      final profile = DeviceDatabase.findById('iphone_15')!;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DeviceFrameWidget(
            profile: profile,
            orientation: DeviceOrientation.portrait,
            child: const ColoredBox(
              color: Color(0xFF0000FF),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      final frameBox = tester.renderObject<RenderBox>(
        find.byType(DeviceFrameWidget),
      );
      final childBox = tester.renderObject<RenderBox>(find.byType(ColoredBox));

      expect(childBox.size.width, lessThan(frameBox.size.width));
      expect(childBox.size.height, lessThan(frameBox.size.height));
    });

    testWidgets('landscape child is wider than tall', (tester) async {
      final profile = DeviceDatabase.findById('iphone_15')!;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DeviceFrameWidget(
            profile: profile,
            orientation: DeviceOrientation.landscape,
            child: const ColoredBox(
              color: Color(0xFF00FF00),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      final childBox = tester.renderObject<RenderBox>(find.byType(ColoredBox));
      expect(childBox.size.width, greaterThan(childBox.size.height));
    });

    testWidgets('portrait child is taller than wide', (tester) async {
      final profile = DeviceDatabase.findById('iphone_15')!;

      // Set a portrait-shaped test viewport (300×550 logical pixels).
      tester.view.physicalSize = const Size(900, 1650);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DeviceFrameWidget(
            profile: profile,
            orientation: DeviceOrientation.portrait,
            child: const ColoredBox(
              color: Color(0xFFFF0000),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      final childBox = tester.renderObject<RenderBox>(find.byType(ColoredBox));
      expect(childBox.size.height, greaterThan(childBox.size.width));
    });

    testWidgets('renders all database profiles without throwing', (
      tester,
    ) async {
      for (final profile in DeviceDatabase.all) {
        for (final orientation in DeviceOrientation.values) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: DeviceFrameWidget(
                profile: profile,
                orientation: orientation,
                child: const SizedBox.expand(),
              ),
            ),
          );
          // No exception → pass.
        }
      }
    });
  });
}
