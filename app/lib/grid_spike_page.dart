// Component 3 (mobile) — the ML Kit half of the grid + row anchoring spike.
// DR-002's ruled-line detection was already spiked as a pure-Dart CLI
// (parser/bin/grid_spike.dart) — no ML Kit needed there. This screen covers
// the other half, DR-003's code-column OCR recall, which can only run here:
// ML Kit is a native plugin, invoked through Flutter's platform channels, so
// it cannot execute in a bare `dart run` CLI process.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:questionnaire_parser/questionnaire_parser.dart';

// Verified against Student_Survey_Bilingual.docx in Component 2 (PRODUCT.md §11.1).
const _constructCounts = <String, int>{
  'ER': 6, 'RE': 6, 'EO': 7, 'EM': 6, 'DI': 6, 'TC': 6,
  'DP': 6, 'DS': 6, 'PS': 7, 'AS': 5, 'IR': 5, 'PC': 5,
};

List<String> _expectedCodes() {
  final codes = <String>[];
  _constructCounts.forEach((construct, count) {
    for (var i = 1; i <= count; i++) {
      codes.add('${construct}_$i');
    }
  });
  return codes;
}

class PageResult {
  final String name;
  final List<CodeMatch>? matches; // null means this page errored
  final String? error;
  PageResult(this.name, this.matches, this.error);
}

class GridSpikePage extends StatefulWidget {
  const GridSpikePage({super.key});

  @override
  State<GridSpikePage> createState() => _GridSpikePageState();
}

class _GridSpikePageState extends State<GridSpikePage> {
  bool _running = true;
  String _status = 'Running…';
  List<PageResult> _results = [];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final expectedCodes = _expectedCodes();
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final results = <PageResult>[];
    final tempDir = await getTemporaryDirectory();

    try {
      for (var i = 1; i <= 6; i++) {
        final name = 'page$i.png';
        setState(() => _status = 'Processing $name (${i - 1}/6 done)…');
        try {
          // Assets live inside the APK, not on a real filesystem path — ML
          // Kit's InputImage.fromFilePath needs an actual path, so copy the
          // asset bytes into the app's own (fully private, no permissions
          // needed) temp directory first.
          final assetBytes = await rootBundle.load('assets/spike_pages/$name');
          final localFile = File('${tempDir.path}/$name');
          await localFile.writeAsBytes(assetBytes.buffer.asUint8List());

          final inputImage = InputImage.fromFilePath(localFile.path);
          final recognized = await recognizer.processImage(inputImage);

          final words = <OcrWord>[];
          for (final block in recognized.blocks) {
            for (final line in block.lines) {
              for (final element in line.elements) {
                words.add(OcrWord(
                  text: element.text,
                  confidence: element.confidence ?? 0,
                  x0: element.boundingBox.left.round(),
                  y0: element.boundingBox.top.round(),
                  x1: element.boundingBox.right.round(),
                  y1: element.boundingBox.bottom.round(),
                ));
              }
            }
          }
          final matches = matchCodes(words, expectedCodes);
          results.add(PageResult(name, matches, null));
        } catch (e) {
          // One page's failure must not silently stop the whole spike, and
          // must never leave the UI stuck on "Running…" forever.
          results.add(PageResult(name, null, e.toString()));
        }
        if (mounted) setState(() => _results = List.of(results));
      }
    } finally {
      await recognizer.close();
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _status = 'Done';
    });
  }

  @override
  Widget build(BuildContext context) {
    final allMatchedCodes = <String>{};
    for (final r in _results) {
      if (r.matches != null) allMatchedCodes.addAll(r.matches!.map((m) => m.code));
    }
    final expected = _expectedCodes();
    final recall = expected.isEmpty ? 0.0 : allMatchedCodes.length / expected.length;
    final missing = expected.where((c) => !allMatchedCodes.contains(c)).toList();
    final anyErrors = _results.any((r) => r.error != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Component 3 — Code-Column OCR (ML Kit)'),
        backgroundColor: const Color(0xFF1F3864),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_running)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                  const SizedBox(width: 16),
                  Expanded(child: Text(_status)),
                ]),
              ),
            )
          else
            Card(
              color: anyErrors ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code-column recall: ${allMatchedCodes.length} / ${expected.length} '
                      '(${(recall * 100).toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Missing: ${missing.join(", ")}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          ..._results.map((r) => Card(
                child: ListTile(
                  leading: Icon(
                    r.error != null ? Icons.error : Icons.check_circle,
                    color: r.error != null ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                  title: Text(r.name),
                  subtitle: Text(r.error ?? '${r.matches!.length} codes matched'),
                  isThreeLine: (r.error?.length ?? 0) > 60,
                ),
              )),
        ],
      ),
    );
  }
}
