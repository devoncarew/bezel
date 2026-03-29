// ignore_for_file: avoid_print

// Extracts screen corner radii, corner Bézier control points, and notch
// geometry from iOS Simulator `.simdevicetype` bundles.
//
// Usage:
//   dart run tool/extract_simdevicetype.dart [filter]
//
// [filter] is an optional case-insensitive substring matched against the
// device name, e.g. "iPhone 14" or "15 pro".
//
// Requires macOS with Xcode / CoreSimulator installed.
//
// For each matching bundle the tool reads:
//   - `profile.plist` → physical dimensions, scale factor, PDF file names
//   - `{framebufferMask}.pdf` → screen-outline path in physical pixels;
//     used to derive the screen corner radius and corner Bézier segments
//   - `{sensorBarImage}.pdf` → notch / DI area path in logical points;
//     empty for Dynamic Island devices
//
// See docs/notch-research.md for background and a summary table
// of extracted values.

import 'dart:convert';
import 'dart:io';

const _kDeviceTypesDir =
    '/Library/Developer/CoreSimulator/Profiles/DeviceTypes';

Future<void> main(List<String> args) async {
  final filter = args.isNotEmpty ? args.join(' ').toLowerCase() : null;

  final dir = Directory(_kDeviceTypesDir);
  if (!dir.existsSync()) {
    stderr.writeln(
      'CoreSimulator DeviceTypes directory not found:\n  $_kDeviceTypesDir',
    );
    exit(1);
  }

  final bundles =
      dir
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path.endsWith('.simdevicetype'))
          .where(
            (d) =>
                filter == null ||
                d.path.split('/').last.toLowerCase().contains(filter),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  if (bundles.isEmpty) {
    stderr.writeln(
      'No .simdevicetype bundles found'
      '${filter != null ? ' matching "$filter"' : ''}',
    );
    exit(1);
  }

  for (final bundle in bundles) {
    await _processBundle(bundle);
  }
}

Future<void> _processBundle(Directory bundle) async {
  final name = bundle.path.split('/').last.replaceAll('.simdevicetype', '');
  final resources = Directory('${bundle.path}/Contents/Resources');
  if (!resources.existsSync()) return;

  final profile = await _parsePlist('${resources.path}/profile.plist');
  if (profile == null) return;

  final physW = (profile['mainScreenWidth'] as num?)?.toDouble();
  final physH = (profile['mainScreenHeight'] as num?)?.toDouble();
  final scale = (profile['mainScreenScale'] as num?)?.toDouble();
  if (physW == null || physH == null || scale == null) return;

  final logW = (physW / scale).round();
  final logH = (physH / scale).round();

  print('## $name');
  print(
    '   Physical: ${physW.toInt()} × ${physH.toInt()} px  '
    '| Scale: ${scale}x  '
    '| Logical: $logW × $logH pt',
  );

  // ── Corner radius and Bézier from framebuffer mask ───────────────────────

  final fbId = profile['framebufferMask'] as String?;
  if (fbId != null) {
    final fbPdf = File('${resources.path}/$fbId.pdf');
    if (fbPdf.existsSync()) {
      final radiusPt = await _extractCornerRadius(
        fbPdf,
        screenWidthPx: physW,
        screenHeightPx: physH,
        scale: scale,
      );
      if (radiusPt != null) {
        final radiusPx = radiusPt * scale;
        print(
          '   Corner radius: ${radiusPt.toStringAsFixed(1)} pt  '
          '(${radiusPx.toStringAsFixed(1)} px physical)',
        );
      } else {
        print('   Corner radius: could not extract from $fbId.pdf');
      }
      await _printCornerBezier(
        fbPdf,
        screenWidthPx: physW,
        screenHeightPx: physH,
        scale: scale,
      );
    }
  }

  // ── Sensor bar (notch / Dynamic Island) ─────────────────────────────────

  final sbName = profile['sensorBarImage'] as String?;
  if (sbName != null) {
    final sbPdf = File('${resources.path}/$sbName.pdf');
    if (sbPdf.existsSync()) {
      await _printSensorBar(sbPdf, sensorBarName: sbName, scale: scale);
    }
  }

  print('');
}

// ── Path parsing ─────────────────────────────────────────────────────────────

/// One logical step in a PDF path content stream.
///
/// - `m` / `l`:  args = `[x, y]`
/// - `c`:        args = `[cp1x, cp1y, cp2x, cp2y, x, y]`
/// - Other ops:  args = whatever numbers preceded the operator (may be empty)
class _PathOp {
  final String op;
  final List<double> args;
  const _PathOp(this.op, this.args);
}

