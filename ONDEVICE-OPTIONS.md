# On-device processing — options and recommendation

Prepared 2026-09-12, after you ruled out sending response images to third-party servers.

Status: **input to Stage 1, not a decision.** Nothing here has been measured on your forms.
Every accuracy claim needs a labelled-sample test before it goes into PLAN.md.

---

## 1. What ML Kit actually does — verified

| | |
|---|---|
| Runs on-device, no network | Yes `[VERIFIED]` |
| Devanagari script | Yes, via a dedicated script model `[VERIFIED]` |
| Android + iOS | Both `[VERIFIED]` |
| App size cost | ~38 MB per script SDK `[VERIFIED]` |
| Speed | Real-time for Latin; **slower for other scripts** `[VERIFIED]` |

<cite index="4-1">Text Recognition v2 recognises text in Chinese, Devanagari, Japanese, Korean and Latin scripts, analyses text structure by identifying blocks, lines, elements and symbols, and returns bounding boxes, corner points and confidence scores for each.</cite> <cite index="9-1">It runs entirely on-device, with no network call and no cloud billing.</cite> Source:
https://developers.google.com/ml-kit/vision/text-recognition/v2 — checked 2026-09-12.

Packages: `play-services-mlkit-text-recognition-devanagari` on Android,
`GoogleMLKit/TextRecognitionDevanagari` on iOS. `[VERIFIED: official setup docs]`

### The catch that decides the architecture

**ML Kit Text Recognition is built for printed text, not handwriting.** Google's own framing
is receipts, business cards, credit cards and street signs. <cite index="20-1">Handwritten
recognition is limited to basic shapes, and complex or cursive handwriting has lower
accuracy.</cite> A Firebase issue reports plainly that <cite index="19-1">it recognises digital
photos well but fails badly on handwritten text.</cite>

**ML Kit's Digital Ink Recognition does handle handwriting, including Devanagari — but it
cannot read a photograph.** <cite index="20-1">It processes sequences of touch or stylus strokes:
time-ordered x, y, timestamp coordinates captured from a touchscreen.</cite> There are no
strokes in a scanned page, only pixels. It is the wrong tool for this product.

**So ML Kit does not solve handwritten Devanagari from a photo.** Neither does any other
on-device library I'd want to bet your dataset on. `[INFERRED]`

That sounds like bad news. It isn't, because of §2.

---

## 2. The reframe: you don't need handwriting recognition at all

Only four fields on the entire form are handwritten free text: **school name, district/block,
class/grade, and place**. Everything else is a mark in a box.

Now look at what those four fields actually contain:

| Field | Sample value | How often does it change? |
|---|---|---|
| School name | B.P. Pujari Gr.EM | Once per school — constant across ~200 responses |
| District / Block | Raipur / Dharsiwa | Follows from the school |
| Class / Grade | 9th "A" | A small fixed set |
| Place (consent) | Raipur | Same as district, usually |

**You are standing in the school when you collect these.** You know its name. Recognising it
from handwriting 200 times — with error, in two scripts, on a phone — is solving a problem you
don't have.

**Recommendation: capture this once per batch, not once per response.** Before scanning a
school's stack, pick school, district and class from a list. Every response in that batch
inherits them. Recognition error on these fields drops to zero because there is no recognition.

Your form already anticipates this. It carries **"For researcher use only: Respondent Number
___ | School Code ___"** on page 1. `[VERIFIED]` That's the identity mechanism, already
designed in — it was simply left blank in the sample.

With this change, **no handwriting recognition is needed anywhere in the product**, and fully
on-device becomes not a compromise but the straightforwardly correct architecture.

---

## 3. Where ML Kit *is* strong here — and now load-bearing

> **Status changed 2026-09-12.** With form changes ruled out for v1 (PRODUCT.md §14.7), this
> is no longer one option among several. It is the only reliable row-anchoring mechanism
> available, and the plan should treat it as a critical-path component.


The form has a printed **Code column**: `ER_1`, `ER_2`, … `PC_5`, in Latin script. `[VERIFIED:
docx structure]` That is printed text — exactly what ML Kit is good at, and the fast Latin
model at that.

Read that column and every row **identifies itself**, with a bounding box giving its vertical
position on the page. The benefits compound:

- **No dependence on row order or row counting.** Rows are matched by code, not by index, so a
  missed or doubled row can't silently shift every subsequent answer — the single most
  dangerous failure mode in grid parsing. `[INFERRED]`
- **Photos can arrive in any order.** Each page announces which items it contains, so page
  sequencing stops being the researcher's problem. This matters directly for note 10.
