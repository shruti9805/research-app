# Research Questionnaire Capture App — Build Plan

Last updated: 2026-09-12 | Current stage: **1 (awaiting approval)** | Current component: none

---

## 0. Read this first — three things that change the plan

Before the technology, three findings from your answers that need a decision from you. Two are
contradictions between what you asked for and what the form allows. I'd rather surface them now
than build around them.

### 0.1 There is no student name on the form

Your answer to Q2 was to record each response against the **student name**. I went back to the
blank questionnaire to find that field. It isn't there.

Part A contains: school name, district/block, class/grade, attendance, gender, family income,
extracurricular involvement, home digital access. The consent page contains a parent signature,
date, place, and two researcher-use fields — Respondent Number and School Code.
`[VERIFIED: full field list extracted from Student_Survey_Bilingual.docx]`

**No student name is collected anywhere on the form.** Likely deliberate — your consent form
promises parents that the child's name will not appear in any research report.
`[VERIFIED: consent text in the docx]`

So the name cannot be parsed. It has to be typed in at capture time, or responses have to be
keyed on something else. **This needs your decision — see Q18 in §11.**

### 0.2 A 99% target means about half your responses carry an error

99% per-item accuracy sounds strong. Across 71 items it isn't:

    0.99 ^ 71 = 0.49

**About 51% of responses would contain at least one wrong value.** At 300 responses that's
roughly 153 corrupted records; at 4,000 it's over 2,000. `[VERIFIED: arithmetic]`

This isn't an argument for a higher target — 99.99% per item is not achievable from photographs
of handwriting. It's an argument that **per-item accuracy is the wrong headline metric.**

What actually protects your data is the flagger. You said you'll review only what the app flags,
so the number that matters is: *of the values the parser gets wrong, what fraction does it flag?*
Call that flagger recall. At 99% accuracy and 95% flagger recall, roughly 1 in 28 responses
carries a silent error. At 99% accuracy and 99.9% flagger recall, it's about 1 in 1,400.

The plan therefore optimises **flagger recall first, accuracy second**, and reports both. See §5
and DR-005.

### 0.3 Mixed stack plus no batch metadata forces the hardest problem back in

You've said the scanning stack is mixed across schools (Q15) and no batch metadata (§14.6).
Together those mean school, district and class must be read from each form individually — in
handwriting, in either Latin or Devanagari, on-device.

That is precisely the task ML Kit is weakest at. `[VERIFIED: ONDEVICE-OPTIONS.md §1]` There is no
on-device library I'd stake your dataset on for handwritten Devanagari.

But note what §0.1 already established: **you have to type something per response anyway**,
because the student name isn't on the form. Adding school and class to that same entry screen
costs a few seconds more and eliminates the single largest source of error in the product.

My recommendation is DR-006. You may disagree; the decision is yours.

---

## 1. Product summary

A Flutter app for Android and iOS that reads photographed paper questionnaires and writes the
responses into an Excel workbook, so questionnaire data reaches analysis without being typed by
hand. 71 Likert items plus demographics per response, 300 collected so far and more coming.

---

## 2. Constraints

| | |
|---|---|
| Platforms | Android + iOS `[N11]` |
| Distribution | APK + IPA, shared directly, no app stores `[Q7]` |
| Budget | Zero — no paid developer accounts `[Q7]` |
| Builder | You, solo, via Claude Code; not a professional developer `[Q7]` |
| Build machine | Mac with Xcode `[Q7]` |
| Processing | Fully on-device, no network `[§14.5]` |
| Users | Two people, each with their own copy `[Q1]` |
| Analysis tool | Excel itself `[Q5]` |
| Ethics constraints | None applicable for now `[Q8]` |
| Form layout | Consistent across print runs `[Q12]` |
| Stack order | Mixed across schools `[Q15]` |
| Volume | 300 now, ongoing `[Q14]` |

---

## 3. Success criteria

