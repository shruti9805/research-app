import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';

class QuestionnaireItem {
  final String code;
  final String construct;
  final String english;
  final String hindi;

  QuestionnaireItem({
    required this.code,
    required this.construct,
    required this.english,
    required this.hindi,
  });
}

class Construct {
  final String code;
  final List<String> itemCodes;

  Construct(this.code, this.itemCodes);
}

class Questionnaire {
  final List<QuestionnaireItem> items;
  final List<Construct> constructs;

  Questionnaire(this.items, this.constructs);
}

/// Thrown when the .docx doesn't match the expected shape. The template is
/// scored against every response, so a silent mis-parse here would propagate
/// into all of them — refuse to guess (PRODUCT.md §11.1).
class QuestionnaireParseException implements Exception {
  final String message;
  QuestionnaireParseException(this.message);

  @override
  String toString() => 'QuestionnaireParseException: $message';
}

/// Parses the 71-item Likert table out of the questionnaire .docx.
///
/// Expects a table whose header row reads SrNo / Code / Statement (English /
/// Hindi) / 1..5, each data row's Code cell holding e.g. "ER_1" and its
/// Statement cell holding the English and Hindi text separated by a single
/// line break run (`<w:br/>`). Verified directly against the real
/// `Student_Survey_Bilingual.docx` XML structure — see parser/test.
Questionnaire parseQuestionnaireDocx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final documentFile = archive.findFile('word/document.xml');
  if (documentFile == null) {
    throw QuestionnaireParseException(
      'Not a valid .docx: word/document.xml not found in the archive.',
    );
  }
  final xmlString = utf8.decode(documentFile.content as List<int>);
  final document = XmlDocument.parse(xmlString);

  final tables = document.findAllElements('w:tbl').toList();
  XmlElement? itemsTable;
  for (final table in tables) {
    final rows = table.findElements('w:tr').toList();
    if (rows.isEmpty) continue;
    final headerCells = rows.first.findElements('w:tc').toList();
    if (headerCells.length < 2) continue;
    if (_cellPlainText(headerCells[0]).trim() == 'SrNo' &&
        _cellPlainText(headerCells[1]).trim() == 'Code') {
      itemsTable = table;
      break;
    }
  }
  if (itemsTable == null) {
    throw QuestionnaireParseException(
      'Could not find the 71-item table in this .docx (expected a table with '
      'header row starting "SrNo", "Code"). Refusing to guess.',
    );
  }

  final dataRows = itemsTable.findElements('w:tr').toList().sublist(1);
  final items = <QuestionnaireItem>[];
  for (var i = 0; i < dataRows.length; i++) {
    final cells = dataRows[i].findElements('w:tc').toList();
    if (cells.length < 3) {
      throw QuestionnaireParseException(
        'Row ${i + 1}: expected at least 3 cells (SrNo, Code, Statement), found ${cells.length}.',
      );
    }
    final code = _cellPlainText(cells[1]).trim();
    final parts = _cellBilingualText(cells[2]);
    if (parts.length != 2) {
      throw QuestionnaireParseException(
        'Row ${i + 1} (code "$code"): expected exactly one line break splitting '
        'English/Hindi in the statement cell, found ${parts.length - 1}.',
      );
    }
    final construct = code.contains('_') ? code.split('_').first : '';
    if (code.isEmpty || construct.isEmpty) {
      throw QuestionnaireParseException(
        'Row ${i + 1}: could not read a valid item code from "$code".',
      );
    }
    items.add(QuestionnaireItem(
      code: code,
      construct: construct,
      english: parts[0].trim(),
      hindi: parts[1].trim(),
    ));
  }

  final seen = <String>{};
  for (final item in items) {
    if (!seen.add(item.code)) {
      throw QuestionnaireParseException(
        'Duplicate item code "${item.code}" — every code must be unique (PRODUCT.md §11.1).',
      );
    }
  }
  if (items.length != 71) {
    throw QuestionnaireParseException(
      'Expected exactly 71 items, parsed ${items.length}. Refusing to emit a wrong-sized template.',
    );
  }

  final constructs = <Construct>[];
  for (final item in items) {
    final matchIndex = constructs.indexWhere((c) => c.code == item.construct);
    if (matchIndex >= 0) {
      constructs[matchIndex].itemCodes.add(item.code);
    } else {
      constructs.add(Construct(item.construct, [item.code]));
    }
  }

  return Questionnaire(items, constructs);
}

/// Plain concatenated text of every `<w:t>` in a cell, ignoring run/paragraph
/// boundaries — used for cells with no line break (e.g. the Code column).
String _cellPlainText(XmlElement cell) {
  return cell.findAllElements('w:t').map((t) => t.innerText).join();
}

/// Splits a cell's text into segments separated by `<w:br/>` runs, so the
/// English and Hindi halves of a Statement cell can be told apart. A `<w:br/>`
/// lives inside its own `<w:r>` run, a sibling of the text-bearing runs —
/// verified directly against the real docx XML, not assumed.
List<String> _cellBilingualText(XmlElement cell) {
  final segments = <StringBuffer>[StringBuffer()];
  for (final paragraph in cell.findElements('w:p')) {
    for (final child in paragraph.childElements) {
      if (child.name.qualified != 'w:r') continue;
      if (child.findElements('w:br').isNotEmpty) {
        segments.add(StringBuffer());
        continue;
      }
      for (final t in child.findElements('w:t')) {
        segments.last.write(t.innerText);
      }
    }
  }
  return segments.map((s) => s.toString()).toList();
}