- **Missing pages are detectable.** If codes `EO_3` through `EM_1` never appear, the app knows
  a page is missing rather than recording those items as unanswered.
- **Row height variation stops mattering.** Rows vary because Hindi text wraps `[VERIFIED]`;
  code positions give exact per-row vertical bounds regardless.

This uses ML Kit precisely where it's reliable and avoids it entirely where it isn't.

---

## 4. The marks themselves — classical computer vision, not ML

Detecting which of five ruled columns contains a mark is a geometry problem, not a learning
problem. Part B is a fully ruled table `[VERIFIED]`, so line detection gives the grid, and
per-cell ink analysis gives the answer.

This is worth stating plainly because it's the bulk of the value: **71 of the ~79 values per
response need no machine learning at all.** Classical CV is deterministic, debuggable,
testable, runs fast on a phone, and adds nothing to app size — all properties a research
instrument should want over a model whose errors you can't inspect.

Mark-type classification (tick / dot / cross / circle / digit) then anchoring per §11.3 of
PRODUCT.md sits on top of this.

**Scale check:** 71 decisions × 4,000 responses = **284,000 column decisions**. At 99%
accuracy that is 2,840 wrong values. This is why the flagging behaviour in note 8 carries more
weight than raw accuracy — the goal is not to be right every time, it's to never be *confidently
wrong* without saying so.

---

## 5. Form redesign — deferred to a future version

An earlier draft of this document recommended changing the printed form: corner registration
marks, a QR code, wider answer columns, explicit answer boxes. On accuracy-per-effort this was
the strongest lever available, and none of it required code.

**It is not available.** The survey is already printed and collection is under way, so v1 must
parse the form exactly as it exists. These ideas are recorded in PRODUCT.md §17 as candidates
for a future version, and should be applied to the next questionnaire you design rather than
forgotten.

### What this costs v1, concretely

Three things get harder, and the plan should account for each:

1. **Page geometry must be corrected without reference points.** No known landmarks means
   perspective and rotation are estimated from page content. Adobe Scan already does this
   competently on your sample — which is the strongest argument for importing its output
   rather than rebuilding capture in-app. See Q13.
2. **The grid must be found by detecting ruled lines**, not by geometry from fixed marks. Part
   B is fully ruled `[VERIFIED]`, so this is workable, but it is search rather than lookup and
   it can fail on a poor scan.
3. **Respondent identity has no machine-readable carrier.** Without a QR code, identity comes
   from the handwritten Respondent Number field, batch metadata plus stack order, or manual
   entry. This is now an open question rather than a solved one — see Q2.

### What partly compensates

The printed Code column (§3) survives all of this. It is printed, in Latin script, and
uniquely identifies each of the 71 rows. Anchoring on it recovers most of what registration
marks would have provided at the row level, though nothing at the page-geometry level.

**The tick-overflow bias (§11.3) cannot be designed away in v1.** Wider columns would have
attacked it at source; instead it must be handled entirely in the parser, through mark-type
classification and apex anchoring, and then *measured* to prove the residual error is
directionally balanced. This raises the importance of the labelled-sample test in §6 from
good practice to mandatory.

## 6. What still needs deciding at Stage 1

- **Cross-platform framework vs native**, given OpenCV-class image processing needs native code
  either way. This is a real cost driver for the Android+iOS requirement.
- **Whether Apple's Vision framework** is a better fit than ML Kit on iOS for the printed-code
  reading, including whether its Devanagari support is adequate. `[UNKNOWN — must verify]`
- **Measured accuracy per mark type** on a hand-labelled set of your real responses. Nothing
  above is trustworthy until this exists.
- **The review workflow** — what fraction gets flagged, and how fast a flagged response can be
  corrected. A parser that flags 30% of fields is worse than typing.

---

## 7. Honest summary

Ruling out cloud processing costs you very little here, because the one task that genuinely
needed cloud-grade models — handwritten Devanagari — turns out to be avoidable rather than
hard. What remains is grid geometry, mark detection, and printed-Latin reading, all of which
run comfortably on a phone.

The risks that remain are not about recognition power. They are systematic tick bias (§11.3),
dot-versus-speck ambiguity, and row misalignment.

Two of those three would have been substantially reduced by changing the form. That option is
gone for v1, so all three must be handled in software and demonstrated by measurement rather
than argued for. The labelled-sample test is therefore not a nice-to-have in the plan — it is
the only evidence that will exist that the parser is safe to use on real research data.