| # | Criterion | How it's measured |
|---|---|---|
| S1 | Flagger recall ≥ 99% on the labelled set | Of known-wrong values, the share flagged |
| S2 | Per-item accuracy ≥ 99% on unflagged values | Against hand-labelled ground truth |
| S3 | No directional bias, per mark type | Signed column-error mean within ±0.05 for ticks and for dots separately |
| S4 | Flag rate ≤ 15% of items | Otherwise review costs more than typing |
| S5 | One response processed in under 60s | Wall clock on a real phone, photos to Excel row |
| S6 | Excel opens in Excel with working pivot tables | Manual check |
| S7 | APK installs and runs on a real Android device | From a clean build |
| S8 | IPA builds on your Mac | See DR-007 — the distribution half is unresolved |

S1 is the important one. S2 without S1 is a dataset you cannot trust.

---

## 4. Technology decisions

### DR-001: Cross-platform framework

**Status:** Proposed | **Date:** 2026-09-12

**Context:** Solo non-developer builder, zero budget, both platforms required, heavy image
processing, ML Kit needed, Mac available.

**Criteria, fixed before looking at options:**

| # | Criterion | Weight | Why for this app |
|---|---|---|---|
| C1 | One codebase for both platforms | High | Solo builder; two codebases is two of everything |
| C2 | Mature image-processing and ML Kit packages | High | The product *is* image processing |
| C3 | Free local APK + IPA builds | High | Zero budget, no cloud build service |
| C4 | Approachable for a non-developer with Claude Code | High | You are the only builder |
| C5 | Testable parsing logic outside the app | Medium | Iterating a parser through a phone is painfully slow |

**Options:**

| Option | C1 | C2 | C3 | C4 | C5 |
|---|---|---|---|---|---|
| Flutter | Yes | ML Kit plugin is mature; OpenCV binding less so | `flutter build apk` / `ipa` | Single language, strong docs | Dart runs on desktop |
| React Native (bare) | Yes | ML Kit wrappers exist, fragmented | Works, more native config | JS familiar but native config is the hard part | Node testable |
| Native Kotlin + Swift | No | Best possible | Yes | Two languages, two toolchains | Poor |
| Expo (managed) | Yes | Custom native modules need dev builds | Local prebuild possible | Easiest — until you need native | Limited |

**Decision:** **Flutter** (stable channel).

**Why this wins:** C2 and C5 decide it. `google_mlkit_text_recognition` is at **0.15.1**, from
verified publisher flutter-ml.dev, 383 likes and ~123k downloads, and explicitly supports
Devanagari alongside Latin. `[VERIFIED: https://pub.dev/packages/google_mlkit_text_recognition,
checked 2026-09-12]` No React Native equivalent has that combination of maintenance and reach.

C5 matters more than it looks. The parser is the whole product, and being able to run it as a
plain Dart program against your six sample pages on your Mac — no phone, no rebuild — is the
difference between iterating in seconds and iterating in minutes.

**What we give up:** Flutter's OpenCV story is weaker than native (see DR-002), and app size will
be larger than native because each ML Kit script model adds roughly 38 MB. `[VERIFIED: ML Kit iOS
docs]` With Latin and Devanagari both bundled that is a substantial APK.

**What would change this:** if the parser turns out to need OpenCV features with no usable Dart
binding, native Android first with iOS later becomes more honest than fighting the ecosystem.

**Confidence:** High on Flutter over React Native. Medium on Flutter over native-Android-only,
because your iOS distribution path is unresolved (DR-007) and an Android-only v1 may prove more
useful than a half-distributable universal one.

---

### DR-002: Image processing library

**Status:** Proposed | **Date:** 2026-09-12

**Context:** We need deskewing, ruled-line detection, per-cell ink measurement and mark shape
classification. No registration marks are available. `[§14.7]`

**Criteria, fixed first:**

| # | Criterion | Weight | Why |
|---|---|---|---|
| C1 | Dependency maturity | **Highest** | A broken binding mid-project with no developer to debug it is fatal |
| C2 | Runs on stable Flutter | High | Bleeding-edge toolchains break under a non-developer |
| C3 | Sufficient capability | High | Must actually do the job |
| C4 | Runs in plain Dart for testing | High | Ties to DR-001 C5 |
| C5 | Build size and speed | Medium | |

**Options:**

