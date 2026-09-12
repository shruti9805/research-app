# PRODUCT.md — Research Questionnaire Capture App

**Version 3** — revised after analysing `Student_Survey_Bilingual.docx` (blank form) and
`Student_Questionnaire_BP_Pujari_1.pdf` (one real filled response), then corrected by four
decisions from you on 2026-09-12 (logged in §14).

> **Methodological note carried forward.** One filled response tells us what *can* appear on a
> form, never what *typically* appears. Version 2 over-generalised from a single sample and
> concluded Devanagari handwriting was a non-issue; you corrected that. Any claim in §11 tagged
> `[VERIFIED]` should be read as "observed at least once", not "true of all responses".

> **Provenance tags.** Nothing here should be mistaken for a requirement you didn't give:
>
> - `[N#]` — from numbered note N in your handwritten pages.
> - `[VERIFIED]` — measured from the two sample files this session (2026-09-12), with the
>   check that produced it.
> - `[INFERRED]` — my reading between the lines. **Check these.**
> - `[OPEN]` — unknown. Listed in §12.
>
> Notes 14–18 are *process* requirements, encoded in the `mobile-app-builder` skill. They're
> in §13 for traceability only.

---

## 1. One-liner

A mobile app (iOS + Android) that turns photographs of filled paper questionnaires into
structured Excel data, so a PhD researcher can collect field responses on paper and get
analysable spreadsheets without manual data entry. `[N1, N2, N3, N5]`

## 2. The problem

A PhD research student collects questionnaire responses in person from people in their field
of research. `[N5]` Responses are filled in manually on paper. `[N9]` Getting those into an
analysable form means transcribing by hand — at 71 items per response `[VERIFIED: item-code
count in the docx]` and 200–4,000 responses per questionnaire `[N8]`, that is between 14,200
and 284,000 individual values typed by hand.

**Why mobile:** the workflow involves collecting a lot of photos, and phones are the natural
capture device. `[N13]` Confirmed by the sample — it was produced with Adobe Scan for Android.
`[VERIFIED: PDF Creator metadata]`

**Why accuracy dominates:** a slight mistake can affect the results of the research. `[N8]`
See §9 and the systematic-bias risk in §11.3.

## 3. Who it's for

**Primary user: the researcher.** Designs the questionnaire, goes into the field, collects
filled paper forms, photographs them, and later pulls insights. `[N5]` Technically capable but
not a developer. `[INFERRED]`

**Secondary subject: the respondent.** Here, a school student — the sample is a Class 9
student. `[VERIFIED]` They fill paper only and never touch the app. `[INFERRED]` Being under
18, guardian consent is required and is captured on the form itself. `[N6, VERIFIED: page 1
is a parent/guardian consent form with signature, date and place]`

`[OPEN — Q1]` Whether field enumerators other than you also use the app.

## 4. The core loop

### Flow A — Register a questionnaire (once per questionnaire)

**DECIDED (§14.3): Word document only.** The app imports the source `.docx` and treats it as
the single source of truth for questionnaire structure. Photo-based registration of a blank
form is **not built** — it is rejected at the file picker.

This supersedes notes 2 and 3, which described photographing the blank form and OCRing it.
Rationale in §11.1: the template is what all 4,000 responses are scored against, so a
recognition error there propagates everywhere.

Consequence to accept: a questionnaire that exists only on paper cannot be registered. The
researcher must retype it into Word first. That is the intended trade — one hour of retyping
against a silent structural error affecting every response. `[INFERRED]`

The output is an Excel structured to receive responses for up to N candidates in
one file `[N6]`, splitting into multiple files only if size genuinely becomes a problem. `[N6]`

### Flow B — Capture a response (many times; the main capability) `[N4]`

1. Select which questionnaire this response belongs to. `[N4]`
2. Provide the filled response as **either** a combined PDF **or** a series of photos —
   uploaded all at once, or one by one until you signal done. `[N10, DECIDED §14.4]` A full
   response is **6 pages**, shot as two-page spreads. `[VERIFIED: 6 PDF pages, pages 2–6 each
   containing a two-page spread]` Both input paths must reach the same parser.
