import 'package:excel/excel.dart' as xl;
import 'package:questionnaire_parser/questionnaire_parser.dart';
import 'package:test/test.dart';

void main() {
  group('columnLetter', () {
    test('converts 1-indexed column numbers to Excel letters, including the two-letter rollover', () {
      expect(columnLetter(1), 'A');
      expect(columnLetter(6), 'F');
      expect(columnLetter(26), 'Z');
      expect(columnLetter(27), 'AA');
      expect(columnLetter(52), 'AZ');
    });
  });

  group('buildQuestionnaireTemplate', () {
    // A miniature questionnaire: 2 constructs, easy to hand-check the formula ranges.
    final questionnaire = Questionnaire(
      [
        QuestionnaireItem(code: 'ER_1', construct: 'ER', english: 'e1', hindi: 'h1'),
        QuestionnaireItem(code: 'ER_2', construct: 'ER', english: 'e2', hindi: 'h2'),
        QuestionnaireItem(code: 'RE_1', construct: 'RE', english: 'e3', hindi: 'h3'),
      ],
      [
        Construct('ER', ['ER_1', 'ER_2']),
        Construct('RE', ['RE_1']),
      ],
    );

    test('writes one column per item plus one live-formula column per construct, referencing the right range', () {
      final bytes = buildQuestionnaireTemplate(questionnaire);

      final readBack = xl.Excel.decodeBytes(bytes);
      final sheet = readBack['Responses'];

      String textAt(int col, int row) =>
          (sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value
                  as xl.TextCellValue)
              .value
              .text ??
          '';

      expect(textAt(0, 0), 'ER_1');
      expect(textAt(1, 0), 'ER_2');
      expect(textAt(2, 0), 'RE_1');
      expect(textAt(3, 0), 'ER_mean');
      expect(textAt(4, 0), 'RE_mean');

      // ER_mean (col index 3) averages ER_1:ER_2 (A:B); RE_mean (col index 4) averages RE_1 alone (C).
      final erMeanCell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1));
      final reMeanCell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1));
      expect((erMeanCell.value as xl.FormulaCellValue).formula, 'AVERAGE(A2:B2)');
      expect((reMeanCell.value as xl.FormulaCellValue).formula, 'AVERAGE(C2:C2)');

      // Cross-check against the example row's own hardcoded values (1, 2, 3 cycling from i%5+1).
      int intAt(int col, int row) =>
          (sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value
                  as xl.IntCellValue)
              .value;
      expect(intAt(0, 1), 1); // ER_1
      expect(intAt(1, 1), 2); // ER_2
      expect(intAt(2, 1), 3); // RE_1
      expect((1 + 2) / 2, 1.5);
      expect(3 / 1, 3);
    });
  });
}