| Option | C1 | C2 | C3 | C4 |
|---|---|---|---|---|
| `opencv_dart` | ~133 likes, ~8.8k downloads, **self-described WIP** | **Requires Dart 3.10 / Flutter 3.38 native-assets hooks** | Full OpenCV | Yes via `dartcv4` |
| `opencv_core` | Same family, no videoio | Same requirement | Ample | Yes |
| `image` (pure Dart) | Long-established, widely used | Any Flutter | Primitives only — we write the algorithms | Yes, natively |
| Platform channels to native OpenCV | Very mature underneath | Any | Full | No |

`[VERIFIED: https://pub.dev/packages/opencv_dart, checked 2026-09-12 — "The minimum required dart
sdk version is 3.10 (Flutter 3.38) that supports hooks (Native-Assets)", and the package describes
itself as WIP]`

**Decision:** Start with the pure-Dart **`image`** package and hand-written algorithms. Treat
`opencv_core` as a fallback if a specific step proves intractable.

**Why this wins:** C1 outweighs C3 here, and the capability gap is smaller than it first appears.
Your form is a **fully ruled table** `[VERIFIED: §11 of PRODUCT.md]`, which means the hard parts
are reachable with projection profiles and connected-component labelling — a few hundred lines of
ordinary code, not a computer-vision research problem:

- Line detection → row/column sums of thresholded pixels; ruled lines appear as sharp peaks.
- Cell ink → count dark pixels in a rectangle.
- Mark shape → connected component, then its bounding box, area, aspect ratio and extremes.

Pinning your only-builder-is-an-AI project to a WIP binding that demands a bleeding-edge Flutter
is the kind of dependency risk that is very expensive to discover in week six.

**What we give up:** more code we own and must test, and no access to OpenCV's tuned
`HoughLinesP` or `findContours` if the simple approach struggles on poor scans.

**What would change this:** if the grid-detection spike (Component 3) fails on real pages with
projection profiles, switch to `opencv_core` and accept the toolchain requirement. **This is the
single most likely plan change, which is why Component 3 comes early.**

**Confidence:** Medium. This is the least certain decision in the plan and the spike exists to
resolve it.

---

### DR-003: Row anchoring via the printed code column

**Status:** Proposed | **Date:** 2026-09-12

**Context:** No registration marks; rows vary in height because Hindi text wraps.
`[VERIFIED: §11]`

**Decision:** Use `google_mlkit_text_recognition` in **Latin** mode to read the printed Code
column (`ER_1` … `PC_5`) and use each match's bounding box as that row's vertical anchor.

**Why this wins:** it converts row identification from counting into lookup. If a row is missed,
the rows below don't silently shift — the failure is local and detectable. Codes are *printed*
Latin text, which is exactly what ML Kit is reliable at, and there are 71 known strings to match
against, so a fuzzy match against the expected set corrects most OCR slips.

**What we give up:** a dependency on ML Kit for a step that is otherwise pure geometry, plus
~38 MB for the Latin model.

**What would change this:** if code-column recall falls below ~95% on the sample pages, fall back
to ruled-line row segmentation with a count check against the expected 71.

**Confidence:** Medium-high. Untested on your pages — Component 3 measures it.

---

### DR-004: Mark classification and anchoring

**Status:** Proposed | **Date:** 2026-09-12

**Context:** Ticks overflow rightward while their vertex stays in the intended column; dots do
not overflow but are indistinguishable from specks by shape. `[VERIFIED: §11.3]`

**Decision:** Classify the connected component first, then anchor by type.

| Type | Signature | Anchor |
|---|---|---|
| Tick | Open V, wide aspect, two endpoints above lowest point | **Lowest vertex** |
| Dot | Small area, near-circular, low extent | Centroid |
| Cross | Two strokes intersecting, symmetric | Intersection |
| Circle | Closed contour enclosing area | Enclosed centre |
| Digit | Tall, closed or complex, inside one cell | Recognise glyph; ignore position |

**Why this wins:** a single anchoring rule is provably wrong for most of these shapes. Anchoring
by type is the only approach that can be unbiased across all of them.