/// Parses a PDF path content stream into a flat list of [_PathOp]s.
///
/// Multiple coordinate pairs before a single `l` or `m` produce one [_PathOp]
/// per pair. Multiple 6-tuples before a `c` produce one [_PathOp] per tuple.
List<_PathOp> _parsePathOperations(String stream) {
  final result = <_PathOp>[];
  final nums = <double>[];

  for (final tok in _tokenize(stream)) {
    final n = double.tryParse(tok);
    if (n != null) {
      nums.add(n);
    } else {
      switch (tok) {
        case 'm':
        case 'l':
          for (var i = 0; i + 1 < nums.length; i += 2) {
            result.add(_PathOp(tok, [nums[i], nums[i + 1]]));
          }
        case 'c':
          for (var i = 0; i + 5 < nums.length; i += 6) {
            result.add(_PathOp(tok, nums.sublist(i, i + 6)));
          }
        default:
          result.add(_PathOp(tok, List.of(nums)));
      }
      nums.clear();
    }
  }
  return result;
}

// ── Corner radius ─────────────────────────────────────────────────────────────

/// Extracts the screen corner radius from a framebuffer mask PDF.
///
/// The PDF path is in physical pixels. The algorithm finds all `l` / `m`
/// coordinates that lie on the top edge (y == [screenHeightPx]), takes the
/// rightmost one as the corner tangent point, then computes:
///   corner_radius_px = screenWidthPx - tangent_x
///   corner_radius_pt = corner_radius_px / scale
Future<double?> _extractCornerRadius(
  File pdfFile, {
  required double screenWidthPx,
  required double screenHeightPx,
  required double scale,
}) async {
  final stream = await _extractPathStream(pdfFile);
  if (stream == null) return null;

  final ops = _parsePathOperations(stream);
  final topEdgeX = <double>[];

  for (final op in ops) {
    if (op.op == 'm' || op.op == 'l') {
      final x = op.args[0];
      final y = op.args[1];
      // Accept points on the top edge within 1px tolerance.
      if ((y - screenHeightPx).abs() < 1.0 && x < screenWidthPx - 1) {
        topEdgeX.add(x);
      }
    }
  }

  if (topEdgeX.isEmpty) return null;

  final tangentX = topEdgeX.reduce((a, b) => a > b ? a : b);
  return (screenWidthPx - tangentX) / scale;
}

// ── Corner Bézier ─────────────────────────────────────────────────────────────

/// Extracts and prints the Bézier control points for the screen corner found
/// in the framebuffer mask PDF.
///
/// Finds the rightmost `l`/`m` point on the top edge of the screen outline
/// (the tangent where the straight top edge meets the corner curve), then
/// collects the consecutive `c` operations that follow it. These `c` segments
/// form one corner of the squircle.
///
/// Coordinates are converted from physical pixels (PDF convention: y=0 at
/// bottom) to Flutter logical points (origin at top-left, y increases
/// downward):
///   flutter_x = pdf_x / scale
///   flutter_y = logH − pdf_y / scale
///
/// The extracted corner is the top-right corner in user-facing coordinates
/// (x ≈ logW, y ≈ 0). By symmetry all four corners are identical; step 5.4
/// reflects/rotates this corner to construct the full squircle clip path.
Future<void> _printCornerBezier(
  File pdfFile, {
  required double screenWidthPx,
  required double screenHeightPx,
  required double scale,
}) async {
  final stream = await _extractPathStream(pdfFile);
  if (stream == null) return;

  final ops = _parsePathOperations(stream);
  final logH = screenHeightPx / scale;

  // Find the rightmost l/m point on the top edge — the tangent where the
  // straight top edge meets the corner curve.
  double maxTangentX = -1;
  int tangentIdx = -1;
  for (var i = 0; i < ops.length; i++) {
    final op = ops[i];
    if (op.op == 'm' || op.op == 'l') {
      final x = op.args[0];
      final y = op.args[1];
      if ((y - screenHeightPx).abs() < 1.0 &&
          x > maxTangentX &&
          x < screenWidthPx - 1) {
        maxTangentX = x;
        tangentIdx = i;
      }
    }
  }
  if (tangentIdx < 0) return;

  // Collect consecutive 'c' operations immediately following the tangent.
  // These are the Bézier segments that form the screen corner curve.
  final segs = <List<double>>[];
  for (var i = tangentIdx + 1; i < ops.length; i++) {
    if (ops[i].op != 'c') break;
    final raw = ops[i].args;
    // Convert physical px (PDF y-up) → Flutter logical pts (y-down):
    //   flutter_x = pdf_x / scale
    //   flutter_y = logH - pdf_y / scale
    segs.add([
      raw[0] / scale,
      logH - raw[1] / scale,
      raw[2] / scale,
      logH - raw[3] / scale,
      raw[4] / scale,
      logH - raw[5] / scale,
    ]);
  }
  if (segs.isEmpty) return;

  // Tangent on the top edge in Flutter coordinates (y = 0 because it's on the
  // top edge: pdf_y = screenHeightPx → flutter_y = logH - logH = 0).
  final fromX = maxTangentX / scale;
  const fromY = 0.0;

  // The end of the last segment is the tangent on the right edge.
  final toX = segs.last[4];
  final toY = segs.last[5];

  String f(double v) => v.toStringAsFixed(2);
  print(
    '   Corner Bézier (top-right; Flutter logical pts — '
    'origin top-left, y increases downward):',
  );
  print('      From (${f(fromX)}, ${f(fromY)}) [tangent on top edge]');
  for (final seg in segs) {
    print(
      '      c  cp1=(${f(seg[0])}, ${f(seg[1])})'
      '  cp2=(${f(seg[2])}, ${f(seg[3])})'
      '  →(${f(seg[4])}, ${f(seg[5])})',
    );
  }
  print('      To (${f(toX)}, ${f(toY)}) [tangent on right edge]');
}

