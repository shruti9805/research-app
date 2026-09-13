import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:questionnaire_parser/questionnaire_parser.dart';
import 'package:test/test.dart';

void main() {
  final fixturePath = 'test/fixtures/Student_Survey_Bilingual.docx';

  group('parseQuestionnaireDocx', () {
    test('parses exactly 71 unique items from the real questionnaire', () {
      final bytes = File(fixturePath).readAsBytesSync();
      final questionnaire = parseQuestionnaireDocx(bytes);

      expect(questionnaire.items, hasLength(71));
      expect(questionnaire.items.map((i) => i.code).toSet(), hasLength(71));
    });

    test('matches the construct breakdown verified against the real file (PRODUCT.md §11.1)', () {
      final bytes = File(fixturePath).readAsBytesSync();
      final questionnaire = parseQuestionnaireDocx(bytes);

      final counts = {
        for (final c in questionnaire.constructs) c.code: c.itemCodes.length
      };
      expect(counts, {
        'ER': 6, 'RE': 6, 'EO': 7, 'EM': 6, 'DI': 6, 'TC': 6,
        'DP': 6, 'DS': 6, 'PS': 7, 'AS': 5, 'IR': 5, 'PC': 5,
      });
    });

    test('reads the first and last item codes in document order', () {
      final bytes = File(fixturePath).readAsBytesSync();
      final questionnaire = parseQuestionnaireDocx(bytes);

      expect(questionnaire.items.first.code, 'ER_1');
      expect(questionnaire.items.last.code, 'PC_5');
    });

    test('splits English and Hindi text correctly for a real item, with proper UTF-8 decoding', () {
      final bytes = File(fixturePath).readAsBytesSync();
      final questionnaire = parseQuestionnaireDocx(bytes);

      final er1 = questionnaire.items.firstWhere((i) => i.code == 'ER_1');
      expect(er1.english, 'My academic submissions are marked and assessed fairly.');
      expect(er1.hindi, contains('मेरे अकादमिक कार्यों का मूल्यांकन निष्पक्ष रूप से किया जाता है'));
    });

    test('throws rather than guess when word/document.xml is missing entirely', () {
      final archive = Archive();
      archive.addFile(ArchiveFile.string('README.txt', 'not a real docx'));
      final encoded = ZipEncoder().encode(archive);
      final zipBytes = Uint8List.fromList(encoded!);

      expect(
        () => parseQuestionnaireDocx(zipBytes),
        throwsA(isA<QuestionnaireParseException>().having(
          (e) => e.message,
          'message',
          contains('word/document.xml not found'),
        )),
      );
    });
  });
}
