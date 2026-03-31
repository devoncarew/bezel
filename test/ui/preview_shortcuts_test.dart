import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_database.dart';
import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/preview_controller.dart';
import 'package:flight_check/src/ui/preview_shortcuts.dart';

/// Pumps a [PreviewShortcuts] with a focusable child so key events are routed.
Future<void> _pump(WidgetTester tester, PreviewController controller) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => PreviewShortcuts(
        controller: controller,
        child: const Focus(autofocus: true, child: SizedBox.expand()),
      ),
    ),
  );
  // Let autofocus settle.
  await tester.pump();
}

void main() {
  late PreviewController controller;

  setUp(() => controller = PreviewController());
  tearDown(() => controller.dispose());

  group('PreviewShortcuts', () {
    testWidgets('Ctrl+D toggles device picker', (tester) async {
      await _pump(tester, controller);
      expect(controller.devicePickerVisible, isFalse);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

      expect(controller.devicePickerVisible, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

      expect(controller.devicePickerVisible, isFalse);
    });

    testWidgets('Ctrl+L toggles orientation', (tester) async {
      await _pump(tester, controller);
      expect(controller.orientation, DeviceOrientation.portrait);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

      expect(controller.orientation, DeviceOrientation.landscape);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

      expect(controller.orientation, DeviceOrientation.portrait);
    });

    testWidgets('Ctrl+] advances to the next device', (tester) async {
      await _pump(tester, controller);
      final before = controller.activeProfile;
      final expectedNext =
          DeviceDatabase.all[(DeviceDatabase.all.indexOf(before) + 1) %
              DeviceDatabase.all.length];

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

      expect(controller.activeProfile, equals(expectedNext));
    });

    testWidgets('Ctrl+[ goes back to the previous device', (tester) async {
      await _pump(tester, controller);
      final before = controller.activeProfile;
      final expectedPrev =
          DeviceDatabase.all[(DeviceDatabase.all.indexOf(before) -
                  1 +
                  DeviceDatabase.all.length) %
              DeviceDatabase.all.length];

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

      expect(controller.activeProfile, equals(expectedPrev));
    });
  });
}
