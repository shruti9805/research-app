import { binarize, bridgeGaps, findRuledLines, longestRunPerColumn, longestRunPerRow, toGrayscale, type RasterImage } from './gridDetection'

export interface DetectedTable {
  rowLines: number[]
  colLines: number[]
  tableLeft: number
  tableRight: number
  tableTop: number
  tableBottom: number
}

export interface DetectTableOptions {
  xStart?: number
  xEnd?: number
  binarizeThreshold?: number
  gapBridgeRadius?: number
  rowLineMinFraction?: number
  colLineMinFraction?: number
  /**
   * Where the mostly-blank answer-column region starts, as a fraction of
   * crop width from xStart. Calibrated against the real sample form
   * (samples/Student_Questionnaire_BP_Pujari_1.pdf): the Sr.No/Code/Statement
   * block occupies the left ~21% of a half-page crop at this render scale.
   * This is a form-layout constant (PRODUCT.md confirms the layout is fixed
   * across print runs), not a general one — a different questionnaire would
   * need this recalibrated. An index-based approach (count coarse column
   * lines from the left) was tried first and was fragile: the table's own
   * outer-left border sometimes gets detected as a strong line too, throwing
   * off which ordinal position means "Statement column boundary."
   */
  blankRegionStartFraction?: number
}

const DEFAULTS = {
  binarizeThreshold: 210,
  gapBridgeRadius: 3,
  rowLineMinFraction: 0.5,
  colLineMinFraction: 0.35,
  blankRegionStartFraction: 0.21,
}

/**
 * Ruled-table detection, tuned against a real scanned page (see gridDetection.ts
 * for why gap-bridging is load-bearing — a naive threshold-and-count approach
 * found zero lines on the real sample). Two passes:
 *
 * 1. Find row lines restricted to the mostly-blank answer-column region
 *    (Sr.No/Code/Statement excluded via `blankRegionStartFraction`) — much
 *    cleaner signal than searching across the text-heavy Statement column,
 *    which produces text-line density peaks indistinguishable from ruled
 *    lines by a simple threshold.
 * 2. Find column lines restricted to the row span from step 1 — sharper
 *    than searching the full page height, now that the table's exact
 *    vertical extent is known.
 */
export function detectTable(image: RasterImage, options: DetectTableOptions = {}): DetectedTable {
  const opts = { ...DEFAULTS, ...options }
  const xStart = options.xStart ?? 0
  const xEnd = options.xEnd ?? image.width
  const empty: DetectedTable = { rowLines: [], colLines: [], tableLeft: xStart, tableRight: xEnd, tableTop: 0, tableBottom: 0 }

  const gray = toGrayscale(image)
  const binary = binarize(gray, opts.binarizeThreshold)
  const rowBridged = bridgeGaps(binary, image.width, image.height, 'row', opts.gapBridgeRadius)
  const colBridged = bridgeGaps(binary, image.width, image.height, 'column', opts.gapBridgeRadius)

  const blankRegionStart = Math.round(xStart + opts.blankRegionStartFraction * (xEnd - xStart))

  // Pass 1: row lines, searched only within the blank answer-column region.
  const rowSpan = xEnd - blankRegionStart
  const rowProfile = longestRunPerRow(rowBridged, image.width, image.height, blankRegionStart, xEnd)
  const rowLines = findRuledLines(rowProfile, rowSpan * opts.rowLineMinFraction)

  if (rowLines.length < 2) return { ...empty, rowLines }

  const tableTop = rowLines[0]
  const tableBottom = rowLines[rowLines.length - 1]

  // Pass 2: column lines, restricted to the known row span.
  const rowSpanHeight = tableBottom - tableTop
  const colProfile = longestRunPerColumn(colBridged, image.width, image.height, tableTop, tableBottom)
  const colLines = findRuledLines(colProfile, rowSpanHeight * opts.colLineMinFraction).filter((x) => x >= xStart && x < xEnd)

  return {
    rowLines,
    colLines,
    tableLeft: colLines[0] ?? xStart,
    tableRight: colLines[colLines.length - 1] ?? xEnd,
    tableTop,
    tableBottom,
  }
}

/** Draws the detected grid as red lines on top of the (already-drawn) canvas, for eyeballing. */
export function drawTableOverlay(ctx: CanvasRenderingContext2D, table: DetectedTable) {
  ctx.save()
  ctx.strokeStyle = 'red'
  ctx.lineWidth = 1
  for (const y of table.rowLines) {
    ctx.beginPath()
    ctx.moveTo(table.tableLeft, y)
    ctx.lineTo(table.tableRight, y)
    ctx.stroke()
  }
  for (const x of table.colLines) {
    ctx.beginPath()
    ctx.moveTo(x, table.tableTop)
    ctx.lineTo(x, table.tableBottom)
    ctx.stroke()
  }
  ctx.restore()
}
