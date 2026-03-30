import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
    testWidgets('Ctrl+L toggles orientation', (tester) async {
      await _pump(tester, controller);
      expect(controller.orientation, isNot(isNull));
      final before = controller.orientation;

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

      expect(controller.orientation, isNot(equals(before)));

      // TODO: Test skipped as keyboard shortcuts are currently removed.
    }, skip: true);
  });
}