**What we give up:** classification can itself be wrong, adding a failure mode. Mitigated by
routing low-confidence classifications straight to the flag queue rather than guessing.

**What would change this:** if real responses show only ticks and dots, collapse to two branches
and simplify.

**Confidence:** Medium. The tick and dot rules rest on direct observation; cross, circle and digit
are anticipated, not observed.

---

### DR-005: Confidence and flagging

**Status:** Proposed | **Date:** 2026-09-12

**Context:** Success rests on flagger recall (§0.2), not raw accuracy.

**Decision:** Every item carries a confidence score. Anything below threshold is written as blank
plus a flag naming the specific reason. Flag when **any** of these hold:

1. No mark found in the row.
2. Marks found in more than one column.
3. Mark type unclassifiable.
4. Anchor point within a margin of a column boundary — the tick-bias case.
5. Ink present but below the intended-mark size floor — the speck case.
6. Row code not matched to an expected item.
7. Dot-mode, with any secondary doubt at all — dots get a stricter threshold than ticks by
   design, because a tick's shape is evidence of intent and a dot's is not.

Thresholds are **tuned against the labelled set**, not chosen by intuition.

**Why this wins:** it makes the safety property explicit and measurable rather than emergent.

**What we give up:** flag rate rises, and review time with it. S4 caps this at 15%; if tuning
can't hold both S1 and S4, that's a real finding and you'll be told rather than shown a tuned-down
flagger.

**What would change this:** if review proves fast in practice, raise flagging further — under your
review-only-flagged policy, a false flag costs a glance and a missed flag costs data.

**Confidence:** High on the approach, unknown on the thresholds until measured.

---

### DR-006: Demographic capture — handwriting recognition

**Status:** **Decided by user 2026-09-12 — recognition, not manual entry** | **Date:** 2026-09-12

**Context:** §0.1 (no student name on the form), §0.3 (mixed stack, no batch metadata),
ONDEVICE-OPTIONS.md §1 (no dependable on-device handwritten Devanagari).

**Proposed:** skip handwriting recognition in v1; type school and class at capture.

**Decided:** **rejected.** School and class are to be read from handwriting. Manual entry is not
the v1 approach.

**What this means, stated once and then accepted:** the four free-text fields go through
on-device recognition in Latin and Devanagari. ML Kit's text recognition is built for printed
text and is weak on handwriting `[VERIFIED: ONDEVICE-OPTIONS.md §1]`, and I have **no measured
accuracy figure** for handwritten Devanagari on your forms. `[UNKNOWN — Component 4 produces the
number; I will not invent one]` If it comes back at 70%, you'll get 70% and the real flag rate,
not a tuned-down flagger.

**How this is built safely without overriding the decision:** recognised fields go through the
same confidence-and-flag path as every parsed value (DR-005). Recognition produces the value; low
confidence produces a flag instead of a guess. That is not a compromise of this decision — it is
the same discipline already agreed for the 71 Likert items, applied consistently.

**Consequences to accept:**

- The **Devanagari ML Kit model returns to the build** — roughly +38 MB on top of Latin.
  `[VERIFIED: ML Kit docs]`
- Component 4 grows: the labelled set now needs ground truth for text fields as well as marks,
  and accuracy must be reported separately for marks and for handwriting. An aggregate number
  would hide poor handwriting performance behind strong mark performance.
- Handwriting accuracy becomes a top-three project risk (§7).

**What would change this:** if Component 4 measures handwriting accuracy low enough that the flag
rate on those four fields approaches "type it anyway", revisit. The decision is reversible at
that point and the measurement is designed to make the call for you.

**Confidence:** High that this is buildable. **Unknown** that it will hit a useful accuracy.

---

### DR-007: Packaging and distribution

**Status:** Proposed, **with one unresolved blocker** | **Date:** 2026-09-12

**Android:** `flutter build apk --release`, self-signed. Anyone can install it. Solved, free.

