import 'package:image/image.dart' as img;

/// Grayscale intensity 0-255 per pixel, row-major (width * height).
List<int> toGrayscale(img.Image image) {
  final gray = List<int>.filled(image.width * image.height, 0);
  var i = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      gray[i] = image.getPixel(x, y).luminance.round();
      i++;
    }
  }
  return gray;
}

/// True where a pixel is "ink" (darker than threshold, 0-255).
List<bool> binarize(List<int> gray, int threshold) {
  return gray.map((v) => v < threshold).toList(growable: false);
}

/// Real scanned ruled lines are not solid — JPEG/scan noise breaks a
/// visually-continuous line into short fragments a few pixels apart
/// (measured directly against samples/Student_Questionnaire_BP_Pujari_1.pdf
/// in the web track: without this step the strongest real column line's
/// longest contiguous run was 39% of the table height; with it, 69%). This
/// bridges gaps up to [radius] pixels along the line's own direction.
/// `axis: 'row'` bridges along x (for detecting horizontal lines);
/// `axis: 'column'` bridges along y (for detecting vertical lines).
List<bool> bridgeGaps(List<bool> binary, int width, int height, String axis, int radius) {
  final out = List<bool>.filled(binary.length, false);
  if (axis == 'row') {
    for (var y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (var x = 0; x < width; x++) {
        var dark = false;
        for (var dx = -radius; dx <= radius && !dark; dx++) {
          final xx = x + dx;
          if (xx >= 0 && xx < width && binary[rowOffset + xx]) dark = true;
        }
        out[rowOffset + x] = dark;
      }
    }
  } else {
    for (var x = 0; x < width; x++) {
      for (var y = 0; y < height; y++) {
        var dark = false;
        for (var dy = -radius; dy <= radius && !dark; dy++) {
          final yy = y + dy;
          if (yy >= 0 && yy < height && binary[yy * width + x]) dark = true;
        }
        out[y * width + x] = dark;
      }
    }
  }
  return out;
}

/// Row -> longest contiguous run of ink pixels within [xStart, xEnd).
List<int> longestRunPerRow(List<bool> binary, int width, int height, {int? xStart, int? xEnd}) {
  final xs = xStart ?? 0;
  final xe = xEnd ?? width;
  final profile = List<int>.filled(height, 0);
  for (var y = 0; y < height; y++) {
    final rowOffset = y * width;
    var longest = 0;
    var current = 0;
    for (var x = xs; x < xe; x++) {
      if (binary[rowOffset + x]) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    profile[y] = longest;
  }
  return profile;
}

/// Column -> longest contiguous run of ink pixels within [yStart, yEnd).
List<int> longestRunPerColumn(List<bool> binary, int width, int height, {int? yStart, int? yEnd}) {
  final ys = yStart ?? 0;
  final ye = yEnd ?? height;
  final profile = List<int>.filled(width, 0);
  for (var x = 0; x < width; x++) {
    var longest = 0;
    var current = 0;
    for (var y = ys; y < ye; y++) {
      if (binary[y * width + x]) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    profile[x] = longest;
  }
  return profile;
}

/// Finds ruled-line positions in a profile: runs of consecutive indices whose
/// value meets [threshold], collapsed to the run's midpoint.
List<int> findRuledLines(List<int> profile, num threshold) {
  final lines = <int>[];
  var runStart = -1;
  for (var i = 0; i <= profile.length; i++) {
    final isLine = i < profile.length && profile[i] >= threshold;
    if (isLine && runStart == -1) {
      runStart = i;
    } else if (!isLine && runStart != -1) {
      lines.add(((runStart + i - 1) / 2).round());
      runStart = -1;
    }
  }
  return lines;
}
