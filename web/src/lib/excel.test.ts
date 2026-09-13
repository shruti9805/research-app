import ExcelJS from 'exceljs'
import { describe, expect, it } from 'vitest'
import { buildHealthCheckWorkbook } from './excel'

describe('buildHealthCheckWorkbook', () => {
  it('writes a formula and a cell fill that both survive a round-trip, with no browser involved', async () => {
    const buffer = await buildHealthCheckWorkbook()

    const readBack = new ExcelJS.Workbook()
    await readBack.xlsx.load(buffer)
    const sheet = readBack.getWorksheet('WT-1 Health Check')
    const cell = sheet!.getCell('C2')

    expect(cell.formula).toBe('A2+B2')
    expect(cell.fill).toMatchObject({
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFFFCC00' },
    })
  })
})