**iOS:** `flutter build ipa` produces the file on your Mac. **Installing it on other people's
iPhones is the unresolved part.** Apple restricts installing apps outside the App Store, and the
free-Apple-ID path has significant limits — I believe certificates expire after a short period and
the device must be tethered to your Mac, but **I have not verified current Apple terms and I'm not
going to assert them.** `[UNKNOWN — verify at Component 8: free provisioning profile duration,
device limits, and whether re-signing is needed]`

Two known ML Kit build requirements to handle: **iOS deployment target 15.5 or newer**, and
**armv7 must be excluded** in Xcode or `flutter build ipa` fails.
`[VERIFIED: https://pub.dev/packages/google_ml_kit, checked 2026-09-12]`

**What this means for the plan:** Component 1 builds an IPA on day one, before any real work, so
this is either resolved or known early. If free distribution proves impractical, honest options
are Android-only v1, running the app on your own iPhone via Xcode, or accepting the $99/year — and
you'd choose with facts rather than at the end.

**Confidence:** High on Android. **Low on iOS distribution**, and I'd rather say so now.

---

### DR-008: Response identity — app-generated auto-numbering

**Status:** **Decided by user 2026-09-12 — revised from the earlier code-based scheme**
**Date:** 2026-09-12

**Decision:** the app assigns each response a sequential identifier at capture. Every response is
recorded, whether or not Respondent Number and School Code are filled on the paper.

**Why this was chosen:** both fields were blank on the sample `[VERIFIED: page 1 of the sample
PDF]` and their state across the 300 collected is unknown. Auto-numbering works regardless, so it
removes the dependency on paperwork that may not exist. Q19 is closed by making it irrelevant.

**Where codes still get used:** when Respondent Number or School Code *are* present on a form,
they are still read and stored alongside the generated ID — as data, not as the key. Where both a
code and a recognised school name exist, disagreement between them remains a flag signal (DR-006).

**Three consequences this decision creates, each needing a build response:**

**1. Two devices will collide.** You have two users `[Q1]`, no sync `[§14.5]`, and a manual Excel
merge. Two phones each counting from 1 produce two responses numbered 1, 2, 3 — and the merge
silently conflates them. **Mitigation:** identifiers carry a device prefix set at first launch
(e.g. `A-0001`, `B-0001`). Cheap now, unfixable after 300 rows exist.

**2. The paper and the record have no link.** A code printed on the form can always be traced back
to a specific sheet. A number invented by the app cannot — the only mapping is stack order, which
survives exactly until someone reorders the stack. **Mitigation:** the app shows the assigned ID
prominently after capture, and **you write it on the form**. Without that step there is no route
from a flagged row back to the paper it came from, which makes the review workflow in Component 6
much weaker — reviewing a flag usually means looking at the original.

**3. Nothing prevents scanning the same form twice — accepted, not mitigated.** With a printed
code, a duplicate is caught on entry; with auto-numbering, a re-scanned form becomes a second
record. Near-duplicate detection was proposed and **declined by the user 2026-09-12**, who will
ensure each response is uploaded once.

This is a sensible trade rather than a reluctant concession. Duplicate detection by answer-pattern
similarity is inherently unreliable — two students in the same class can legitimately answer 71
Likert items alike, so it would have produced false flags on genuine responses and added review
burden to catch a failure the operator is well placed to prevent. Scope reduced accordingly:
Component 6 does not build it.

**What we give up:** traceability by default and duplicate protection by default. Duplicate
protection now rests entirely on operator discipline. Traceability is bought back by writing the
assigned ID on each form (consequence 2), which still stands and is unaffected by this decision.

**What would change this:** if you check the stack and the printed codes turn out to be filled in,
switching the key to those codes restores traceability and duplicate detection for free. The
generated ID can stay as a secondary column, so the switch stays cheap.

**Confidence:** High. This works unconditionally, which is its main virtue.

## 5. Architecture

```
capture (camera / gallery)
        │
        ▼
  page normalise ──── deskew, grayscale, adaptive threshold
        │
        ├──► ML Kit Latin ──► code column ──► row anchors      [DR-003]
        │
        └──► projection profiles ──► ruled grid ──► cell boxes  [DR-002]
                    │
                    ▼
        per cell: ink → component → classify → anchor → column  [DR-004]
                    │
                    ▼
        confidence scoring ──► value OR flag+reason             [DR-005]
                    │
                    ▼
        response record  ◄── typed metadata (name/school/class) [DR-006]
                    │
                    ▼
        local store (SQLite) ──► review screen ──► Excel writer
```

