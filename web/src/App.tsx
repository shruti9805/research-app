import { useEffect, useState } from 'react'
import { recognizeText } from './lib/ocr'
import { storageRoundTrip } from './lib/storage'
import { buildHealthCheckWorkbook } from './lib/excel'
import './App.css'

type CheckStatus = 'pending' | 'pass' | 'fail'

interface CheckState {
  status: CheckStatus
  detail: string
}

const initialCheck: CheckState = { status: 'pending', detail: 'Running…' }

/** Draws test text onto an offscreen canvas — stands in for a photographed form page. */
function drawTestCanvas(): HTMLCanvasElement {
  const canvas = document.createElement('canvas')
  canvas.width = 300
  canvas.height = 80
  const ctx = canvas.getContext('2d')!
  ctx.fillStyle = '#ffffff'
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.fillStyle = '#000000'
  ctx.font = '32px sans-serif'
  ctx.fillText('RESEARCH APP', 10, 50)
  return canvas
}

export default function App() {
  const [ocr, setOcr] = useState<CheckState>(initialCheck)
  const [storage, setStorage] = useState<CheckState>(initialCheck)
  const [excel, setExcel] = useState<CheckState>(initialCheck)
  const [workbookBuffer, setWorkbookBuffer] = useState<ArrayBuffer | null>(null)

  useEffect(() => {
    recognizeText(drawTestCanvas())
      .then((result) => {
        const text = result.text.trim()
        if (text.toUpperCase().includes('RESEARCH')) {
          setOcr({ status: 'pass', detail: `Read "${text}" at ${result.confidence.toFixed(0)}% confidence` })
        } else {
          setOcr({ status: 'fail', detail: `Unexpected read: "${text}"` })
        }
      })
      .catch((err) => setOcr({ status: 'fail', detail: String(err) }))

    storageRoundTrip()
      .then((record) => setStorage({ status: 'pass', detail: `Round-tripped record "${record.id}" at ${record.checkedAt}` }))
      .catch((err) => setStorage({ status: 'fail', detail: String(err) }))

    buildHealthCheckWorkbook()
      .then((buffer) => {
        setWorkbookBuffer(buffer as ArrayBuffer)
        setExcel({ status: 'pass', detail: `Built a ${(buffer as ArrayBuffer).byteLength}-byte .xlsx with a live formula and a filled cell` })
      })
      .catch((err) => setExcel({ status: 'fail', detail: String(err) }))
  }, [])

  function downloadWorkbook() {
    if (!workbookBuffer) return
    const blob = new Blob([workbookBuffer], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'wt1-health-check.xlsx'
    a.click()
    URL.revokeObjectURL(url)
  }

  const checks: Array<{ name: string; state: CheckState }> = [
    { name: 'Tesseract.js OCR (canvas → text)', state: ocr },
    { name: 'IndexedDB round-trip', state: storage },
    { name: 'ExcelJS workbook (formula + fill)', state: excel },
  ]

  return (
    <main className="health-check">
      <h1>Component WT-1 — Web Walking Skeleton</h1>
      <p>Proves the web-track toolchain works, before any real parsing is built. See PLAN.md §6.1.</p>
      <ul className="check-list">
        {checks.map(({ name, state }) => (
          <li key={name} className={`check-card check-card--${state.status}`}>
            <span className="check-card__icon">
              {state.status === 'pending' ? '…' : state.status === 'pass' ? '✅' : '❌'}
            </span>
            <div>
              <strong>{name}</strong>
              <p>{state.detail}</p>
            </div>
          </li>
        ))}
      </ul>
      <button onClick={downloadWorkbook} disabled={!workbookBuffer}>
        Download test workbook (.xlsx)
      </button>
    </main>
  )
}
