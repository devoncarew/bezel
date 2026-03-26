import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/preview_controller.dart';
import 'package:bezel/src/ui/preview_toolbar.dart';

/// Wraps [child] with the ancestors needed by Material-level widgets.
Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  late PreviewController controller;

  setUp(() => controller = PreviewController());
  tearDown(() => controller.dispose());

  group('PreviewToolbar', () {
    testWidgets('shows the active device name', (tester) async {
      await tester.pumpWidget(_wrap(PreviewToolbar(controller: controller)));

      expect(find.text(controller.activeProfile.name), findsOneWidget);
    });

    testWidgets('device name updates after setProfile', (tester) async {
      await tester.pumpWidget(_wrap(PreviewToolbar(controller: controller)));

      final next = DeviceDatabase.all.firstWhere(
        (p) => p.id != controller.activeProfile.id,
      );
      controller.setProfile(next);
      await tester.pump();

      expect(find.text(next.name), findsOneWidget);
    });

    testWidgets('tapping orientation button calls toggleOrientation', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(PreviewToolbar(controller: controller)));

      var toggled = false;
      controller.addListener(() => toggled = true);

      await tester.tap(find.byIcon(Icons.screen_rotation));
      expect(toggled, isTrue);
    });

    testWidgets('tapping passthrough button toggles passthroughMode', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(PreviewToolbar(controller: controller)));

      expect(controller.passthroughMode, isFalse);
      await tester.tap(find.byIcon(Icons.phone_android));
      expect(controller.passthroughMode, isTrue);
    });

    testWidgets('passthrough icon changes when passthroughMode is active', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(PreviewToolbar(controller: controller)));

      expect(find.byIcon(Icons.phone_android), findsOneWidget);
      expect(find.byIcon(Icons.crop_free), findsNothing);

      controller.togglePassthrough();
      await tester.pump();

      expect(find.byIcon(Icons.crop_free), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsNothing);
    });
  });
}
