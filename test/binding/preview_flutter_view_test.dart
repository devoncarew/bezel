import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/binding/preview_flutter_view.dart';
import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/preview_controller.dart';

void main() {
  // Initialize the test binding so we have a real FlutterView to use as _real.
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

  test('devicePixelRatio is min of width-ratio and height-ratio', () {
    final realPhysical = binding.platformDispatcher.implicitView!.physicalSize;
    final emulatedLogical = controller.emulatedLogicalSize;
    final expected = math.min(
      realPhysical.width / emulatedLogical.width,
      realPhysical.height / emulatedLogical.height,
    );
    expect(view.devicePixelRatio, closeTo(expected, 0.001));
  });

  test('physicalSize reflects emulated dimensions at current DPR', () {
    final dpr = view.devicePixelRatio;
    final emulated = controller.emulatedLogicalSize;
    expect(view.physicalSize.width, closeTo(emulated.width * dpr, 0.001));
    expect(view.physicalSize.height, closeTo(emulated.height * dpr, 0.001));
  });

  test(
    'physicalSize / devicePixelRatio always equals emulated logical size',
    () {
      final emulated = controller.emulatedLogicalSize;
      final logical = view.physicalSize / view.devicePixelRatio;
      expect(logical.width, closeTo(emulated.width, 0.001));
      expect(logical.height, closeTo(emulated.height, 0.001));
    },
  );

  test('devicePixelRatio updates when orientation toggles', () {
    final realPhysical = binding.platformDispatcher.implicitView!.physicalSize;
    controller.toggleOrientation();
    final emulatedLogical = controller.emulatedLogicalSize; // now landscape
    final expected = math.min(
      realPhysical.width / emulatedLogical.width,
      realPhysical.height / emulatedLogical.height,
    );
    expect(view.devicePixelRatio, closeTo(expected, 0.001));
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
