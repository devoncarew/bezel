import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_database.dart';
import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/frame/screen_clip_widget.dart';

void main() {
  group('ScreenClipWidget', () {
    testWidgets('child fills the full widget bounds', (tester) async {
      final profile = DeviceDatabase.findById('iphone_15')!;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenClipWidget(
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
        find.byType(ScreenClipWidget),
      );
      final childBox = tester.renderObject<RenderBox>(find.byType(ColoredBox));
      expect(childBox.size.width, closeTo(frameBox.size.width, 0.5));
      expect(childBox.size.height, closeTo(frameBox.size.height, 0.5));
    });

    testWidgets('landscape child is wider than tall', (tester) async {
      final profile = DeviceDatabase.findById('iphone_15')!;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ScreenClipWidget(
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
          child: ScreenClipWidget(
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
              child: ScreenClipWidget(
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
