import 'package:image/image.dart' as img;
import 'package:questionnaire_parser/src/grid_detection.dart';
import 'package:test/test.dart';

img.Image makeRuledGrid(int width, int height, List<int> rowLines, List<int> colLines) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  final black = img.ColorRgb8(0, 0, 0);
  for (final y in rowLines) {
    for (var x = 0; x < width; x++) {
      image.setPixel(x, y, black);
    }
  }
  for (final x in colLines) {
    for (var y = 0; y < height; y++) {
      image.setPixel(x, y, black);
    }
  }
  return image;
}

void main() {
  group('gridDetection on a clean synthetic grid', () {
    test('recovers exact ruled-line positions with no gap-bridging needed', () {
      final image = makeRuledGrid(100, 100, [10, 30, 50, 70, 90], [10, 50, 90]);
      final gray = toGrayscale(image);
      final binary = binarize(gray, 128);

      final hProfile = longestRunPerRow(binary, image.width, image.height);
      expect(findRuledLines(hProfile, image.width * 0.9), [10, 30, 50, 70, 90]);

      final vProfile = longestRunPerColumn(binary, image.width, image.height);
      expect(findRuledLines(vProfile, image.height * 0.9), [10, 50, 90]);
    });

    test('does not mistake scattered text-like ink for a ruled line', () {
      const width = 100;
      const height = 20;
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      for (var x = 0; x < width; x += 3) {
        image.setPixel(x, 10, img.ColorRgb8(0, 0, 0));
      }
      final binary = binarize(toGrayscale(image), 128);
      final profile = longestRunPerRow(binary, width, height);
      expect(findRuledLines(profile, width * 0.5), <int>[]);
    });

    test('collapses a multi-pixel-thick line to its midpoint', () {
      final image = makeRuledGrid(50, 50, [20, 21, 22], []);
      final binary = binarize(toGrayscale(image), 128);
      final profile = longestRunPerRow(binary, image.width, image.height);
      expect(findRuledLines(profile, image.width * 0.9), [21]);
    });
  });

  group('bridgeGaps', () {
    test('heals small gaps in an otherwise-continuous line', () {
      const width = 30;
      const height = 5;
      final binary = List<bool>.filled(width * height, false);
      const row = 2;
      void draw(int from, int to) {
        for (var x = from; x < to; x++) {
          binary[row * width + x] = true;
        }
      }
      draw(0, 8);
      draw(10, 18); // 2px gap
      draw(20, 28); // 2px gap

      final rawProfile = longestRunPerRow(binary, width, height);
      expect(rawProfile[row], 8); // without bridging, only the longest dash counts

      final bridged = bridgeGaps(binary, width, height, 'row', 2);
      final bridgedProfile = longestRunPerRow(bridged, width, height);
      // Gaps of <=2px healed into one run, and dilation grows both outer edges by the radius too.
      expect(bridgedProfile[row], 30);

      expect(bridgedProfile[0], 0); // rows with no ink stay untouched
    });

    test('bridges along columns independently of rows', () {
      const width = 5;
      const height = 30;
      final binary = List<bool>.filled(width * height, false);
      const col = 2;
      void draw(int from, int to) {
        for (var y = from; y < to; y++) {
          binary[y * width + col] = true;
        }
      }
      draw(0, 8);
      draw(10, 18);

      final bridged = bridgeGaps(binary, width, height, 'column', 2);
      final profile = longestRunPerColumn(bridged, width, height);
      expect(profile[col], 20);
    });
  });
}
