/**
 * Promise.withResolvers (used internally by pdf.js) only landed in
 * Chrome 119, Firefox 121 and Safari 17.4 (March 2024) — real iPhones in the
 * field may well be older than that. Two-line polyfill per MDN.
 */
if (typeof Promise.withResolvers !== 'function') {
  Promise.withResolvers = function <T>() {
    let resolve!: (value: T | PromiseLike<T>) => void
    let reject!: (reason?: unknown) => void
    const promise = new Promise<T>((res, rej) => {
      resolve = res
      reject = rej
    })
    return { promise, resolve, reject }
  }
}