3. Determine which language each answer was given in, and parse accordingly. `[N9]` — note
   this works differently than the notes assume; see §11.4.
4. Parse and record the response against a person. `[N4]`
5. Anything not confidently parsed is **left blank and flagged**, naming what was unclear.
   `[N8]`
6. Write the parsed response into that questionnaire's Excel. `[N6, N10]`

## 5. Features

### Must have

- [ ] **Questionnaire registration from `.docx` only** → response-ready Excel with all 71
      items, their codes, construct groupings, and both language variants. Non-Word files
      rejected with a clear message. `[DECIDED §14.3, VERIFIED]`
- [ ] **Questionnaire library**, selectable at capture time. `[N4]`
- [ ] **Response intake in two formats** — a combined PDF, or a series of photos (batch or
      one-at-a-time with an explicit done signal). `[N10, DECIDED §14.4]`
- [ ] **Grid/table detection** on Part B — locate the ruled 71-row × 5-column answer grid.
      `[VERIFIED: Part B is a fully ruled table]`
- [ ] **Mark-type classification then position detection** — identify what kind of mark was
      used (tick, dot, cross, circle, written digit), then apply the anchoring rule
      appropriate to that type. See §11.3, which changed materially now that dots are in
      scope. `[N9, DECIDED §14.2]`
- [ ] **Dot-mode false-positive suppression.** A dot carries no distinguishing shape, so it
      cannot be separated from a stray pen mark, scanner speck, or paper flaw by appearance
      alone. Position within the cell has to do that work. `[DECIDED §14.2 + VERIFIED §11.6]`
- [ ] **Checkbox detection** on Part A demographics, including EN/HI duplicate reconciliation.
      `[VERIFIED — see §11.4]`
- [ ] **Handwritten text capture in both Latin and Devanagari** for the free-text fields:
      school name, district/block, class/grade, and place. Respondents may write these in
      either script. `[DECIDED §14.1]` This is the hardest recognition task in the product and
      the main driver of the Q4 decision — see §11.4.
- [ ] **Consent record capture** — the tick, signature presence, date, and place from page 1.
      `[N6, VERIFIED]`
- [ ] **Uncertainty flagging** — unparsed fields left empty and surfaced with what was
      unclear. `[N8]` Exercised immediately: the sample has genuinely unanswered fields
      (§11.5).
- [ ] **Blank-vs-unreadable distinction.** An unanswered field and an unreadable one are
      different facts and must not collapse into the same empty cell. `[INFERRED from N8]`
- [ ] **Respondent identity linkage** via the Respondent Number / School Code fields already
      printed on the form. `[N4, VERIFIED: "For researcher use only — Respondent Number ___ |
      School Code ___" exists on page 1; blank in this sample]`
- [ ] **Excel output**, up to N candidates per file, splitting only under size pressure. `[N6]`
- [ ] **Android and iOS.** `[N11]`
- [ ] **APK and IPA distribution.** `[N12]` — caveat in §7.

### Should have

- [ ] Review/correction screen to fix flagged fields before committing. `[INFERRED — flagging
      is only useful if there's somewhere to act on it]`
- [ ] Per-questionnaire progress view (e.g. 340 of 4,000 captured). `[INFERRED from N8]`
- [ ] Re-parse a response after a failed attempt.
- [ ] Construct-level grouping in the Excel (ER, RE, EO, EM, DI, TC, DP, DS, PS, AS, IR, PC)
      so scale scores are computable downstream. `[VERIFIED: 12 constructs — see §11.1]`
- [ ] Export/share the Excel out of the app. `[OPEN — Q5]`

### Not in v1

- [ ] Analysis or insight generation in-app — insights are pulled later, from the Excel. `[N5]`
- [ ] In-app questionnaire authoring (authored in Word). `[VERIFIED]`
- [ ] Languages beyond Hindi and English. `[OPEN — Q6]`
- [ ] Multi-researcher collaboration. `[OPEN — Q1]`

## 6. What it explicitly does not do

- Does not replace the paper form. `[N9]`
- Does not analyse results. `[N5]`
- Is not used by the respondent. `[INFERRED]`
- Does not need to transcribe the signature — only record that one is present. `[INFERRED —
  confirm in Q3]`

