// @vitest-environment jsdom
import { readFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'
import { parseQuestionnaireDocx } from './questionnaire'

const dirname = path.dirname(fileURLToPath(import.meta.url))
const fixturePath = path.join(dirname, '../fixtures/Student_Survey_Bilingual.docx')

function toArrayBuffer(buffer: Buffer): ArrayBuffer {
  return buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength) as ArrayBuffer
}

describe('parseQuestionnaireDocx', () => {
  it('parses exactly 71 unique items from the real questionnaire', async () => {
    const source = toArrayBuffer(readFileSync(fixturePath))
    const questionnaire = await parseQuestionnaireDocx(source)

    expect(questionnaire.items).toHaveLength(71)
    expect(new Set(questionnaire.items.map((i) => i.code)).size).toBe(71)
  })

  it('matches the construct breakdown verified against the real file (PRODUCT.md §11.1)', async () => {
    const source = toArrayBuffer(readFileSync(fixturePath))
    const questionnaire = await parseQuestionnaireDocx(source)

    const counts = Object.fromEntries(questionnaire.constructs.map((c) => [c.code, c.itemCodes.length]))
    expect(counts).toEqual({
      ER: 6, RE: 6, EO: 7, EM: 6, DI: 6, TC: 6, DP: 6, DS: 6, PS: 7, AS: 5, IR: 5, PC: 5,
    })
  })

  it('reads the first and last item codes in document order', async () => {
    const source = toArrayBuffer(readFileSync(fixturePath))
    const questionnaire = await parseQuestionnaireDocx(source)

    expect(questionnaire.items[0].code).toBe('ER_1')
    expect(questionnaire.items[questionnaire.items.length - 1].code).toBe('PC_5')
  })

  it('splits English and Hindi text correctly for a real item', async () => {
    const source = toArrayBuffer(readFileSync(fixturePath))
    const questionnaire = await parseQuestionnaireDocx(source)

    const er1 = questionnaire.items.find((i) => i.code === 'ER_1')!
    expect(er1.english).toBe('My academic submissions are marked and assessed fairly.')
    expect(er1.hindi).toContain('मेरे अकादमिक कार्यों का मूल्यांकन निष्पक्ष रूप से किया जाता है')
  })
})
