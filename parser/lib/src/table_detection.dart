import 'package:image/image.dart' as img;

import 'grid_detection.dart';

class DetectedTable {
  final List<int> rowLines;
  final List<int> colLines;
  final int tableLeft;
  final int tableRight;
  final int tableTop;
  final int tableBottom;

  DetectedTable({
    required this.rowLines,
    required this.colLines,
    required this.tableLeft,
    required this.tableRight,
    required this.tableTop,
    required this.tableBottom,
  });

  static DetectedTable empty(int xStart, int xEnd) => DetectedTable(
        rowLines: [],
        colLines: [],
        tableLeft: xStart,
        tableRight: xEnd,
        tableTop: 0,
        tableBottom: 0,
      );
}

/// Ruled-table detection, tuned against the real sample scan
/// (samples/Student_Questionnaire_BP_Pujari_1.pdf) — ported directly from the
/// web track's `tableDetection.ts`, where this exact approach was measured
/// against the same file. See grid_detection.dart for why gap-bridging is
/// load-bearing here — a naive threshold-and-count approach found zero lines.
///
/// Two passes:
/// 1. Row lines, restricted to the mostly-blank answer-column region
///    ([blankRegionStartFraction] of crop width from xStart) — much cleaner
///    signal than searching across the text-heavy Statement column.
/// 2. Column lines, restricted to the row span from pass 1 — sharper than
///    searching the full page height.
DetectedTable detectTable(
  img.Image image, {
  int? xStart,
  int? xEnd,
  int binarizeThreshold = 210,
  int gapBridgeRadius = 3,
  double rowLineMinFraction = 0.5,
  double colLineMinFraction = 0.35,
  double blankRegionStartFraction = 0.21,
}) {
  final xs = xStart ?? 0;
  final xe = xEnd ?? image.width;

  final gray = toGrayscale(image);
  final binary = binarize(gray, binarizeThreshold);
  final rowBridged = bridgeGaps(binary, image.width, image.height, 'row', gapBridgeRadius);
  final colBridged = bridgeGaps(binary, image.width, image.height, 'column', gapBridgeRadius);

  final blankRegionStart = (xs + blankRegionStartFraction * (xe - xs)).round();

  final rowSpan = xe - blankRegionStart;
  final rowProfile = longestRunPerRow(rowBridged, image.width, image.height, xStart: blankRegionStart, xEnd: xe);
  final rowLines = findRuledLines(rowProfile, rowSpan * rowLineMinFraction);

  if (rowLines.length < 2) return DetectedTable.empty(xs, xe);

  final tableTop = rowLines.first;
  final tableBottom = rowLines.last;

  final rowSpanHeight = tableBottom - tableTop;
  final colProfile = longestRunPerColumn(colBridged, image.width, image.height, yStart: tableTop, yEnd: tableBottom);
  final colLines = findRuledLines(colProfile, rowSpanHeight * colLineMinFraction).where((x) => x >= xs && x < xe).toList();

  return DetectedTable(
    rowLines: rowLines,
    colLines: colLines,
    tableLeft: colLines.isNotEmpty ? colLines.first : xs,
    tableRight: colLines.isNotEmpty ? colLines.last : xe,
    tableTop: tableTop,
    tableBottom: tableBottom,
  );
}

/// Draws the detected grid as red lines on top of [image], for eyeballing.
void drawTableOverlay(img.Image image, DetectedTable table) {
  final red = img.ColorRgb8(255, 0, 0);
  for (final y in table.rowLines) {
    img.drawLine(image, x1: table.tableLeft, y1: y, x2: table.tableRight, y2: y, color: red);
  }
  for (final x in table.colLines) {
    img.drawLine(image, x1: x, y1: table.tableTop, x2: x, y2: table.tableBottom, color: red);
  }
}
