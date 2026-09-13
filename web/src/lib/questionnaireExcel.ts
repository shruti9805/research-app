import ExcelJS from 'exceljs'
import type { Questionnaire } from './questionnaire'

/** Converts a 1-indexed column number to its Excel letter(s): 1 -> A, 26 -> Z, 27 -> AA. */
export function columnLetter(n: number): string {
  let result = ''
  let num = n
  while (num > 0) {
    const remainder = (num - 1) % 26
    result = String.fromCharCode(65 + remainder) + result
    num = Math.floor((num - 1) / 26)
  }
  return result
}

/**
 * Builds an Excel template from a parsed Questionnaire: one column per item code
 * (ER_1 .. PC_5), followed by one live-formula column per construct mean (PLAN.md §5.2).
 * Includes one clearly-labelled example row so the formulas can be seen to compute,
 * not just exist.
 */
export async function buildQuestionnaireTemplate(questionnaire: Questionnaire): Promise<ExcelJS.Buffer> {
  const workbook = new ExcelJS.Workbook()
  const sheet = workbook.addWorksheet('Responses')

  const itemColumns = questionnaire.items.map((item) => ({ header: item.code, key: item.code, width: 8 }))
  const constructColumns = questionnaire.constructs.map((construct) => ({
    header: `${construct.code}_mean`,
    key: `${construct.code}_mean`,
    width: 10,
  }))
  sheet.columns = [...itemColumns, ...constructColumns]

  // One example row (values 1..5 cycling) so the construct-mean formulas visibly compute.
  const exampleValues: Record<string, number> = {}
  questionnaire.items.forEach((item, i) => {
    exampleValues[item.code] = (i % 5) + 1
  })
  sheet.addRow(exampleValues)

  const rowNumber = 2 // header is row 1, example data is row 2
  questionnaire.constructs.forEach((construct) => {
    const firstItemIndex = questionnaire.items.findIndex((item) => item.code === construct.itemCodes[0])
    const lastItemIndex = firstItemIndex + construct.itemCodes.length - 1
    const startCol = columnLetter(firstItemIndex + 1)
    const endCol = columnLetter(lastItemIndex + 1)
    const meanColIndex = itemColumns.length + questionnaire.constructs.indexOf(construct) + 1
    const cell = sheet.getCell(rowNumber, meanColIndex)
    cell.value = { formula: `AVERAGE(${startCol}${rowNumber}:${endCol}${rowNumber})` }
  })

  return workbook.xlsx.writeBuffer()
}
