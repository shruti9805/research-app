import { recognizeWords, type OcrWord } from './ocr'
import type { ImageLike } from 'tesseract.js'

export interface CodeMatch {
  /** The expected code this OCR word was matched to (e.g. "ER_1"). */
  code: string
  /** What Tesseract actually read (may differ from `code` — OCR slips). */
  rawText: string
  confidence: number
  bbox: { x0: number; y0: number; x1: number; y1: number }
}

/** Levenshtein edit distance — used to correct OCR slips against the known set of 71 codes. */
function editDistance(a: string, b: string): number {
  const dp: number[][] = Array.from({ length: a.length + 1 }, () => Array(b.length + 1).fill(0))
  for (let i = 0; i <= a.length; i++) dp[i][0] = i
  for (let j = 0; j <= b.length; j++) dp[0][j] = j
  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] === b[j - 1] ? dp[i - 1][j - 1] : 1 + Math.min(dp[i - 1][j - 1], dp[i - 1][j], dp[i][j - 1])
    }
  }
  return dp[a.length][b.length]
}

/**
 * Row anchoring via the printed Code column (DR-003): fuzzy-match each OCR
 * word against the 71 known expected codes — there are only 71 possible
 * strings, so a small edit distance corrects most OCR slips (e.g. "ER_l" ->
 * "ER_1"). Each expected code can only be claimed once (closest match wins),
 * so a repeated OCR misread can't silently duplicate a row.
 */
export function matchCodes(words: OcrWord[], expectedCodes: string[], maxEditDistance = 1): CodeMatch[] {
  const candidates: Array<CodeMatch & { distance: number; wordIndex: number }> = []
  words.forEach((word, wordIndex) => {
    const cleaned = word.text.trim()
    if (!cleaned) return
    for (const code of expectedCodes) {
      const distance = editDistance(cleaned.toUpperCase(), code.toUpperCase())
      if (distance <= maxEditDistance) {
        candidates.push({ code, rawText: cleaned, confidence: word.confidence, bbox: word.bbox, distance, wordIndex })
      }
    }
  })
  // Closest matches first, so both "a word's best code" and "a code's best word" are resolved before weaker pairings.
  candidates.sort((a, b) => a.distance - b.distance)

  const claimedCodes = new Set<string>()
  const claimedWords = new Set<number>()
  const matches: CodeMatch[] = []
  for (const candidate of candidates) {
    if (claimedCodes.has(candidate.code) || claimedWords.has(candidate.wordIndex)) continue
    claimedCodes.add(candidate.code)
    claimedWords.add(candidate.wordIndex)
    matches.push({ code: candidate.code, rawText: candidate.rawText, confidence: candidate.confidence, bbox: candidate.bbox })
  }
  return matches
}

/** Convenience: OCR an image region and match against the expected codes in one call. */
export async function anchorCodes(image: ImageLike, expectedCodes: string[]): Promise<CodeMatch[]> {
  const words = await recognizeWords(image)
  return matchCodes(words, expectedCodes)
}
