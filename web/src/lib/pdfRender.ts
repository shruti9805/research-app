import './polyfills'
// The "legacy" build targets less-modern JS engines (no native `Iterator` global,
// etc.) — this Mac's Node 20.18 lacks that global entirely, and real iPhones in
// the field may run a Safari version behind pdf.js's main-build assumptions too.
import * as pdfjsLib from 'pdfjs-dist/legacy/build/pdf.mjs'
import type { PDFDocumentProxy } from 'pdfjs-dist/types/src/display/api'

pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
  'pdfjs-dist/legacy/build/pdf.worker.mjs',
  import.meta.url,
).toString()

/**
 * Loads a PDF once. `getDocument` transfers the source ArrayBuffer to the
 * worker (detaching it), so load once and reuse the returned document for
 * every page rather than calling getDocument again per page.
 */
export async function loadPdfDocument(source: ArrayBuffer): Promise<PDFDocumentProxy> {
  return pdfjsLib.getDocument({ data: source }).promise
}

/** Renders one page of an already-loaded document to a canvas (scale 2 ≈ 144dpi for a 72dpi page unit). */
export async function renderPdfPage(doc: PDFDocumentProxy, pageNumber: number, scale = 2): Promise<HTMLCanvasElement> {
  const page = await doc.getPage(pageNumber)
  const viewport = page.getViewport({ scale })

  const canvas = document.createElement('canvas')
  canvas.width = Math.round(viewport.width)
  canvas.height = Math.round(viewport.height)
  const renderTask = page.render({ canvas, viewport })
  await renderTask.promise
  return canvas
}
