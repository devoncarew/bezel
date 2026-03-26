import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/frame/device_frame_widget.dart';
import 'package:bezel/src/preview_controller.dart';
import 'package:bezel/src/ui/device_picker.dart';
import 'package:bezel/src/ui/preview_overlay.dart';
import 'package:bezel/src/ui/preview_toolbar.dart';

void main() {
  group('PreviewOverlay', () {
    late PreviewController controller;

    setUp(() => controller = PreviewController());
    tearDown(() => controller.dispose());

    testWidgets('renders DeviceFrameWidget', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(DeviceFrameWidget), findsOneWidget);
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
          .widget<DeviceFrameWidget>(find.byType(DeviceFrameWidget))
          .profile;

      final next = DeviceDatabase.all.firstWhere((p) => p.id != before.id);
      controller.setProfile(next);
      await tester.pump();

      final after = tester
          .widget<DeviceFrameWidget>(find.byType(DeviceFrameWidget))
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
          .widget<DeviceFrameWidget>(find.byType(DeviceFrameWidget))
          .orientation;
      expect(before, DeviceOrientation.portrait);

      controller.toggleOrientation();
      await tester.pump();

      final after = tester
          .widget<DeviceFrameWidget>(find.byType(DeviceFrameWidget))
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

    testWidgets('hides PreviewToolbar when toolbarVisible is false', (
      tester,
    ) async {
      controller.toggleToolbar();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PreviewOverlay(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.byType(PreviewToolbar), findsNothing);
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
      expect(find.byType(DeviceFrameWidget), findsNothing);
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
    test('returns 1.0 when device fits within 90% of available space', () {
      // 390 <= 500 * 0.9 = 450, 844 <= 1000 * 0.9 = 900 → scale = 1.0
      final scale = PreviewOverlay.computeScale(
        const Size(500, 1000),
        const Size(390, 844),
      );
      expect(scale, equals(1.0));
    });

    test('scales down when device is larger than 90% of available space', () {
      // Device same size as window → neither fits within 90%
      const available = Size(390, 844);
      const emulated = Size(390, 844);
      final scale = PreviewOverlay.computeScale(available, emulated);
      expect(scale, lessThan(1.0));
      // Should be min(390/390, 844/844) * 0.9 = 0.9
      expect(scale, closeTo(0.9, 0.001));
    });

    test('scale is bounded by the tighter dimension', () {
      // Width fits (200 <= 400 * 0.9 = 360) but height does not (900 > 600 * 0.9 = 540)
      const available = Size(400, 600);
      const emulated = Size(200, 900);
      final scale = PreviewOverlay.computeScale(available, emulated);
      // min(400/200, 600/900) * 0.9 = min(2.0, 0.667) * 0.9 = 0.6
      expect(scale, closeTo(0.6, 0.001));
    });
  });
}