## 7. Constraints

| | |
|---|---|
| **Platforms** | iOS and Android, both required `[N11]` |
| **Distribution** | APK + IPA, installable directly `[N12]` — caveat below |
| **Input languages** | Hindi (Devanagari) and English, **in handwriting as well as print** `[N6, N9, DECIDED §14.1]` |
| **Questionnaire input** | `.docx` only `[DECIDED §14.3]` |
| **Response input** | Combined PDF or a series of photos `[DECIDED §14.4]` |
| **Mark conventions** | Tick, dot, and others — not a fixed convention `[DECIDED §14.2]` |
| **Excel language** | English counterpart alone is acceptable `[N6]` |
| **Items per response** | 71 Likert items + 8 demographic fields + consent block `[VERIFIED]` |
| **Photos per response** | 6, as two-page spreads `[VERIFIED]` |
| **Volume** | 200–4,000 responses per questionnaire `[N8]` → up to ~24,000 photos |
| **Scan source** | Adobe Scan for Android, 282–424 ppi, JPEG in PDF `[VERIFIED: pdfimages]` |
| **Existing OCR layer** | None usable — 1 byte of text per page `[VERIFIED: pdftotext]` |
| **Accuracy** | High; errors corrupt research results `[N8]` |
| **Who builds it** | `[OPEN — Q7]` |
| **Timeline / budget** | `[OPEN — Q7]` |
| **Backend / offline** | Fully on-device, no network processing `[DECIDED §14.5]` |
| **Ethics / compliance** | `[OPEN — Q8]` — minors' data and consent records `[VERIFIED]` |

**Caveat on note 12.** APK installs directly on Android. For iOS, Apple restricts installing
an IPA outside the App Store, and the available routes carry limits on device counts, tester
counts, eligibility, or annual cost. Verify against current Apple policy at Stage 1 before
treating "install anywhere" as settled. `[INFERRED — flagged, not asserted; I have not checked
current Apple terms]`

## 8. Native capabilities needed

- [x] **Camera** `[N2, N10, N13]` — or import from Adobe Scan / gallery `[VERIFIED: that's
      how the sample was produced]`
- [x] **Local storage** — questionnaires, photos, Excel, parse results `[INFERRED]`
- [x] **File export / share sheet** `[INFERRED from N3]`
- [ ] **Network** — **not needed for parsing** `[DECIDED §14.5]`
- [x] **On-device ML** — ML Kit Text Recognition for printed text only `[DECIDED §14.5]`
- [ ] Location, Bluetooth, background execution, payments, widgets, AR — **not needed**

## 9. Success criteria

**Product**

- A response is captured end to end without typing any of the 71 values by hand. `[N1–N5]`
- Capturing one response is meaningfully faster than typing it. `[INFERRED]`

**Technical** — numbers needed before Stage 1 `[OPEN — Q9]`:

- Mark-position accuracy on Part B: target `___`%, measured on a hand-labelled sample.
- **Zero systematic directional bias.** Column errors must not lean consistently one way.
  Random error adds noise; directional error shifts every construct mean and silently changes
  the research conclusion. See §11.3 — the sample shows this is a live risk, not a
  hypothetical one. `[VERIFIED + N8]`
- **No silent wrong values.** A missed flag is worse than a false flag: the first corrupts
  data invisibly, the second costs a glance. `[N8]`
- Every flagged field names what specifically was unclear. `[N8]`
- Holds up across the full 200–4,000 range. `[N8]`

## 10. Look and feel

`[OPEN — Q10]`

---

## 11. Findings from the sample files

All measured on 2026-09-12 from the two supplied files. These are the facts the Stage 1 plan
should be built on.

### 11.1 The blank questionnaire is already structured data

`Student_Survey_Bilingual.docx` is a Word document containing a proper table: 71 rows, each
with a code, an English statement, a Hindi statement, and five answer columns.

- **71 items**, zero duplicate codes. `[VERIFIED: regex extraction]`
- **12 constructs**: ER 6, RE 6, EO 7, EM 6, DI 6, TC 6, DP 6, DS 6, PS 7, AS 5, IR 5, PC 5.
  `[VERIFIED]`
