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
