import 'dart:convert';
import 'dart:io';

const _kDeviceKey = 'lastDevice';

/// Returns the settings file path.
///
/// - macOS / Linux: `$HOME/.config/flight_check.json`
/// - Windows: `%APPDATA%\flight_check.json`
///
/// Returns `null` if the required environment variable is absent.
File? _settingsFile() {
  final String? dir;

  if (Platform.isWindows) {
    dir = Platform.environment['APPDATA'];
  } else {
    final home = Platform.environment['HOME'];
    dir = home == null ? null : '$home/.config';
  }

  if (dir == null) {
    return null;
  }

  return File('$dir${Platform.pathSeparator}flight_check.json');
}

Map<String, Object?> _readJson(File file) {
  try {
    if (!file.existsSync()) {
      return {};
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
  } catch (_) {}

  return {};
}

/// Reads the last-selected device ID from `.dart_tool/flight_check.json`.
///
/// Returns `null` if the file does not exist, cannot be read, or contains no
/// device entry. Silently swallows all errors.
String? loadLastDeviceId() {
  try {
    final file = _settingsFile();
    if (file == null) {
      return null;
    }
    return _readJson(file)[_kDeviceKey] as String?;
  } catch (_) {
    return null;
  }
}

/// Persists [id] as the last-selected device ID in `.dart_tool/flight_check.json`.
///
/// Reads the existing file before writing so that any other fields in the
/// object are preserved. Silently swallows all errors — persistence failures
/// should never surface to the user.
void saveLastDeviceId(String id) {
  try {
    final file = _settingsFile();
    if (file == null) {
      return;
    }

    final settings = _readJson(file);
    settings[_kDeviceKey] = id;

    // The $HOME/.config directory might not exist in some situations (on MacOS,
    // flutter run -d macos is sandboxed into an app specific directory).
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync();
    }

    final str = const JsonEncoder.withIndent('  ').convert(settings);
    file.writeAsStringSync('$str\n');
  } catch (_) {}
}
