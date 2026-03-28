// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

import 'package:bezel/src/devices/device_database.dart';
import 'package:bezel/src/devices/device_profile.dart';
import 'package:bezel/src/devices/screen_cutout.dart';

void main() {
  group('DeviceDatabase.all', () {
    test('is non-empty', () {
      expect(DeviceDatabase.all, isNotEmpty);
    });

    test(
      'every profile has a non-null cutout (uses NoCutout rather than null)',
      () {
        for (final profile in DeviceDatabase.all) {
          // cutout is non-nullable; this confirms no profile omits the field.
          expect(profile.cutout, isA<ScreenCutout>());
        }
      },
    );

    test('every profile id is unique', () {
      final ids = DeviceDatabase.all.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('prints device list in markdown format', () {
      String size(DeviceProfile d) =>
          '${d.logicalSize.width.toInt()} × ${d.logicalSize.height.toInt()}';

      String platform(DeviceProfile d) =>
          d.platform.label + (d.tablet ? ' / tablet' : '');

      final iOS = DeviceDatabase.all
          .where((d) => d.platform == DevicePlatform.iOS && !d.tablet)
          .toList();
      final android = DeviceDatabase.all
          .where((d) => d.platform == DevicePlatform.android && !d.tablet)
          .toList();
      final tablets = DeviceDatabase.all.where((d) => d.tablet).toList();

      final devices = [...iOS, ...android, ...tablets];

      print('## Supported devices');
      print('');

      print('| Device | Size | Platform | Device category |');
      print('| --- | --- | --- | --- |');

      for (final device in devices) {
        print(
          '| ${device.name} | ${size(device)} | '
          '${platform(device)} | ${device.description ?? ''} |',
        );
      }

      print('');
    });
  });

  group('DeviceDatabase.forPlatform', () {
    test('returns only iOS profiles', () {
      final ios = DeviceDatabase.forPlatform(DevicePlatform.iOS);
      expect(ios, isNotEmpty);
      expect(ios.every((p) => p.platform == DevicePlatform.iOS), isTrue);
    });

    test('returns only Android profiles', () {
      final android = DeviceDatabase.forPlatform(DevicePlatform.android);
      expect(android, isNotEmpty);
      expect(
        android.every((p) => p.platform == DevicePlatform.android),
        isTrue,
      );
    });

    test('iOS and Android lists together cover all profiles', () {
      final ios = DeviceDatabase.forPlatform(DevicePlatform.iOS);
      final android = DeviceDatabase.forPlatform(DevicePlatform.android);
      expect(ios.length + android.length, DeviceDatabase.all.length);
    });
  });

  group('DeviceDatabase.findById', () {
    test('returns the matching profile', () {
      final profile = DeviceDatabase.findById('iphone_15');
      expect(profile, isNotNull);
      expect(profile!.id, 'iphone_15');
      expect(profile.name, 'iPhone 15');
    });

    test('returns null for an unknown id', () {
      expect(DeviceDatabase.findById('does_not_exist'), isNull);
    });
  });

  group('DeviceDatabase.defaultProfile', () {
    test('is contained in all', () {
      expect(DeviceDatabase.all, contains(DeviceDatabase.defaultProfile));
    });

    test('is the iPhone 15', () {
      expect(DeviceDatabase.defaultProfile.id, 'iphone_15');
    });
  });
}