- Part A is a second table of 8 demographic rows with 30 checkbox glyphs. `[VERIFIED]`

**This contradicts notes 2 and 3.** Photographing the blank form and OCRing it converts
perfect structured data into pixels, then tries to recover the structure with error. Reading
the `.docx` gives the same result with no recognition step and therefore no recognition error
— and this is the *template* every response is scored against, so an error here propagates
into all 4,000 responses, not one.

Photo-based registration still has a real use: when the questionnaire exists only on paper
and no source file survives. Recommendation for Stage 1 is to treat the docx import as the
primary path and photo registration as the fallback. **Your call — flagging, not deciding.**

### 11.2 The instruction and the actual behaviour disagree

Part B tells the student to *write a number between 1 and 5*. `[VERIFIED: docx text]` The
student **ticked a column instead**. `[VERIFIED: all 71 items in the filled PDF are ticks]`

You have confirmed that other responses use **dots**. `[DECIDED §14.2]` So the observed set is
already at least {written digit (instructed), tick (observed), dot (confirmed)}, and circles
and crosses are plausible from the same population.

The parser therefore cannot assume a convention, and cannot assume consistency *within* one
response either — a respondent may tick some rows and dot others. Mark-type classification has
to run per cell, not once per page. `[INFERRED]`

### 11.3 Mark geometry — and why dots change the rule

This remains the most important technical finding, but the correction in §14.2 changes the
answer.

**What was observed.** Checkmarks are large relative to the column width and **routinely
overflow to the right**: the ascending stroke crosses into the next column while the **bottom
vertex sits in the intended column**. `[VERIFIED: 5× render, items ER_1, ER_5, RE_5, RE_6,
EO_1, EO_2]`

A detector using ink centroid or maximum ink overlap per cell will therefore resolve a
meaningful share of ticked answers **one column to the right** — toward "Agree" and "Strongly
Agree". That is not random noise. It inflates every construct mean in one direction,
invisibly and consistently across all 4,000 responses, which is exactly the failure note 8
warns about.

**Why "lowest vertex" is not a universal fix.** Version 2 proposed anchoring on the mark's
lowest vertex. That works for a tick. It does not generalise:

| Mark | Overflow behaviour | Correct anchor |
|---|---|---|
| Tick (✓) | Large, overflows right | Bottom vertex |
| Dot (•) | Compact, no overflow | Centroid |
| Cross (✗) | Symmetric overflow both ways | Centroid / intersection |
| Circle (◯) | May enclose the column label | Enclosed region centre |
| Written digit | No position meaning at all | Recognise the glyph, ignore position |

A single anchoring rule applied to all of them will be wrong for most. **Classify the mark
type first, then anchor accordingly.** `[INFERRED from §14.2]`

**The dot case is the dangerous one.** A tick is unmistakably an intentional mark — its shape
is evidence of intent. A dot has no shape to reason about. It is geometrically identical to
a stray pen touch, a scanner speck, ink bleed-through from the reverse side, or a paper flaw.
The sample already contains two stray pen strokes in the attendance cell `[VERIFIED, §11.6]`,
and against dots that class of noise becomes indistinguishable from signal by appearance.

Position becomes the only discriminator: an intended dot sits inside a cell, roughly centred;
noise does not. This is a weaker signal than shape, so **dot-mode should flag for review far
more readily than tick-mode**. Under note 8's logic a flagged good answer costs a glance,
while a speck silently recorded as a "1" corrupts the data. `[INFERRED from N8]`

**Requirement for the plan:** measure error *per mark type* on a labelled sample, and
demonstrate that residual error is directionally balanced in each mode separately. An
aggregate accuracy number would hide a tick-mode rightward bias behind good dot-mode
performance.

### 11.4 Where language actually matters — corrected

Version 2 concluded that the Devanagari handwriting problem "largely does not exist". **That
was wrong**, and it is worth being precise about why: the sample student happened to write
the free-text fields in Latin script, and v2 generalised one observation into a property of
the form. You have confirmed other respondents write those fields in Devanagari.
`[DECIDED §14.1]`

