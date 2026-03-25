import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/binding/preview_flutter_view.dart';
import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/preview_controller.dart';

void main() {
  // Initialise the test binding so we have a real FlutterView to use as _real.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late PreviewController controller;
  late PreviewFlutterView view;

  setUp(() {
    controller = PreviewController();
    view = PreviewFlutterView(
      binding.platformDispatcher.implicitView!,
      controller,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('devicePixelRatio returns the active profile value', () {
    final profile = DeviceDatabase.defaultProfile;
    expect(view.devicePixelRatio, profile.devicePixelRatio);
  });

  test('physicalSize equals logical size × devicePixelRatio', () {
    final profile = DeviceDatabase.defaultProfile;
    final expected =
        profile.logicalSizeForOrientation(DeviceOrientation.portrait) *
        profile.devicePixelRatio;
    expect(view.physicalSize, expected);
  });

  test('physicalSize updates when orientation toggles', () {
    controller.toggleOrientation();
    final profile = controller.activeProfile;
    final expected =
        profile.logicalSizeForOrientation(DeviceOrientation.landscape) *
        profile.devicePixelRatio;
    expect(view.physicalSize, expected);
  });

  test('padding.top returns the profile safe area top', () {
    final profile = DeviceDatabase.defaultProfile;
    expect(view.padding.top, profile.safeAreaPortrait.top);
  });

  test('viewPadding matches padding', () {
    expect(view.viewPadding.top, view.padding.top);
    expect(view.viewPadding.bottom, view.padding.bottom);
    expect(view.viewPadding.left, view.padding.left);
    expect(view.viewPadding.right, view.padding.right);
  });

  test('viewInsets is zero', () {
    expect(view.viewInsets.top, 0.0);
    expect(view.viewInsets.bottom, 0.0);
    expect(view.viewInsets.left, 0.0);
    expect(view.viewInsets.right, 0.0);
  });
}