// ── Sensor bar ────────────────────────────────────────────────────────────────

/// Prints sensor-bar information from the PDF.
///
/// Dynamic Island devices produce an empty path (`q Q`); pre-DI devices
/// contain a Bézier notch path with MediaBox in logical points.
Future<void> _printSensorBar(
  File pdfFile, {
  required String sensorBarName,
  required double scale,
}) async {
  final mediaBox = await _extractMediaBox(pdfFile);
  final stream = await _extractPathStream(pdfFile);

  if (stream == null || stream.trim() == 'q Q') {
    print(
      '   Sensor bar ($sensorBarName): empty — Dynamic Island (drawn in code)',
    );
    return;
  }

  if (mediaBox != null) {
    print(
      '   Sensor bar ($sensorBarName): '
      'MediaBox ${mediaBox[2].toStringAsFixed(0)} × ${mediaBox[3].toStringAsFixed(0)} pt',
    );
  }

  // Print bounding box as a quick summary.
  final bounds = _pathBounds(stream);
  if (bounds != null) {
    final w = bounds[2] - bounds[0];
    final h = bounds[3] - bounds[1];
    print(
      '   Notch path bounds: '
      '${w.toStringAsFixed(1)} × ${h.toStringAsFixed(1)} pt  '
      '(x: ${bounds[0].toStringAsFixed(1)}–${bounds[2].toStringAsFixed(1)}, '
      'y: ${bounds[1].toStringAsFixed(1)}–${bounds[3].toStringAsFixed(1)})',
    );
  }

  // Print the structured Bézier path. The sensor bar PDF is already in logical
  // points (MediaBox matches the notch area in pts). PDF y-axis: y=0 at the
  // bottom of the MediaBox, y increases upward.
  final ops = _parsePathOperations(stream);
  final drawOps = ops.where((op) => op.op != 'q' && op.op != 'Q').toList();
  if (drawOps.isNotEmpty) {
    print('   Bézier path (logical pts, PDF y=0 at bottom of MediaBox):');
    for (final op in drawOps) {
      String f(double v) => v.toStringAsFixed(3);
      switch (op.op) {
        case 'm':
          print('      m  (${f(op.args[0])}, ${f(op.args[1])})');
        case 'l':
          print('      l  (${f(op.args[0])}, ${f(op.args[1])})');
        case 'c':
          final a = op.args;
          print(
            '      c  cp1=(${f(a[0])}, ${f(a[1])})'
            '  cp2=(${f(a[2])}, ${f(a[3])})'
            '  →(${f(a[4])}, ${f(a[5])})',
          );
        case 'z':
          print('      z');
        default:
          if (op.args.isNotEmpty) {
            print('      ${op.op}  ${op.args.map(f).join(' ')}');
          } else {
            print('      ${op.op}');
          }
      }
    }
  }
}

