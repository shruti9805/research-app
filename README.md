# Research Questionnaire Capture App — working set

Everything you need to start Stage 1. Read this first; it explains what each file is for and
what to do with it.

---

## The files

```
your-app/
├── .claude/
│   └── skills/
│       └── mobile-app-builder/
│           └── SKILL.md          ← HOW to work. Stable, rarely edited.
├── PRODUCT.md                    ← WHAT to build. Yours. The source of truth.
├── ONDEVICE-OPTIONS.md           ← Verified technical research feeding Stage 1.
├── KICKOFF.md                    ← The prompts to paste.
├── README.md                     ← This file.
├── PLAN.md                       ← Created by Claude at Stage 1. Don't write it yourself.
└── src/                          ← The app, from Stage 2 onward.
```

**Why the split.** The skill is process and doesn't change between projects. `PRODUCT.md` is
requirements and is yours. `ONDEVICE-OPTIONS.md` is evidence gathered before planning.
`PLAN.md` is current state and belongs to Claude. Collapsing these into one prompt means
re-pasting everything every session and watching the requirements drift as you edit them
in-place.

| File | Who owns it | Changes |
|---|---|---|
| `SKILL.md` | You, rarely | Almost never |
| `PRODUCT.md` | You | When requirements change — log it in §14 |
| `ONDEVICE-OPTIONS.md` | Reference | When new evidence arrives |
| `PLAN.md` | Claude | Continuously, per component |

---

## Setup

1. `mkdir -p .claude/skills/mobile-app-builder` and put `SKILL.md` there.
2. Put `PRODUCT.md`, `ONDEVICE-OPTIONS.md` and `KICKOFF.md` in the project root.
3. Copy the two sample files in too — the plan depends on them:
   - `samples/Student_Survey_Bilingual.docx` (blank form, the structure source of truth)
   - `samples/Student_Questionnaire_BP_Pujari_1.pdf` (a real filled response)
4. `git init`. The staged process uses commits as checkpoints.
5. Answer the five blocking questions in `PRODUCT.md` §12 before starting. Edit your answers
   straight into the file.

---

## What's already settled

Decisions logged in `PRODUCT.md` §14, so you don't have to re-litigate them each session:

| | Decision |
|---|---|
| 14.1 | Devanagari handwriting is in scope — both scripts appear in free-text fields |
| 14.2 | Marks are ticks **and** dots, possibly others — classify type, then anchor |
| 14.3 | Questionnaires are imported from `.docx` only; no photo/OCR of blank forms |
| 14.4 | Responses arrive as a combined PDF **or** a series of photos |
| 14.5 | No third-party cloud processing — everything runs on the device |
| 14.6 | *Proposed:* school/district/class captured once per batch, not per response |
| 14.7 | No changes to the paper form in v1 — survey already printed |

Decision 14.6 is the only one still awaiting your yes or no. It matters: approving it removes
handwriting recognition from the product entirely.

---

## What the evidence found

Established from the two sample files, with the checks recorded in `PRODUCT.md` §11:

- **71 items, 12 constructs**, no duplicate codes — verified from the docx table.
- **Part B needs no text recognition at all.** English and Hindi share a cell; the answer is a
  mark in one of five ruled columns. That's 71 of ~79 values per response reduced to geometry.
- **Ticks overflow rightward.** The stroke crosses into the next column while the bottom vertex
  stays in the intended one. A centroid-based detector would bias answers toward "Agree" —
  systematically, invisibly, across every response. This is the single most important finding.
- **Dots are the harder case.** A tick's shape proves intent; a dot is geometrically identical
  to a speck, a stray touch, or bleed-through. Position becomes the only discriminator, so
  dot-mode must flag far more readily.
- **Real gaps already exist.** Income and extracurricular are blank in the sample, and two
  stray pen strokes sit in the attendance cell.
- **Scan quality is fine** — 282–424 ppi. The existing Adobe Scan OCR layer is empty and
  unusable.

One caution carried through the docs: a single filled response shows what *can* appear on a
form, never what typically does. That's how the first draft wrongly concluded Devanagari
wasn't a problem.

---

## Running the process

Full prompts are in `KICKOFF.md`. The shape:

1. **Answer the blocking questions** in `PRODUCT.md` §12.
2. **Paste the kickoff prompt.** Claude asks anything still missing, then writes `PLAN.md`.
3. **Review the plan.** It should contain decision records with criteria stated *before*
   options, named trade-offs, and a reversal condition for each choice. If a decision has no
   stated cost, it hasn't been thought through — send it back.
4. **Approve explicitly.** Nothing gets built before this.
5. **One component at a time.** Each reaches the Definition of Done before the next starts,
   and `PLAN.md` is updated before completion is reported.
6. **Resume in new sessions** by pointing Claude at `PRODUCT.md` and `PLAN.md`.

---

## Two things to watch for

**Verify the verification.** Spot-check three `[VERIFIED]` citations early — open the link,
confirm it says what's claimed. If they hold up, the rest probably does. If one is fabricated,
stop and re-check the whole plan. The labels exist to make errors *findable*, and that only
works if you look occasionally.

**Insist on measurement, not argument.** Because form changes are unavailable in v1, the tick
bias and dot ambiguity must be handled entirely in software. The only evidence that the parser
is safe for real research data will be a test against a hand-labelled sample of your own
responses, reported **per mark type**. An aggregate accuracy figure can hide a rightward tick
bias behind good dot performance. If the plan doesn't include that test, it isn't finished.

---

## Scale worth keeping in mind

71 decisions per response × up to 4,000 responses = **284,000 column decisions**. At 99%
accuracy that's 2,840 wrong values in your dataset, and you would have no way of knowing which
ones. That is why the flagging behaviour from your note 8 matters more than headline accuracy:
the goal isn't being right every time, it's never being confidently wrong in silence.
