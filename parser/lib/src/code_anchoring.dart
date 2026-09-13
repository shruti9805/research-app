class OcrWord {
  final String text;
  final double confidence;
  final int x0, y0, x1, y1;

  OcrWord({
    required this.text,
    required this.confidence,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });
}

class CodeMatch {
  /// The expected code this OCR word was matched to (e.g. "ER_1").
  final String code;
  /// What OCR actually read (may differ from [code] — OCR slips).
  final String rawText;
  final double confidence;
  final int x0, y0, x1, y1;

  CodeMatch({
    required this.code,
    required this.rawText,
    required this.confidence,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });
}

/// Levenshtein edit distance — used to correct OCR slips against the known set of 71 codes.
int _editDistance(String a, String b) {
  final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] == b[j - 1]
          ? dp[i - 1][j - 1]
          : 1 + [dp[i - 1][j - 1], dp[i - 1][j], dp[i][j - 1]].reduce((x, y) => x < y ? x : y);
    }
  }
  return dp[a.length][b.length];
}

/// Row anchoring via the printed Code column (DR-003): fuzzy-match each OCR
/// word against the 71 known expected codes — there are only 71 possible
/// strings, so a small edit distance corrects most OCR slips (e.g. "ER_l" ->
/// "ER_1"). Each expected code and each OCR word can only be claimed once, so
/// a repeated misread can't silently duplicate a row, and one word can't
/// claim two different codes.
List<CodeMatch> matchCodes(List<OcrWord> words, List<String> expectedCodes, {int maxEditDistance = 1}) {
  final candidates = <(int distance, int wordIndex, String code)>[];
  for (var wi = 0; wi < words.length; wi++) {
    final cleaned = words[wi].text.trim();
    if (cleaned.isEmpty) continue;
    for (final code in expectedCodes) {
      final distance = _editDistance(cleaned.toUpperCase(), code.toUpperCase());
      if (distance <= maxEditDistance) {
        candidates.add((distance, wi, code));
      }
    }
  }
  candidates.sort((a, b) => a.$1.compareTo(b.$1));

  final claimedCodes = <String>{};
  final claimedWords = <int>{};
  final matches = <CodeMatch>[];
  for (final candidate in candidates) {
    final (_, wordIndex, code) = candidate;
    if (claimedCodes.contains(code) || claimedWords.contains(wordIndex)) continue;
    claimedCodes.add(code);
    claimedWords.add(wordIndex);
    final word = words[wordIndex];
    matches.add(CodeMatch(
      code: code,
      rawText: word.text.trim(),
      confidence: word.confidence,
      x0: word.x0,
      y0: word.y0,
      x1: word.x1,
      y1: word.y1,
    ));
  }
  return matches;
}
