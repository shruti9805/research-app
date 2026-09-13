import mammoth from 'mammoth'

export interface QuestionnaireItem {
  code: string
  construct: string
  english: string
  hindi: string
}

export interface Construct {
  code: string
  itemCodes: string[]
}

export interface Questionnaire {
  items: QuestionnaireItem[]
  constructs: Construct[]
}

/** mammoth's Node build wants {buffer}, its browser build wants {arrayBuffer}. */
async function convertDocxToHtml(source: ArrayBuffer): Promise<string> {
  const input = typeof Buffer !== 'undefined' ? { buffer: Buffer.from(source) } : { arrayBuffer: source }
  const { value: html } = await mammoth.convertToHtml(input)
  return html
}

function textOf(el: Element): string {
  return (el.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Parses the 71-item Likert table out of the questionnaire .docx.
 * Expects a table whose header row reads SrNo / Code / Statement (English / Hindi) / 1..5,
 * each data row's Code cell holding e.g. "ER_1" and its Statement cell holding the English
 * and Hindi text separated by a single <br>. Throws rather than guess if that shape doesn't
 * hold — a silently wrong template would corrupt every response scored against it (PRODUCT.md §11.1).
 */
export async function parseQuestionnaireDocx(source: ArrayBuffer): Promise<Questionnaire> {
  const html = await convertDocxToHtml(source)
  const doc = new DOMParser().parseFromString(html, 'text/html')
  const tables = Array.from(doc.querySelectorAll('table'))

  const itemsTable = tables.find((table) => {
    const headerCells = Array.from(table.querySelectorAll('tr')[0]?.querySelectorAll('td') ?? [])
    const headerText = headerCells.map(textOf)
    return headerText[0] === 'SrNo' && headerText[1] === 'Code'
  })

  if (!itemsTable) {
    throw new Error(
      'Could not find the 71-item table in this .docx (expected a table with header row starting "SrNo", "Code"). Refusing to guess.',
    )
  }

  const rows = Array.from(itemsTable.querySelectorAll('tr')).slice(1) // drop header
  const items: QuestionnaireItem[] = rows.map((row, rowIndex) => {
    const cells = Array.from(row.querySelectorAll('td'))
    const code = textOf(cells[1])
    const statementCell = cells[2]
    const parts = statementCell.innerHTML.split(/<br\s*\/?>/i)
    if (parts.length !== 2) {
      throw new Error(
        `Row ${rowIndex + 1} (code "${code}"): expected exactly one line break splitting English/Hindi in the statement cell, found ${parts.length - 1}.`,
      )
    }
    const [englishHtml, hindiHtml] = parts
    const english = textOf(parseFragment(englishHtml))
    const hindi = textOf(parseFragment(hindiHtml))
    const construct = code.split('_')[0]
    if (!code || !construct) {
      throw new Error(`Row ${rowIndex + 1}: could not read a valid item code from "${code}".`)
    }
    return { code, construct, english, hindi }
  })

  const seen = new Set<string>()
  for (const item of items) {
    if (seen.has(item.code)) {
      throw new Error(`Duplicate item code "${item.code}" — every code must be unique (PRODUCT.md §11.1).`)
    }
    seen.add(item.code)
  }
  if (items.length !== 71) {
    throw new Error(`Expected exactly 71 items, parsed ${items.length}. Refusing to emit a wrong-sized template.`)
  }

  const constructs: Construct[] = []
  for (const item of items) {
    const existing = constructs.find((c) => c.code === item.construct)
    if (existing) {
      existing.itemCodes.push(item.code)
    } else {
      constructs.push({ code: item.construct, itemCodes: [item.code] })
    }
  }

  return { items, constructs }

  function parseFragment(fragmentHtml: string): Element {
    const wrapper = doc.createElement('div')
    wrapper.innerHTML = fragmentHtml
    return wrapper
  }
}