**Deliberate property: the parser is a pure Dart library with no Flutter dependency.** It takes
image bytes and returns a structured result. That lets it run as a command-line program on your
Mac against the sample pages, which is what makes the measurement loop in Component 4 fast enough
to actually iterate on.

### 5.1 Demographic field specification

**All eight Part A fields are captured. Anything the respondent left unanswered is recorded as
blank.** Confirmed by user 2026-09-12. See the blank-reason rule in §5.2 — it changes nothing in
the columns you analyse, it just keeps the *reason* for a blank in a separate notes column so a
non-response stays distinguishable from a parse failure.

| # | Field | Type | Options | Method | Confirmed by user |
|---|---|---|---|---|---|
| 1 | School name | Handwritten text | free | Recognition (DR-006), cross-checked against School Code where present | Yes |
| 2 | District / Block | Handwritten text | free | Recognition (DR-006) | Yes |
| 3 | Class / Grade of child | Handwritten text | free, short | Recognition (DR-006) | Yes |
| 4 | School attendance | Checkbox | 4 | Mark detection + EN/HI reconcile | Yes (confirmed 2026-09-12) |
| 5 | Gender | Checkbox | 3 | Mark detection + EN/HI reconcile | Yes |
| 6 | Annual family income | Checkbox | 4 | Mark detection + EN/HI reconcile | Yes |
| 7 | Extracurricular involvement | Checkbox | Yes/No | Mark detection + EN/HI reconcile | Yes |
| 8 | Home digital device / internet access | Checkbox | Yes/No | Mark detection + EN/HI reconcile | Yes |

**EN/HI reconciliation for fields 4–8.** English and Hindi are duplicate parallel columns, and the
sample respondent ticked **both sides** for attendance, gender and digital access.
`[VERIFIED: §11.4 of PRODUCT.md]` Rules:

- Both sides agree → high confidence, record the value.
- One side only → record it, normal confidence.
- **Sides disagree → flag.** Two independent marks contradicting each other is the strongest
  uncertainty signal available on this form, and it comes free from the layout.
- Neither side marked → blank, reason `unanswered`.

### 5.2 The blank-reason rule

"Leave it blank if not filled" is right, but two very different things produce a blank cell and
they must not be conflated:

| Reason | Meaning | Excel cell | Notes column |
|---|---|---|---|
| `unanswered` | Respondent left it empty | blank | `unanswered` |
| `unreadable` | Parser couldn't determine the value | blank, highlighted | `unreadable: <specific reason>` |
| `conflict` | EN and HI sides disagree | blank, highlighted | `conflict: EN=x HI=y` |

This distinction is not bookkeeping. In your sample, family income and extracurricular involvement
were **genuinely unanswered** by the student. `[VERIFIED: §11.5]` If the app writes the same empty
cell for "the student skipped this" and "the parser failed here", you lose the ability to tell a
real non-response rate — a legitimate research finding — from a software defect. One is data; the
other is a bug. They must be separable in the output.

**Excel layout**, given you analyse in Excel itself (Q5). One row per respondent, columns in order:

1. `response_id` (device-prefixed, e.g. `A-0001`), `device_id`, `captured_at`
2. `respondent_number`, `school_code` — stored when present on the form, blank otherwise
3. The eight demographic fields from §5.1
4. `ER_1` … `PC_5` — all 71 item values
5. Twelve construct-mean columns (ER, RE, EO, EM, DI, TC, DP, DS, PS, AS, IR, PC) as **live Excel
   formulas**, so they recalculate if you correct a value by hand
6. `flag_count`, `notes` — per-row summary and the blank-reason detail from §5.2

Flagged cells are blank and highlighted. Pivot-ready as-is.

**Two users, no sync** `[Q1, §14.5]`: each phone holds its own database and its own workbook.
Merging is a manual step — the workbook carries a device tag so rows can be concatenated without
collision. Real sync needs a server, which the no-cloud decision rules out.

