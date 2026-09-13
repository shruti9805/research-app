// Component 3 (mobile) — grid detection spike. Pure-Dart CLI, no Flutter/ML
// Kit needed for this half of the spike (DR-002's ruled-line detection).
// Code-column OCR recall (DR-003) needs ML Kit, which only runs inside the
// Flutter app — see the app-side integration test for that half.
//
// Usage: dart run bin/grid_spike.dart <page1.png> [page2.png ...]
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:questionnaire_parser/src/table_detection.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run bin/grid_spike.dart <page1.png> [page2.png ...]');
    exit(64);
  }

  for (final path in arguments) {
    final bytes = File(path).readAsBytesSync();
    final image = img.decodePng(bytes);
    if (image == null) {
      stderr.writeln('$path: could not decode as PNG, skipping.');
      continue;
    }

    final midpoint = (image.width / 2).round();
    final left = detectTable(image, xStart: 0, xEnd: midpoint);
    final right = detectTable(image, xStart: midpoint, xEnd: image.width);

    drawTableOverlay(image, left);
    drawTableOverlay(image, right);

    final outPath = path.replaceAll(RegExp(r'\.png$'), '_overlay.png');
    File(outPath).writeAsBytesSync(img.encodePng(image));

    stdout.writeln('$path (${image.width}x${image.height}):');
    stdout.writeln('  left:  ${left.rowLines.length} row lines, ${left.colLines.length} col lines');
    stdout.writeln('  right: ${right.rowLines.length} row lines, ${right.colLines.length} col lines');
    stdout.writeln('  overlay written to $outPath');
  }
}
