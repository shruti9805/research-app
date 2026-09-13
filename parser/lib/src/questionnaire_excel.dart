import 'package:excel/excel.dart';

import 'questionnaire.dart';

/// Converts a 1-indexed column number to its Excel letter(s): 1 -> A, 26 -> Z, 27 -> AA.
String columnLetter(int n) {
  var result = '';
  var num = n;
  while (num > 0) {
    final remainder = (num - 1) % 26;
    result = String.fromCharCode(65 + remainder) + result;
    num = (num - 1) ~/ 26;
  }
  return result;
}

/// Builds an Excel template from a parsed Questionnaire: one column per item
/// code (ER_1 .. PC_5), followed by one live-formula column per construct
/// mean (PLAN.md §5.2). Includes one clearly-labelled example row so the
/// formulas can be seen to compute, not just exist.
List<int> buildQuestionnaireTemplate(Questionnaire questionnaire) {
  final excel = Excel.createExcel();
  const sheetName = 'Responses';
  final sheet = excel[sheetName];
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != sheetName) {
    excel.delete(defaultSheet);
  }

  // Header row: item codes, then construct-mean columns.
  for (var i = 0; i < questionnaire.items.length; i++) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        .value = TextCellValue(questionnaire.items[i].code);
  }
  final itemCount = questionnaire.items.length;
  for (var i = 0; i < questionnaire.constructs.length; i++) {
    sheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: itemCount + i, rowIndex: 0))
        .value = TextCellValue('${questionnaire.constructs[i].code}_mean');
  }

  // One example row (values 1..5 cycling) so the construct-mean formulas
  // visibly compute, not just exist as strings.
  const exampleRow = 1; // header is row 0
  for (var i = 0; i < questionnaire.items.length; i++) {
    sheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: i, rowIndex: exampleRow))
        .value = IntCellValue((i % 5) + 1);
  }

  final excelRowNumber = exampleRow + 1; // 1-indexed, for formula text
  for (var c = 0; c < questionnaire.constructs.length; c++) {
    final construct = questionnaire.constructs[c];
    final firstItemIndex = questionnaire.items
        .indexWhere((item) => item.code == construct.itemCodes.first);
    final lastItemIndex = firstItemIndex + construct.itemCodes.length - 1;
    final startCol = columnLetter(firstItemIndex + 1);
    final endCol = columnLetter(lastItemIndex + 1);
    final meanColIndex = itemCount + c;
    sheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: meanColIndex, rowIndex: exampleRow))
        .setFormula('AVERAGE($startCol$excelRowNumber:$endCol$excelRowNumber)');
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('excel.encode() returned null — could not build the workbook.');
  }
  return bytes;
}