---

## 6. Component build order

Ordered by risk retired, not by layer.

| # | Component | Why here | Done when | Status |
|---|---|---|---|---|
| 1 | Walking skeleton | Toolchain and the iOS unknown (DR-007) surface on day one, not week six | Blank Flutter app builds, runs on a real Android phone from clean checkout; `flutter build ipa` succeeds on your Mac; DR-007's unknown answered in writing | Not started |
| 2 | docx → questionnaire model → Excel template | Deterministic, no images, fully verifiable against your real file; unblocks everything downstream | Parses `Student_Survey_Bilingual.docx` to exactly 71 items with correct codes and both languages; emits an Excel that opens in Excel with working construct formulas | Not started |
| 3 | **Grid + row anchoring spike** | **The riskiest thing in the project.** Resolves DR-002 and DR-003 while the plan is still cheap to change | Runs as a plain Dart CLI over all 6 sample pages; reports code-column recall and cell-boundary accuracy with a rendered overlay to eyeball | Not started |
| 4 | Mark detection + **handwriting recognition** + labelled measurement harness | Where S1–S3 are proven or disproven, and where DR-006's real accuracy surfaces | Hand-labelled ground truth for all 71×6 cells **and the four text fields**; harness reports accuracy, flagger recall and signed bias **separately for marks and for handwriting**; S1–S3 met or a written explanation of why not | Not started |
| 5 | Capture flow | First user-facing piece; safe now that parsing is understood | Camera and gallery both work; 6 pages assembled into one response; add-one-at-a-time with explicit done | Not started |
| 6 | Identity + review screen | Implements DR-008 and makes flags actionable | Device-prefixed auto-ID assigned and displayed for writing on the form; printed codes stored when present; code-vs-handwriting cross-check flags disagreement; flagged items listed with the page image cropped to the row; correction writes through | Not started |
| 7 | Store + Excel writer + merge | Turns parsed data into the thing you actually use | 300 responses round-trip; workbook opens in Excel; two device files concatenate without collision | Not started |
| 8 | Packaging | Ship | Signed release APK installs on a non-developer Android phone; IPA built; distribution reality documented | Not started |

**Component 3 is the gate.** If projection profiles can't find the grid reliably on real scans,
DR-002 flips to `opencv_core` and the toolchain requirement changes. Better to learn that in
week one.

**Component 4 is the honest one.** It's where we find out whether 99% is reachable on your actual
handwriting. If it isn't, you'll get the real number and the real flag rate, not a tuned-down
flagger that looks good.

---

## 7. Risks

| Risk | Likelihood | Impact | Early signal | Mitigation |
|---|---|---|---|---|
| Grid detection unreliable on real scans | Medium | High — reshapes the stack | Component 3 overlay looks wrong | `opencv_core` fallback, accepted in DR-002 |
| 99% unreachable on real handwriting | Medium | High — changes what the product is | Component 4 numbers | Report honestly; raise flag rate; revisit S2 with you |
| iOS distribution impractical for free | **Medium-high** | Medium — Android-only v1 | Component 1 | Documented in DR-007; decided with facts |
| Flag rate so high review costs more than typing | Medium | High — product loses its point | Component 4 | S4 caps it; if S1 and S4 conflict you're told |
| Two-device data diverges | Medium | Medium | First merge attempt | Device tag; manual concatenation; documented as a known limit |
| **Handwritten Devanagari accuracy too low to be useful** | **Medium-high** | **High — four fields per response unreliable** | Component 4 numbers | Same flag/review path as marks; DR-006 reversible on measurement |
| Duplicate scans inflate the dataset | Low | High — phantom respondents in research data | None in software | **Accepted risk.** Operator ensures one upload per response (user decision 2026-09-12) |
| Device ID collision on merge | High if unhandled | High — silent row conflation | First merge | Device prefix from first launch (DR-008) |
| Paper-to-record traceability lost | Medium | Medium — weakens flag review | Component 6 | Write assigned ID on the form at capture |
| Photo quality varies by phone and lighting | Medium | Medium | Component 5 | Capture guidance overlay; reject and re-shoot on blur |
| App size from two ML Kit models | High | Low | Component 1 | Both Latin and Devanagari required by DR-006; ~76 MB of models |

