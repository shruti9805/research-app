import 'package:questionnaire_parser/questionnaire_parser.dart';
import 'package:test/test.dart';

OcrWord _word(String text, {double confidence = 90}) {
  return OcrWord(text: text, confidence: confidence, x0: 0, y0: 0, x1: 10, y1: 10);
}

void main() {
  group('matchCodes', () {
    test('matches exact codes', () {
      final matches = matchCodes([_word('ER_1'), _word('ER_2')], ['ER_1', 'ER_2', 'ER_3']);
      expect(matches.map((m) => m.code).toList()..sort(), ['ER_1', 'ER_2']);
    });

    test('corrects a single-character OCR slip against the known code list', () {
      // "ER_l" (lowercase L) instead of "ER_1" - a classic OCR confusion.
      final matches = matchCodes([_word('ER_l')], ['ER_1', 'ER_2']);
      expect(matches, hasLength(1));
      expect(matches[0].code, 'ER_1');
      expect(matches[0].rawText, 'ER_l');
    });

    test('does not match a word too far from any expected code', () {
      final matches = matchCodes([_word('Statement')], ['ER_1', 'ER_2']);
      expect(matches, isEmpty);
    });

    test('never claims the same code twice, even with duplicate OCR reads', () {
      final matches = matchCodes([_word('ER_1'), _word('ER_1'), _word('ER_2')], ['ER_1', 'ER_2']);
      final codes = matches.map((m) => m.code).toList()..sort();
      expect(codes, ['ER_1', 'ER_2']);
    });

    test('never lets one word claim two different codes', () {
      // "ER_1" is distance 0 from ER_1 and distance 1 from ER_3 - must only claim ER_1.
      final matches = matchCodes([_word('ER_1')], ['ER_1', 'ER_3']);
      expect(matches, hasLength(1));
      expect(matches[0].code, 'ER_1');
    });

    test('ignores blank/whitespace-only OCR words', () {
      final matches = matchCodes([_word('   '), _word('')], ['ER_1']);
      expect(matches, isEmpty);
    });
  });
}
