/** A plain, DOM-free stand-in for ImageData so this module has no Canvas/browser dependency. */
export interface RasterImage {
  data: Uint8ClampedArray // RGBA, length = width * height * 4
  width: number
  height: number
}

/** Grayscale intensity 0-255 per pixel, row-major. */
export function toGrayscale(image: RasterImage): Uint8ClampedArray {
  const gray = new Uint8ClampedArray(image.width * image.height)
  for (let i = 0; i < gray.length; i++) {
    const r = image.data[i * 4]
    const g = image.data[i * 4 + 1]
    const b = image.data[i * 4 + 2]
    // Standard luma weights.
    gray[i] = 0.299 * r + 0.587 * g + 0.114 * b
  }
  return gray
}

/** True where a pixel is "ink" (darker than threshold, 0-255). */
export function binarize(gray: Uint8ClampedArray, threshold: number): Uint8Array {
  const out = new Uint8Array(gray.length)
  for (let i = 0; i < gray.length; i++) {
    out[i] = gray[i] < threshold ? 1 : 0
  }
  return out
}

/**
 * Real scanned ruled lines are not solid — JPEG compression and scan noise
 * break a visually-continuous line into short fragments a few pixels apart
 * (measured directly against samples/Student_Questionnaire_BP_Pujari_1.pdf:
 * without this step, the strongest real column line's longest contiguous run
 * was 39% of the table height; with it, 69%). This bridges gaps up to
 * `radius` pixels along the line's own direction, one dimension at a time.
 * `axis: 'row'` bridges along x (for detecting horizontal lines);
 * `axis: 'column'` bridges along y (for detecting vertical lines).
 */
export function bridgeGaps(binary: Uint8Array, width: number, height: number, axis: 'row' | 'column', radius: number): Uint8Array {
  const out = new Uint8Array(binary.length)
  if (axis === 'row') {
    for (let y = 0; y < height; y++) {
      const rowOffset = y * width
      for (let x = 0; x < width; x++) {
        let dark = false
        for (let dx = -radius; dx <= radius && !dark; dx++) {
          const xx = x + dx
          if (xx >= 0 && xx < width && binary[rowOffset + xx]) dark = true
        }
        out[rowOffset + x] = dark ? 1 : 0
      }
    }
  } else {
    for (let x = 0; x < width; x++) {
      for (let y = 0; y < height; y++) {
        let dark = false
        for (let dy = -radius; dy <= radius && !dark; dy++) {
          const yy = y + dy
          if (yy >= 0 && yy < height && binary[yy * width + x]) dark = true
        }
        out[y * width + x] = dark ? 1 : 0
      }
    }
  }
  return out
}

/** Row -> longest contiguous run of ink pixels within [xStart, xEnd) for that row. */
export function longestRunPerRow(binary: Uint8Array, width: number, height: number, xStart = 0, xEnd = width): Int32Array {
  const profile = new Int32Array(height)
  for (let y = 0; y < height; y++) {
    const rowOffset = y * width
    let longest = 0
    let current = 0
    for (let x = xStart; x < xEnd; x++) {
      if (binary[rowOffset + x]) {
        current++
        if (current > longest) longest = current
      } else {
        current = 0
      }
    }
    profile[y] = longest
  }
  return profile
}

/** Column -> longest contiguous run of ink pixels within [yStart, yEnd) for that column. */
export function longestRunPerColumn(binary: Uint8Array, width: number, height: number, yStart = 0, yEnd = height): Int32Array {
  const profile = new Int32Array(width)
  for (let x = 0; x < width; x++) {
    let longest = 0
    let current = 0
    for (let y = yStart; y < yEnd; y++) {
      if (binary[y * width + x]) {
        current++
        if (current > longest) longest = current
      } else {
        current = 0
      }
    }
    profile[x] = longest
  }
  return profile
}

/**
 * Finds ruled-line positions in a profile: runs of consecutive indices whose
 * value meets `threshold`, collapsed to the run's midpoint. Callers decide
 * what the threshold means — a fraction of a *known* span (row/column search
 * restricted to the table's real extent) or a fraction of the profile's own
 * max (a coarse first pass, before the table's extent is known — comparing
 * against an assumed-but-wrong span undercounts real lines that only exist
 * within a portion of the search area).
 */
export function findRuledLines(profile: Int32Array, threshold: number): number[] {
  const lines: number[] = []
  let runStart = -1
  for (let i = 0; i <= profile.length; i++) {
    const isLine = i < profile.length && profile[i] >= threshold
    if (isLine && runStart === -1) {
      runStart = i
    } else if (!isLine && runStart !== -1) {
      lines.push(Math.round((runStart + i - 1) / 2))
      runStart = -1
    }
  }
  return lines
}
