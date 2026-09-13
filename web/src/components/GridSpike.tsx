import { useState } from 'react'
import { loadPdfDocument, renderPdfPage } from '../lib/pdfRender'
import { detectTable, drawTableOverlay } from '../lib/tableDetection'
import { matchCodes } from '../lib/codeAnchoring'
import { recognizeWords } from '../lib/ocr'

// Verified against Student_Survey_Bilingual.docx in WT-2 (PRODUCT.md §11.1).
const CONSTRUCT_COUNTS: Record<string, number> = {
  ER: 6, RE: 6, EO: 7, EM: 6, DI: 6, TC: 6, DP: 6, DS: 6, PS: 7, AS: 5, IR: 5, PC: 5,
}
const EXPECTED_CODES = Object.entries(CONSTRUCT_COUNTS).flatMap(([construct, count]) =>
  Array.from({ length: count }, (_, i) => `${construct}_${i + 1}`),
)

interface PageResult {
  canvas: HTMLCanvasElement
  leftRowLines: number
  leftColLines: number
  rightRowLines: number
  rightColLines: number
  matchedCodes: string[]
  debug: string
}

async function runDetectionOcrAndOverlay(canvas: HTMLCanvasElement): Promise<Omit<PageResult, 'canvas'>> {
  const ctx = canvas.getContext('2d')!
  const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
  const midpoint = Math.round(canvas.width / 2)

  const left = detectTable(imageData, { xStart: 0, xEnd: midpoint })
  const right = detectTable(imageData, { xStart: midpoint, xEnd: canvas.width })
  drawTableOverlay(ctx, left)
  drawTableOverlay(ctx, right)

  // OCR the whole page (cropping to just the Code column was tried and made
  // recall *worse* — 16.9% vs 35.2% — Tesseract errored on the narrow strip
  // with "Image too small to scale" on several lines. Real finding, not
  // theoretical: keep whole-page OCR, rely on fuzzy code-matching instead.
  const words = await recognizeWords(canvas)
  const matches = matchCodes(words, EXPECTED_CODES)

  ctx.save()
  ctx.strokeStyle = 'green'
  ctx.lineWidth = 2
  ctx.font = '16px sans-serif'
  ctx.fillStyle = 'green'
  for (const match of matches) {
    const { x0, y0, x1, y1 } = match.bbox
    ctx.strokeRect(x0, y0, x1 - x0, y1 - y0)
    ctx.fillText(match.code, x1 + 4, y1)
  }
  ctx.restore()

  return {
    leftRowLines: left.rowLines.length,
    leftColLines: left.colLines.length,
    rightRowLines: right.rowLines.length,
    rightColLines: right.colLines.length,
    matchedCodes: matches.map((m) => m.code),
    debug: JSON.stringify({ left, right }),
  }
}

/** WT-3 investigation: renders every page, runs grid detection (DR-002) and OCR code-anchoring (DR-003), overlays both for eyeballing. */
export default function GridSpike() {
  const [status, setStatus] = useState<'idle' | 'rendering' | 'done' | 'error'>('idle')
  const [error, setError] = useState('')
  const [results, setResults] = useState<PageResult[]>([])

  async function handleFile(file: File) {
    setStatus('rendering')
    setError('')
    setResults([])
    try {
      const arrayBuffer = await file.arrayBuffer()
      const doc = await loadPdfDocument(arrayBuffer)
      const rendered: PageResult[] = []
      for (let i = 1; i <= doc.numPages; i++) {
        const canvas = await renderPdfPage(doc, i, 4)
        const outcome = await runDetectionOcrAndOverlay(canvas)
        rendered.push({ canvas, ...outcome })
        setResults([...rendered])
      }
      setStatus('done')
    } catch (err) {
      setError(String(err))
      setStatus('error')
    }
  }

  const allMatchedCodes = new Set(results.flatMap((r) => r.matchedCodes))
  const recall = results.length > 0 ? allMatchedCodes.size / EXPECTED_CODES.length : 0
  const missingCodes = EXPECTED_CODES.filter((c) => !allMatchedCodes.has(c))

  return (
    <section className="grid-spike" id="grid-spike">
      <h2>Component WT-3 — Grid + Row Anchoring Spike</h2>
      <p>Upload a filled response PDF. Red = detected ruled-line grid (DR-002). Green = OCR-matched item codes (DR-003). See PLAN.md §6.1.</p>
      <input
        type="file"
        accept=".pdf"
        onChange={(e) => {
          const file = e.target.files?.[0]
          if (file) void handleFile(file)
        }}
      />
      {status === 'rendering' && <p>Rendering and running OCR — this takes a while, one page at a time…</p>}
      {status === 'error' && <p className="questionnaire-import__error">{error}</p>}
      {status === 'done' && (
        <div className="check-card check-card--pass">
          <span className="check-card__icon">✅</span>
          <div>
            <strong>
              Code-column recall: {allMatchedCodes.size} / {EXPECTED_CODES.length} ({(recall * 100).toFixed(1)}%)
            </strong>
            {missingCodes.length > 0 && <p>Missing: {missingCodes.join(', ')}</p>}
          </div>
        </div>
      )}
      <div className="grid-spike__pages">
        {results.map((result, i) => (
          <div key={i} className="grid-spike__page-wrapper">
            <p className="grid-spike__stats">
              Page {i + 1} — left: {result.leftRowLines} rows × {result.leftColLines} cols; right:{' '}
              {result.rightRowLines} rows × {result.rightColLines} cols; codes matched: {result.matchedCodes.length}
            </p>
            <pre className="grid-spike__debug" style={{ display: 'none' }}>
              {result.debug}
            </pre>
            <div
              className="grid-spike__page"
              ref={(el) => {
                if (el) el.replaceChildren(result.canvas)
              }}
            />
          </div>
        ))}
      </div>
    </section>
  )
}