The corrected picture, split by section:

- **Part B (71 items) — language genuinely irrelevant.** English and Hindi sit in the *same
  cell*, and the answer is a mark in a numbered column. No text recognition is needed for 71
  of the ~79 values per response. `[VERIFIED]` This part is a mark-position problem and it
  stays that way regardless of script. It is the bulk of the data and the easier half.
- **Part A checkboxes — a reconciliation problem.** English and Hindi are *duplicate parallel
  columns*. The sample student ticked **both sides** for attendance, gender, and home digital
  access. `[VERIFIED]` The duplication is useful: it gives a free cross-check, and
  EN/HI disagreement is a strong flag signal.
- **Part A free text — genuinely bilingual handwriting recognition.** School name,
  district/block, class/grade, and place may be written in **either Latin or Devanagari**.
  `[DECIDED §14.1]` Script has to be detected per field, not per response — a respondent could
  write the school name in Devanagari and the class as "9th A".

**Why this drives the Q4 decision.** Handwritten Devanagari is a materially harder recognition
task than handwritten Latin: fewer mature models, conjunct consonants, and vowel marks placed
above and below the base line. Support for it is noticeably better in cloud recognition
services than in on-device libraries. `[INFERRED — must be verified with real accuracy testing
at Stage 1, not assumed]`

So the free-text fields are what pull toward cloud processing, while Part B needs nothing of
the sort. That asymmetry opens a design option worth evaluating at Stage 1 — see §11.8.

### 11.5 Real unanswered fields already appear in the sample

Annual family income and extracurricular involvement are **both blank**. `[VERIFIED]` The
flagging requirement is exercised on the very first real response, and "blank because
unanswered" must be distinguishable from "blank because unreadable".

### 11.6 Stray marks are present

The attendance cell contains two stray pen strokes in addition to the intended tick.
`[VERIFIED]` A naive ink-presence detector would read these as answers. False-positive
suppression is a v1 requirement, not a refinement.

### 11.7 Scan quality is sufficient

282–424 ppi, ~3,500 × 2,500 px per spread. `[VERIFIED: pdfimages -list]` No usable text layer
despite declared fonts — Adobe Scan embedded font references but no extractable text.
`[VERIFIED: pdftotext returns 1 byte per page]` Resolution is not a limiting factor; the
existing OCR layer is not reusable.

### 11.8 A hybrid option the asymmetry creates

Because Part B needs no text recognition at all, the only content that requires strong
handwriting recognition is roughly **four small fields per response** — school, district,
class, place — plus the consent date and place.

That means "send the response to the cloud" is not the only choice available. A third path
exists: detect the grid and all 71 marks on the device, crop only those few small text
regions, and send just the crops for recognition.

Compared with uploading six full pages, this would send a very small fraction of the image
data, remove the student's ticked answers from anything transmitted, and cut per-page
processing costs proportionally. It also degrades gracefully — with no connectivity, the 71
Likert values still parse locally and only the text fields are left pending.

Flagged as an option to evaluate properly at Stage 1, with measured accuracy and cost. Not a
recommendation yet: cropping accurately is its own engineering problem, and a wrong crop
silently loses a field. `[INFERRED]`

---

## 12. Open questions

**Closed so far:** Q0 (sample files supplied), Q4 (no cloud — §14.5), Q10 (question types),
Q11 (you author in Word, but cannot change the form now — §14.7).

### Blocking — Stage 1 cannot produce a sound plan without these

**Q2 — How does a response get tied to a person?** More acute now that a QR code is off the
table (§14.7). On the real collected forms, are "Respondent Number" and "School Code" actually
filled in? They were blank in the sample. If they're filled, they're the key. If not, identity
has to come from batch metadata plus physical stack order, or from you typing a number per
response — and that choice shapes the whole capture screen.

**Q9 — Accuracy bar and review policy.** What parse accuracy would you accept? And do you
intend to review every parsed response, or only the ones flagged? This decides whether the app
is a parser with a review screen or a review tool with parsing assistance — a fundamentally
different product.

