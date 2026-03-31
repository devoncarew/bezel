import 'dart:io' show Platform;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_check/src/devices/device_database.dart';
import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/preview_controller.dart';
import 'package:flight_check/src/ui/preview_shortcuts.dart';

/// The modifier key used by [PreviewShortcuts] on the current host platform.
final _modifier = Platform.isMacOS
    ? LogicalKeyboardKey.meta
    : LogicalKeyboardKey.control;

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

Future<void> _sendShortcut(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(_modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(_modifier);
}

void main() {
  late PreviewController controller;

  setUp(() => controller = PreviewController());
  tearDown(() => controller.dispose());

  group('PreviewShortcuts', () {
    testWidgets('modifier+D toggles device picker', (tester) async {
      await _pump(tester, controller);
      expect(controller.devicePickerVisible, isFalse);

      await _sendShortcut(tester, LogicalKeyboardKey.keyD);
      expect(controller.devicePickerVisible, isTrue);

      await _sendShortcut(tester, LogicalKeyboardKey.keyD);
      expect(controller.devicePickerVisible, isFalse);
    });

    testWidgets('modifier+L toggles orientation', (tester) async {
      await _pump(tester, controller);
      expect(controller.orientation, DeviceOrientation.portrait);

      await _sendShortcut(tester, LogicalKeyboardKey.keyL);
      expect(controller.orientation, DeviceOrientation.landscape);

      await _sendShortcut(tester, LogicalKeyboardKey.keyL);
      expect(controller.orientation, DeviceOrientation.portrait);
    });

    testWidgets('modifier+] advances to the next device', (tester) async {
      await _pump(tester, controller);
      final before = controller.activeProfile;
      final expectedNext =
          DeviceDatabase.all[(DeviceDatabase.all.indexOf(before) + 1) %
              DeviceDatabase.all.length];

      await _sendShortcut(tester, LogicalKeyboardKey.bracketRight);

      expect(controller.activeProfile, equals(expectedNext));
    });

    testWidgets('modifier+[ goes back to the previous device', (tester) async {
      await _pump(tester, controller);
      final before = controller.activeProfile;
      final expectedPrev =
          DeviceDatabase.all[(DeviceDatabase.all.indexOf(before) -
                  1 +
                  DeviceDatabase.all.length) %
              DeviceDatabase.all.length];

      await _sendShortcut(tester, LogicalKeyboardKey.bracketLeft);

      expect(controller.activeProfile, equals(expectedPrev));
    });
  });
}
