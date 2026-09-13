// CLI entry point — the whole reason the parser is a pure-Dart library with
// no Flutter dependency: this runs in seconds against samples/, no rebuild,
// no phone. Usage:
//   dart run bin/parse_questionnaire.dart <input.docx> [output.xlsx]
import 'dart:io';

import 'package:questionnaire_parser/questionnaire_parser.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run bin/parse_questionnaire.dart <input.docx> [output.xlsx]');
    exit(64);
  }
  final inputPath = arguments[0];
  final outputPath = arguments.length > 1 ? arguments[1] : 'questionnaire-template.xlsx';

  final bytes = File(inputPath).readAsBytesSync();

  final Questionnaire questionnaire;
  try {
    questionnaire = parseQuestionnaireDocx(bytes);
  } on QuestionnaireParseException catch (e) {
    stderr.writeln('Parse failed: ${e.message}');
    exit(1);
  }

  stdout.writeln('Parsed ${questionnaire.items.length} items across ${questionnaire.constructs.length} constructs:');
  for (final construct in questionnaire.constructs) {
    stdout.writeln('  ${construct.code}: ${construct.itemCodes.length}');
  }

  final xlsxBytes = buildQuestionnaireTemplate(questionnaire);
  File(outputPath).writeAsBytesSync(xlsxBytes);
  stdout.writeln('Wrote $outputPath (${xlsxBytes.length} bytes)');
}