**Q13 — Adobe Scan, or in-app capture?** Your sample came from Adobe Scan for Android, which
already deskews and crops well. `[VERIFIED]` With no registration marks available (§14.7), the
app is dependent on whatever corrects page geometry. Reproducing that badly in-app would be a
step backwards; importing Adobe Scan's PDF output may be the better design. Which do you want?

**Q14 — Is collection finished or ongoing?** "The survey is already done" could mean the
pilot is complete with main collection ahead, or all responses are collected and simply need
digitising. The first is a field tool; the second is a bulk-import tool with a very different
interface. How many responses exist on paper right now?

**Q7 — Team, timeline, budget.** Who writes the code, and what do they already know well? This
is usually the strongest single predictor of which framework is right. When does it need to
work, and what can be spent on developer accounts and devices?

### Important — needed before the relevant component is built

**Q1 — Who uses the app?** Just you, or do field enumerators also collect and upload? Does
data from several people need to merge into one Excel?

**Q3 — Consent handling.** Is capturing the tick, date and place enough, or does the signature
image itself need to be retained and retrievable per respondent for your ethics records?

**Q5 — Where does the Excel go, and what do you analyse in?** SPSS, R, Python, Excel? The
output layout should match the tool — SPSS and R want one row per respondent with one column
per item code, which is not the most human-readable arrangement.

**Q8 — Research ethics.** Is this under an institutional ethics board? Any rules about where
respondent data may be stored, even on-device? Minors' data usually attracts stricter handling,
and it affects whether the phone needs encryption at rest.

**Q12 — Is the printed form identical across print runs and schools?** Same Word file, same
printer settings, same margins? If the grid lands in the same place every time, a fixed
template match becomes possible and accuracy rises. If layout drifts, the parser must find the
grid from scratch on every page.

**Q15 — Are the forms grouped by school when you scan them?** The batch-metadata proposal
(§14.6) assumes you process one school's stack at a time. If the stack is mixed, that idea
needs rethinking.

**Q16 — One response per PDF?** The sample is `..._BP_Pujari_1.pdf`, which suggests a numbered
series. Does each PDF hold exactly one student's response, or can several be combined?

### Lower priority

**Q6 — Languages.** Hindi and English only, or might other Indian languages follow? Cheap to
design for now, expensive to retrofit.

**Q17 — Retention of source images.** After parsing, do the photos need keeping as an audit
trail — some ethics protocols require it — or should they be deleted to limit data held?

---

## 14. Decisions log

Recorded 2026-09-12. These override earlier readings of the notes.

**14.1 — Devanagari handwriting is in scope.** The sample student wrote free-text fields in
Latin script, but other respondents write them in Devanagari. Both scripts must be supported
in the free-text demographic fields. Corrects §11.4, which had over-generalised from one
sample.

**14.2 — Marks are not always ticks.** Dots are confirmed in other responses. The parser must
classify mark type and anchor position accordingly, and must treat dot-mode as
higher-uncertainty. Rewrites §11.3.

**14.3 — The Word document is the source of truth for questionnaires.** The app accepts
`.docx` only for questionnaire registration. Photographing and OCRing a blank form is not
built. Supersedes notes 2 and 3.

**14.4 — Responses arrive as a combined PDF or a series of photos.** Both paths required,
both feeding the same parser.

**14.5 — No third-party cloud processing.** Response images must not be sent to outside
servers, on privacy grounds. All parsing runs on the device. This closes Q4 and rules out the
cloud and hybrid options in §11.8. See `ONDEVICE-OPTIONS.md` for what this implies — in short,
it costs less than expected, because the one task that needed cloud-grade models turns out to
be avoidable.

**14.7 — No changes to the paper form in v1.** The survey is already printed and collection
is under way, so registration marks, QR codes, wider answer columns and explicit answer boxes
are **not available**. The parser must work with the form exactly as it exists today. These
ideas move to §17 as future-version candidates.

*Consequence:* the printed Code column (`ER_1` … `PC_5`) becomes the **only** reliable row
anchor available. What was an elegant option in `ONDEVICE-OPTIONS.md` §3 is now load-bearing.
Likewise, page deskewing must rely on whatever produced the scan — which raises the priority
of Q13.

