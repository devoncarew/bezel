import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/preview_controller.dart';
import 'package:bezel/src/ui/macos_menu.dart';

const _kChildKey = Key('child');

Future<void> _pump(WidgetTester tester, PreviewController controller) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => MacosPreviewMenu(
        controller: controller,
        child: const SizedBox.expand(key: _kChildKey),
      ),
    ),
  );
}

/// Recursively collects all leaf [PlatformMenuItem]s (not [PlatformMenu] or
/// [PlatformMenuItemGroup]) from [list].
List<PlatformMenuItem> _collectLeaves(List<PlatformMenuItem> list) {
  final result = <PlatformMenuItem>[];
  for (final m in list) {
    if (m is PlatformMenu) {
      result.addAll(_collectLeaves(m.menus));
    } else if (m is PlatformMenuItemGroup) {
      result.addAll(_collectLeaves(m.members));
    } else {
      result.add(m);
    }
  }
  return result;
}

void main() {
  late PreviewController controller;

  setUp(() => controller = PreviewController());
  tearDown(() => controller.dispose());

  group('MacosPreviewMenu — non-macOS passthrough', () {
    testWidgets('returns child unchanged on non-macOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await _pump(tester, controller);
        expect(find.byKey(_kChildKey), findsOneWidget);
        expect(find.byType(PlatformMenuBar), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('MacosPreviewMenu — macOS', () {
    testWidgets('wraps child in PlatformMenuBar on macOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pump(tester, controller);
        expect(find.byKey(_kChildKey), findsOneWidget);
        expect(find.byType(PlatformMenuBar), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('menu contains an item for every device profile', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pump(tester, controller);

        final menuBar = tester.widget<PlatformMenuBar>(
          find.byType(PlatformMenuBar),
        );
        expect(menuBar.menus.length, 1);
        final previewMenu = menuBar.menus.first as PlatformMenu;
        expect(previewMenu.label, 'Preview');

        final leaves = _collectLeaves(previewMenu.menus);
        // One item per device plus Toggle Orientation and Reassemble.
        expect(leaves.length, DeviceDatabase.all.length + 2);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('active profile has check-mark prefix', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final profile = DeviceDatabase.findById('iphone_15')!;
        controller.setProfile(profile);
        await _pump(tester, controller);

        final menuBar = tester.widget<PlatformMenuBar>(
          find.byType(PlatformMenuBar),
        );
        final previewMenu = menuBar.menus.first as PlatformMenu;
        final leaves = _collectLeaves(previewMenu.menus);

        // endsWith avoids matching 'iPhone 15 Pro' when looking for 'iPhone 15'.
        final item = leaves.firstWhere((m) => m.label.endsWith(profile.name));
        expect(item.label, startsWith('\u2713'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('selecting a device item updates the controller', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pump(tester, controller);

        final target = DeviceDatabase.forPlatform(DevicePlatform.android).first;
        final menuBar = tester.widget<PlatformMenuBar>(
          find.byType(PlatformMenuBar),
        );
        final previewMenu = menuBar.menus.first as PlatformMenu;
        final leaves = _collectLeaves(previewMenu.menus);

        final item = leaves.firstWhere((m) => m.label.endsWith(target.name));
        item.onSelected!();

        expect(controller.activeProfile, equals(target));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('toggle orientation item calls toggleOrientation', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pump(tester, controller);
        final before = controller.orientation;

        final menuBar = tester.widget<PlatformMenuBar>(
          find.byType(PlatformMenuBar),
        );
        final previewMenu = menuBar.menus.first as PlatformMenu;
        final leaves = _collectLeaves(previewMenu.menus);

        final item = leaves.firstWhere((m) => m.label == 'Toggle Orientation');
        item.onSelected!();

        expect(controller.orientation, isNot(equals(before)));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