The top two rows are the ones to watch. Both resolve early — one at Component 4, one as soon as
you've looked through the stack.

---

## 8. Out of scope for v1

- Analysis or insights inside the app — you analyse in Excel `[Q5, N5]`
- In-app questionnaire authoring — `.docx` only `[§14.3]`
- Handwriting recognition for demographics — DR-006, revisitable as autofill
- Cloud sync or multi-device merge automation `[§14.5]`
- Form redesign: registration marks, QR, wider columns `[§14.7, PRODUCT.md §17]`
- Languages beyond Hindi and English `[Q6 open]`
- App store distribution `[Q7]`

---

## 9. What I'm least sure about

Per the skill, stated plainly.

**Top three uncertainties:**

1. **Whether projection profiles beat OpenCV for grid detection on your real scans.** Resolved by
   Component 3. It's why Component 3 is third and not tenth.
2. **Whether 99% is achievable at a tolerable flag rate.** Resolved by Component 4. I have no
   basis to predict this and won't pretend otherwise — one filled response is not a sample.
3. **Whether an IPA can be shared freely with another person's iPhone.** Resolved by Component 1.
   Flagged `[UNKNOWN]` in DR-007 rather than guessed.

**The decision I'm least confident about: DR-002**, the image-processing library. I've chosen
lower dependency risk over more capability, on the reasoning that a broken WIP binding is worse
for a solo non-developer than writing a few hundred lines of well-understood code. A professional
CV engineer might reasonably pick the opposite. Component 3 is designed to prove me wrong cheaply
if I am.

---

## 10. Approval needed

**Resolved 2026-09-12:**

- DR-006 — handwriting recognition, not manual entry.
- DR-008 — app-generated auto-numbering; all responses recorded.
- Q19 — closed. Auto-numbering works whether or not the printed codes exist.

- Q20 — closed. All eight demographic fields captured, including school attendance.
  Unanswered items recorded blank.

**No open questions remain.** The plan is complete and ready to build.

---

## 11. One process step this plan depends on

Not a question — a habit the design now assumes.

**Write the assigned ID on each paper form as you scan it.** DR-008 consequence 2. The app will
display it. Thirty seconds a stack, and it is the only thing that will let you get from a flagged
row in Excel back to the sheet of paper it came from. Skip it and Component 6's review screen can
show you *that* something is uncertain but never let you check *what was actually written*.

If that habit isn't practical for the 300 already collected, say so — the review screen can lean
harder on stored page crops instead, which is weaker but workable.

## 12. Changelog

| Date | Change |
|---|---|
| 2026-09-12 | Plan created. DR-001..007 proposed. Q18 raised. Contradiction in §0.1 surfaced. |
| 2026-09-12 | DR-006 rejected by user — handwriting recognition retained. Devanagari model back in scope; handwriting accuracy added as a top risk; Component 4 scope expanded to measure it separately. |
| 2026-09-12 | Q18 answered — DR-008 added: identity via Respondent Number + School Code. Cross-check against recognised school name adopted as a flag signal. Q19 raised: backlog may lack these codes. |
| 2026-09-12 | DR-008 **revised** — user chose app-generated auto-numbering, all responses recorded. Q19 closed as no longer relevant. Three new build requirements added: device-prefixed IDs, ID written on paper, near-duplicate detection. Component 6 and risk table updated. |
| 2026-09-12 | Q20 answered — school attendance included. All eight Part A fields captured; unanswered recorded blank. No open questions remain. |
| 2026-09-12 | Demographic capture specified (§5.1) — all eight Part A fields, EN/HI reconciliation rules, blank-reason taxonomy (§5.2). Excel column order fixed. Q20 raised on school attendance. |
| 2026-09-12 | Near-duplicate detection **dropped** at user's decision — duplicates prevented by operator discipline instead. Component 6 scope reduced; risk reclassified as accepted. Device prefix and write-ID-on-paper both retained, being separate concerns. |
