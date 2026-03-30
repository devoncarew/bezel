// ignore_for_file: avoid_print

import 'package:flight_check/src/devices/device_database.dart';
import 'package:flight_check/src/devices/device_profile.dart';
import 'package:flight_check/src/devices/screen_cutout.dart';
import 'package:flutter_test/flutter_test.dart';

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
      // Run with `flutter test test/devices/device_database_test.dart`.

      String size(DeviceProfile d) =>
          '${d.logicalSize.width.toInt()} × ${d.logicalSize.height.toInt()}';

      final iOS = DeviceDatabase.all.where(
        (d) => d.platform == DevicePlatform.iOS && !d.tablet,
      );
      final android = DeviceDatabase.all.where(
        (d) => d.platform == DevicePlatform.android && !d.tablet,
      );
      final tablets = DeviceDatabase.all.where((d) => d.tablet);

      print('## Supported devices');

      for (final devices in [iOS, android, tablets]) {
        print('');
        print('| Device | Size | Device category |');
        print('| --- | --- | --- |');

        for (final device in devices) {
          print(
            '| ${device.name} | ${size(device)} | ${device.description ?? ''} |',
          );
        }
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