**14.6 — Proposed, pending your approval: batch-level metadata.** School, district and class
are selected once per school visit rather than recognised from handwriting on each form. This
removes handwriting recognition from the product entirely. Not yet decided — see
`ONDEVICE-OPTIONS.md` §2.

---

## 15. What Q4 actually means

Plain version, since this decides the architecture.

To read a photograph of a form, software has to analyse the pixels. There are two places that
analysis can run.

**On the phone.** The image never leaves the device. Nothing is uploaded, nothing is stored on
anyone else's computer, and it works with no internet at all. The limitation is that phone-sized
recognition models are generally less capable — which matters specifically for handwritten
Devanagari (§11.4).

**On someone else's servers.** The app uploads the image over the internet to a document-reading
service — the large cloud providers all sell one — which analyses it and sends back the text.
These services are typically more accurate, especially for non-Latin handwriting. In exchange,
the photograph leaves your control: it travels over the internet, is processed on hardware owned
by a company, and is usually held there at least briefly.

**Why this is not purely a technical question here.** Those photographs contain the student's
school name, district, class, and the parent's signature, date and place. The respondents are
minors. The consent form you gave their parents states that responses will be kept strictly
confidential and used only for academic research purposes. `[VERIFIED: docx consent text]`
Whether routing those images through a commercial service is consistent with that undertaking
is a question for your supervisor and your institution's ethics committee, not for me — I can
describe the options accurately, but I am not in a position to judge what your ethics approval
permits.

**The four practical axes:**

| | On device | Cloud service |
|---|---|---|
| Works without internet | Yes | No |
| Devanagari handwriting accuracy | Weaker `[INFERRED]` | Stronger `[INFERRED]` |
| Cost at ~24,000 images | None beyond the phone | Usually priced per page |
| Data leaves your control | No | Yes |

**Two middle paths also exist.** You could run the recognition software on a server your
university controls, which keeps the data inside the institution while still using stronger
models. Or you could use the hybrid in §11.8 — process the 71 Likert marks on the phone and
send only a few small cropped text fields out, which removes the answers and most of the image
from anything transmitted.

**What I need from you:** not a technology choice. Just whether sending these images outside
your control is permitted, whether you have internet where you'll be uploading, and roughly
what budget exists. The plan derives the rest.

---

## 17. Deferred to future versions

Good ideas that are unavailable in v1 because the survey is already printed and in the field
`[DECIDED §14.7]`. Recorded so they aren't rediscovered later as if new.

**17.1 — Corner registration marks.** Four small solid squares at known positions on each
page. Would let the app correct perspective and rotation exactly rather than estimating, and
locate the answer grid by geometry instead of searching for ruled lines.

**17.2 — QR code on page 1** encoding questionnaire ID, school code and respondent number.
Would turn respondent identity from a data-entry step into a scan, and make it impossible to
file a response against the wrong person.

**17.3 — Wider answer columns.** The tick-overflow bias in §11.3 exists partly because the
columns are narrow relative to how people actually tick. Widening attacks the bias at its
source rather than compensating for it in software — likely the highest-value change on this
list.

**17.4 — Explicit boxes in each answer cell** instead of open ruled space. Pulls marks toward
cell centres and makes stray marks easier to reject, which matters most in dot-mode (§11.3).

**17.5 — A "digitisation-friendly" form template** combining all of the above, for the next
questionnaire you design.

**Important for whoever reads this later:** even once these ship, the parser must retain the
v1 path. Responses collected on the current layout will still need parsing, and a parser that
requires registration marks would strand the existing data. `[INFERRED]`

---

## 16. Process requirements (notes 14–18)

Implemented by the `mobile-app-builder` skill, not by the app.

| Note | Requirement |
|---|---|
| 14 | Strategize, plan, then develop. |
| 15 | Understand the app's purpose; justify every design decision with hard proven facts. |
| 16 | Do not hallucinate. Every decision justified with proven facts, including why it is the most optimized way. |
| 17 | Build in stages: strategize → plan → **get approval** → then execute in stages. |
| 18 | Execute in stages: build each component one by one, record the stage done, move on, keep updating the execution plan until ready. |
