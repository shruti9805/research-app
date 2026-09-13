import ExcelJS from 'exceljs'

/**
 * Builds a tiny workbook that exercises the two ExcelJS features the real
 * app depends on (PLAN.md §5.2): a live formula (construct-mean columns)
 * and a filled/highlighted cell (flagged-value highlighting).
 */
export async function buildHealthCheckWorkbook(): Promise<ExcelJS.Buffer> {
  const workbook = new ExcelJS.Workbook()
  const sheet = workbook.addWorksheet('WT-1 Health Check')

  sheet.columns = [
    { header: 'a', key: 'a', width: 10 },
    { header: 'b', key: 'b', width: 10 },
    { header: 'a + b (live formula)', key: 'sum', width: 20 },
  ]
  sheet.addRow({ a: 2, b: 3 })

  const sumCell = sheet.getCell('C2')
  sumCell.value = { formula: 'A2+B2' }
  sumCell.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFFFCC00' },
  }

  return workbook.xlsx.writeBuffer()
}
