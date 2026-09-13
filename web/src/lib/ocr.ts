import { createWorker } from 'tesseract.js'
import type { ImageLike } from 'tesseract.js'

export interface OcrResult {
  text: string
  confidence: number
}

/**
 * Runs Tesseract.js against an image and returns recognized text + confidence.
 * Accepts anything Tesseract.js does (Buffer, File, Blob, canvas, image URL/path),
 * so the same function works from a browser UI and from a plain Node test.
 */
export async function recognizeText(image: ImageLike, lang = 'eng'): Promise<OcrResult> {
  const worker = await createWorker(lang)
  try {
    const { data } = await worker.recognize(image)
    return { text: data.text, confidence: data.confidence }
  } finally {
    await worker.terminate()
  }
}

export interface OcrWord {
  text: string
  confidence: number
  bbox: { x0: number; y0: number; x1: number; y1: number }
}

/** Word-level OCR results with bounding boxes — needed for row anchoring (DR-003), where each word's Y position matters, not just the recognized text. */
export async function recognizeWords(image: ImageLike, lang = 'eng'): Promise<OcrWord[]> {
  const worker = await createWorker(lang)
  try {
    const { data } = await worker.recognize(image, {}, { blocks: true })
    const words: OcrWord[] = []
    for (const block of data.blocks ?? []) {
      for (const paragraph of block.paragraphs) {
        for (const line of paragraph.lines) {
          for (const word of line.words) {
            words.push({ text: word.text, confidence: word.confidence, bbox: word.bbox })
          }
        }
      }
    }
    return words
  } finally {
    await worker.terminate()
  }
}
