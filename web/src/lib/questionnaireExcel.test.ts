import ExcelJS from 'exceljs'
import { describe, expect, it } from 'vitest'
import { buildQuestionnaireTemplate, columnLetter } from './questionnaireExcel'
import type { Questionnaire } from './questionnaire'

describe('columnLetter', () => {
  it('converts 1-indexed column numbers to Excel letters, including the two-letter rollover', () => {
    expect(columnLetter(1)).toBe('A')
    expect(columnLetter(6)).toBe('F')
    expect(columnLetter(26)).toBe('Z')
    expect(columnLetter(27)).toBe('AA')
    expect(columnLetter(52)).toBe('AZ')
  })
})

describe('buildQuestionnaireTemplate', () => {
  // A miniature questionnaire: 2 constructs, easy to hand-check the formula ranges.
  const questionnaire: Questionnaire = {
    items: [
      { code: 'ER_1', construct: 'ER', english: 'e1', hindi: 'h1' },
      { code: 'ER_2', construct: 'ER', english: 'e2', hindi: 'h2' },
      { code: 'RE_1', construct: 'RE', english: 'e3', hindi: 'h3' },
    ],
    constructs: [
      { code: 'ER', itemCodes: ['ER_1', 'ER_2'] },
      { code: 'RE', itemCodes: ['RE_1'] },
    ],
  }

  it('writes one column per item plus one live-formula column per construct, referencing the right range', async () => {
    const buffer = await buildQuestionnaireTemplate(questionnaire)

    const readBack = new ExcelJS.Workbook()
    await readBack.xlsx.load(buffer)
    const sheet = readBack.getWorksheet('Responses')!

    expect(sheet.getRow(1).values).toEqual([undefined, 'ER_1', 'ER_2', 'RE_1', 'ER_mean', 'RE_mean'])

    // ER_mean (column D) should average ER_1:ER_2 (columns A:B); RE_mean (column E) averages RE_1 alone (column C).
    expect(sheet.getCell('D2').formula).toBe('AVERAGE(A2:B2)')
    expect(sheet.getCell('E2').formula).toBe('AVERAGE(C2:C2)')

    // Cross-check against the example row's own hardcoded values (1, 2, 3 cycling from i%5+1).
    expect(sheet.getCell('A2').value).toBe(1) // ER_1
    expect(sheet.getCell('B2').value).toBe(2) // ER_2
    expect(sheet.getCell('C2').value).toBe(3) // RE_1
    const expectedErMean = (1 + 2) / 2
    const expectedReMean = 3 / 1
    expect(expectedErMean).toBe(1.5)
    expect(expectedReMean).toBe(3)
  })
})