/// Returns [xMin, yMin, xMax, yMax] for all numeric pairs in [pathData].
///
/// This is a rough approximation: it collects all numbers and interprets
/// consecutive pairs as (x, y). Operator tokens are stripped first.
List<double>? _pathBounds(String pathData) {
  final numbers = <double>[];
  for (final tok in _tokenize(pathData)) {
    final n = double.tryParse(tok);
    if (n != null) numbers.add(n);
  }
  if (numbers.length < 2) return null;

  double xMin = double.infinity, xMax = double.negativeInfinity;
  double yMin = double.infinity, yMax = double.negativeInfinity;
  for (var i = 0; i + 1 < numbers.length; i += 2) {
    final x = numbers[i];
    final y = numbers[i + 1];
    if (x < xMin) xMin = x;
    if (x > xMax) xMax = x;
    if (y < yMin) yMin = y;
    if (y > yMax) yMax = y;
  }
  return [xMin, yMin, xMax, yMax];
}

/// Tokenizes a PDF content stream into numbers and operator strings.
List<String> _tokenize(String stream) {
  final result = <String>[];
  // Match numbers (including negatives and scientific notation) and operators.
  final re = RegExp(r'-?[\d]+\.?[\d]*(?:e[+-]?\d+)?|[a-zA-Z*]+');
  for (final m in re.allMatches(stream)) {
    result.add(m.group(0)!);
  }
  return result;
}

/// Decompresses and returns the first path-bearing stream from a PDF.
///
/// PDF streams are FlateDecode-compressed. Returns `null` if no suitable
/// stream is found.
Future<String?> _extractPathStream(File pdfFile) async {
  final bytes = await pdfFile.readAsBytes();

  // Scan for 'stream\r\n' or 'stream\n' markers.
  for (var i = 0; i < bytes.length - 10; i++) {
    // 's' 't' 'r' 'e' 'a' 'm'
    if (bytes[i] != 0x73 ||
        bytes[i + 1] != 0x74 ||
        bytes[i + 2] != 0x72 ||
        bytes[i + 3] != 0x65 ||
        bytes[i + 4] != 0x61 ||
        bytes[i + 5] != 0x6D) {
      continue;
    }
    // Skip the newline after 'stream'
    var start = i + 6;
    if (start < bytes.length && bytes[start] == 0x0D) start++; // CR
    if (start < bytes.length && bytes[start] == 0x0A) start++; // LF

    // Find 'endstream'
    final endMarker = _findBytes(bytes, _endstream, start);
    if (endMarker < 0) continue;

    // Skip trailing newline before 'endstream'
    var end = endMarker;
    if (end > 0 && bytes[end - 1] == 0x0A) end--;
    if (end > 0 && bytes[end - 1] == 0x0D) end--;

    try {
      final compressed = bytes.sublist(start, end);
      final decompressed = zlib.decode(compressed);
      final text = utf8.decode(decompressed, allowMalformed: true);
      // Accept streams that contain PDF path operators.
      if (text.contains(' m') || text.contains('m ') || text.contains('\nm')) {
        return text;
      }
    } catch (_) {
      // Not zlib-compressed or corrupt; try next stream.
    }
  }
  return null;
}

final _endstream = 'endstream'.codeUnits;

/// Finds the first occurrence of [needle] in [haystack] starting from [start].
int _findBytes(List<int> haystack, List<int> needle, int start) {
  outer:
  for (var i = start; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// Parses the `/MediaBox` entry from a PDF file.
///
/// Returns `[x, y, width, height]` in PDF coordinate units, or `null`.
Future<List<double>?> _extractMediaBox(File pdfFile) async {
  // Read a chunk of the file; MediaBox is always near the top.
  final bytes = await pdfFile.readAsBytes();
  final text = latin1.decode(bytes.sublist(0, bytes.length.clamp(0, 4096)));
  final m = RegExp(
    r'/MediaBox\s*\[\s*(-?[\d.]+)\s+(-?[\d.]+)\s+([\d.]+)\s+([\d.]+)\s*\]',
  ).firstMatch(text);
  if (m == null) return null;
  return [
    double.parse(m.group(1)!),
    double.parse(m.group(2)!),
    double.parse(m.group(3)!),
    double.parse(m.group(4)!),
  ];
}

/// Parses a plist file by converting it to JSON via `plutil`.
Future<Map<String, dynamic>?> _parsePlist(String path) async {
  final result = await Process.run('plutil', [
    '-convert',
    'json',
    '-o',
    '-',
    path,
  ]);
  if (result.exitCode != 0) return null;
  try {
    return jsonDecode(result.stdout as String) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
