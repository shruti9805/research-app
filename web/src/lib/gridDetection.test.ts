import { describe, expect, it } from 'vitest'
import {
  binarize,
  bridgeGaps,
  findRuledLines,
  longestRunPerColumn,
  longestRunPerRow,
  toGrayscale,
  type RasterImage,
} from './gridDetection'

/** Builds a synthetic white RasterImage with full-width/height black lines at the given rows/columns. */
function makeRuledGrid(width: number, height: number, rowLines: number[], colLines: number[]): RasterImage {
  const data = new Uint8ClampedArray(width * height * 4).fill(255)
  for (let i = 3; i < data.length; i += 4) data[i] = 255 // alpha
  const setBlack = (x: number, y: number) => {
    const i = (y * width + x) * 4
    data[i] = data[i + 1] = data[i + 2] = 0
  }
  for (const y of rowLines) {
    for (let x = 0; x < width; x++) setBlack(x, y)
  }
  for (const x of colLines) {
    for (let y = 0; y < height; y++) setBlack(x, y)
  }
  return { data, width, height }
}

describe('gridDetection on a clean synthetic grid', () => {
  it('recovers exact ruled-line positions with no gap-bridging needed', () => {
    const image = makeRuledGrid(100, 100, [10, 30, 50, 70, 90], [10, 50, 90])
    const gray = toGrayscale(image)
    const binary = binarize(gray, 128)

    const hProfile = longestRunPerRow(binary, image.width, image.height)
    expect(findRuledLines(hProfile, image.width * 0.9)).toEqual([10, 30, 50, 70, 90])

    const vProfile = longestRunPerColumn(binary, image.width, image.height)
    expect(findRuledLines(vProfile, image.height * 0.9)).toEqual([10, 50, 90])
  })

  it('does not mistake scattered text-like ink for a ruled line', () => {
    // A row with dots every 3px (like sparse text) never forms a long contiguous run.
    const width = 100
    const height = 20
    const data = new Uint8ClampedArray(width * height * 4).fill(255)
    for (let x = 0; x < width; x += 3) {
      const i = (10 * width + x) * 4
      data[i] = data[i + 1] = data[i + 2] = 0
    }
    const image: RasterImage = { data, width, height }
    const binary = binarize(toGrayscale(image), 128)
    const profile = longestRunPerRow(binary, width, height)
    expect(findRuledLines(profile, width * 0.5)).toEqual([])
  })

  it('collapses a multi-pixel-thick line to its midpoint', () => {
    const image = makeRuledGrid(50, 50, [20, 21, 22], [])
    const binary = binarize(toGrayscale(image), 128)
    const profile = longestRunPerRow(binary, image.width, image.height)
    expect(findRuledLines(profile, image.width * 0.9)).toEqual([21])
  })
})

describe('bridgeGaps', () => {
  it('heals small gaps in an otherwise-continuous line, matching what real scans need', () => {
    // A "line" broken into three short dashes, like a real scanned ruled line
    // fragmented by compression noise (verified against the real sample PDF).
    const width = 30
    const height = 5
    const binary = new Uint8Array(width * height)
    const row = 2
    const draw = (from: number, to: number) => {
      for (let x = from; x < to; x++) binary[row * width + x] = 1
    }
    draw(0, 8)
    draw(10, 18) // 2px gap
    draw(20, 28) // 2px gap

    const rawProfile = longestRunPerRow(binary, width, height)
    expect(rawProfile[row]).toBe(8) // without bridging, only the longest dash counts

    const bridged = bridgeGaps(binary, width, height, 'row', 2)
    const bridgedProfile = longestRunPerRow(bridged, width, height)
    // Gaps of <=2px are healed into one run, and dilation also grows the two
    // outer edges of the whole run by the radius (0..27 becomes 0..29).
    expect(bridgedProfile[row]).toBe(30)

    // Rows with no ink at all must stay untouched.
    expect(bridgedProfile[0]).toBe(0)
  })

  it('bridges along columns independently of rows, for vertical-line detection', () => {
    const width = 5
    const height = 30
    const binary = new Uint8Array(width * height)
    const col = 2
    const draw = (from: number, to: number) => {
      for (let y = from; y < to; y++) binary[y * width + col] = 1
    }
    draw(0, 8)
    draw(10, 18)

    const bridged = bridgeGaps(binary, width, height, 'column', 2)
    const profile = longestRunPerColumn(bridged, width, height)
    expect(profile[col]).toBe(20) // gap healed, and the run's tail edge grows by the radius too
  })
})
