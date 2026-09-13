import { describe, expect, it } from 'vitest'
import { matchCodes } from './codeAnchoring'
import type { OcrWord } from './ocr'

const bbox = { x0: 0, y0: 0, x1: 10, y1: 10 }
function word(text: string, confidence = 90): OcrWord {
  return { text, confidence, bbox }
}

describe('matchCodes', () => {
  it('matches exact codes', () => {
    const matches = matchCodes([word('ER_1'), word('ER_2')], ['ER_1', 'ER_2', 'ER_3'])
    expect(matches.map((m) => m.code).sort()).toEqual(['ER_1', 'ER_2'])
  })

  it('corrects a single-character OCR slip against the known code list', () => {
    // "ER_l" (lowercase L) instead of "ER_1" - a classic OCR confusion.
    const matches = matchCodes([word('ER_l')], ['ER_1', 'ER_2'])
    expect(matches).toHaveLength(1)
    expect(matches[0].code).toBe('ER_1')
    expect(matches[0].rawText).toBe('ER_l')
  })

  it('does not match a word too far from any expected code', () => {
    const matches = matchCodes([word('Statement')], ['ER_1', 'ER_2'])
    expect(matches).toEqual([])
  })

  it('never claims the same code twice, even with duplicate OCR reads', () => {
    const matches = matchCodes([word('ER_1'), word('ER_1'), word('ER_2')], ['ER_1', 'ER_2'])
    const codes = matches.map((m) => m.code).sort()
    expect(codes).toEqual(['ER_1', 'ER_2'])
  })

  it('ignores blank/whitespace-only OCR words', () => {
    const matches = matchCodes([word('   '), word('')], ['ER_1'])
    expect(matches).toEqual([])
  })
})
