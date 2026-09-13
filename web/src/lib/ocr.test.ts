import { readFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'
import { recognizeText } from './ocr'

const dirname = path.dirname(fileURLToPath(import.meta.url))
const fixturePath = path.join(dirname, '../fixtures/eng_bw.png')

describe('recognizeText', () => {
  it(
    'reads printed text from a real image with no browser/DOM involved',
    async () => {
      const image = readFileSync(fixturePath)
      const result = await recognizeText(image)

      // Real output observed 2026-09-13 running this fixture through
      // Tesseract.js under plain Node: "Mild Splendour of the various-vested
      // Night!..." at 92% confidence. Asserting on a stable substring rather
      // than the full text, since exact whitespace/line-wrap isn't the point.
      expect(result.text).toContain('Mild Splendour')
      expect(result.confidence).toBeGreaterThan(80)
    },
    30_000,
  )
})
