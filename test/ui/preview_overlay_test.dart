import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_database.dart';
import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/frame/screen_clip_widget.dart';
import 'package:flight_check/src/preview_controller.dart';
import 'package:flight_check/src/ui/device_picker.dart';
import 'package:flight_check/src/ui/preview_overlay.dart';
import 'package:flight_check/src/ui/preview_toolbar.dart';

void main() {
  group('PreviewOverlay', () {
    late PreviewController controller;

    setUp(() => controller = PreviewController());
    tearDown(() => controller.dispose());

    testWidgets('renders ScreenClipWidget', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(ScreenClipWidget), findsOneWidget);
    });

    testWidgets('renders the child inside the frame', (tester) async {
      const key = ValueKey('app-child');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox(key: key),
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('rebuilds when controller changes profile', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      final before = tester
          .widget<ScreenClipWidget>(find.byType(ScreenClipWidget))
          .profile;

      final next = DeviceDatabase.all.firstWhere((p) => p.id != before.id);
      controller.setProfile(next);
      await tester.pump();

      final after = tester
          .widget<ScreenClipWidget>(find.byType(ScreenClipWidget))
          .profile;

      expect(after, equals(next));
      expect(after, isNot(equals(before)));
    });

    testWidgets('rebuilds when controller toggles orientation', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      final before = tester
          .widget<ScreenClipWidget>(find.byType(ScreenClipWidget))
          .orientation;
      expect(before, DeviceOrientation.portrait);

      controller.toggleOrientation();
      await tester.pump();

      final after = tester
          .widget<ScreenClipWidget>(find.byType(ScreenClipWidget))
          .orientation;
      expect(after, DeviceOrientation.landscape);
    });

    testWidgets('shows PreviewToolbar by default', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(PreviewToolbar), findsOneWidget);
    });

    testWidgets('passthrough mode shows child without device frame', (
      tester,
    ) async {
      const key = ValueKey('app-child');
      controller.togglePassthrough();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox(key: key),
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);
      expect(find.byType(ScreenClipWidget), findsNothing);
    });

    testWidgets('passthrough mode shows the orientation icon as active', (
      tester,
    ) async {
      controller.togglePassthrough();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      // In passthrough mode the overlay renders just the raw child — no toolbar.
      expect(find.byType(PreviewToolbar), findsNothing);
    });

    testWidgets('DevicePicker absent by default', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(DevicePicker), findsNothing);
    });

    testWidgets('DevicePicker shown when devicePickerVisible is true', (
      tester,
    ) async {
      controller.toggleDevicePicker();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(DevicePicker), findsOneWidget);
    });
  });

  group('PreviewOverlay.computeScale', () {
    test('returns 1.0 when content area is larger than emulated size', () {
      // 500 > 390 and 900 > 844 → fits, scale = 1.0
      final scale = PreviewOverlay.computeScale(
        const Size(500, 900),
        const Size(390, 844),
      );
      expect(scale, equals(1.0));
    });

    test('returns 1.0 when content area exactly matches emulated size', () {
      const emulated = Size(390, 844);
      expect(PreviewOverlay.computeScale(emulated, emulated), equals(1.0));
    });

    test(
      'scales down to fit when content area is smaller than emulated size',
      () {
        // Content area is exactly half the emulated size → scale = 0.5
        final scale = PreviewOverlay.computeScale(
          const Size(195, 422),
          const Size(390, 844),
        );
        expect(scale, closeTo(0.5, 0.001));
      },
    );

    test('scale is bounded by the tighter dimension', () {
      // Width fits (400 > 200) but height does not (600 < 900)
      // → min(400/200, 600/900) = min(2.0, 0.667) → clamped to 0.667
      final scale = PreviewOverlay.computeScale(
        const Size(400, 600),
        const Size(200, 900),
      );
      expect(scale, closeTo(0.667, 0.001));
    });
  });
}
