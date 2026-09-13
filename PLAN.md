# Research Questionnaire Capture App — Build Plan

Last updated: 2026-09-13 | Current stage: **2** | Two tracks active — see DR-009.

- **Mobile track (paused):** Component 1 (walking skeleton) — partially done, blocked on hardware/host access; see status below.
- **Web track (active):** stopgap so the app can be tested without mobile hardware. **WT-1 and WT-2 are Done** — live at https://shruti9805.github.io/research-app/. Current component: **WT-3 (grid + row anchoring spike)**.

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

**Status:** Paused — see DR-009 (2026-09-13) | **Date:** 2026-09-12

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

**Why this wins:** C2 and C5 decide it. `google_mlkit_text_recognition` explicitly supports
Devanagari alongside Latin. No React Native equivalent has that combination of maintenance and
reach. **Version re-verified 2026-09-12 at Component 1:** `flutter pub add` resolved
**0.17.1** (was 0.15.1 when this decision was first written the same day — pub.dev had already
moved on). Per the evidence rules, version numbers aren't stable; the installed
`TextRecognizer`/`TextRecognitionScript` API in 0.17.1 was read directly from
`~/.pub-cache/hosted/pub.dev/google_mlkit_text_recognition-0.17.1/lib/src/text_recognizer.dart`
and matches `lib_main.dart`'s usage exactly, including the `devanagiri` (not "devanagari") enum
spelling — that's the package's own spelling, not a typo in the draft.

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

**Status:** Paused — see DR-009 (2026-09-13) | **Date:** 2026-09-12

**Android:** `flutter build apk --release`, self-signed. Anyone can install it. Solved, free.

**iOS:** `flutter build ipa` produces the file on your Mac. **Installing it on other people's
iPhones is the unresolved part.**

**Resolved 2026-09-12 — no, not durably, without the paid program.** Verified directly against
Apple's own developer documentation:

- A free Apple Account lets you install and run your app on a device via Xcode, full stop —
  Apple's own FAQ: *"Do I need to enroll in the Apple Developer Program to install apps on a
  device? No. You can install apps on your personal device with Xcode. You'll only need to enroll
  if you'd like to distribute apps..."* `[VERIFIED: https://developer.apple.com/support/enrollment/,
  checked 2026-09-12]` — the free path is scoped to *your own* device connected to *your own* Mac
  during signing, not handing someone else a file to install on their phone.
- Free ("Personal Team") signing registers **up to 3 devices**, and *"Provisioning profiles that
  enable apps to be installed on a device will expire 7 days from issuance. You'll need to rebuild
  and reinstall your app to your device after expiration."*
  `[VERIFIED: https://developer.apple.com/support/compare-memberships/, checked 2026-09-12]`
- Distributing a built IPA so **another person installs it on their own iPhone** — ad hoc
  distribution — is exactly the capability gated behind enrollment. The paid **Apple Developer
  Program ($99/year)** raises the device cap to up to 100 registered devices and the signing
  certificate is valid about a year rather than 7 days. `[VERIFIED: same two sources above +
  cross-checked against secondary summaries, 2026-09-12]`

**Practical answer for this project:** with the free path, the *other person's* iPhone (the second
user in `[Q1]`) would need to be physically connected to your Mac and re-signed through Xcode every
7 days — not workable for someone in the field. Ad hoc distribution to their phone as an
independently installable IPA requires the $99/year Apple Developer Program. Given the zero-budget
constraint `[Q7]`, the realistic v1 options are: (a) pay the $99/year, (b) run the app on the
second user's iPhone by tethering it to your Mac and re-signing weekly, or (c) Android-only for the
second user. **This needs your decision before Component 8 (packaging)** — flagging now since it
was flagged as a risk in §7, not deciding it for you.

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

---

### DR-009: Web stopgap track

**Status:** Decided by user 2026-09-13 | **Date:** 2026-09-13

**Context:** Component 1 is blocked on Mac/Xcode/Android-SDK access the user doesn't currently
have. The user asked for a web app usable on any device so work can be tested now.

**Decision:** Build a **parallel, stopgap web track**, not a replacement. The Flutter/mobile
plan (DR-001..DR-008) stays the eventual target and is **paused**, not deleted — see the status
lines on DR-001 and DR-007. The web track is built in **plain TypeScript** (Vite + React + TS),
not Flutter Web, and deployed to a **free static host** (GitHub Pages or Netlify).

**Why not Flutter Web:** Google's ML Kit — load-bearing for DR-003 (row anchoring) and DR-006
(handwriting) — has no web build at all. `[VERIFIED: pub.dev/GitHub — "Google's ML Kit was built
only for mobile platforms... Web or any other platform is not supported"]` Flutter Web would
still need a from-scratch OCR replacement wired in through JS interop, so it keeps Flutter's
learning curve while giving up ML Kit, the thing DR-001 chose Flutter *for*. Going straight to
TypeScript gets the same OCR substitution with a more mature ecosystem around it (OCR, canvas
image processing, Excel writing), at the cost of eventually re-implementing the parser twice —
once in TS now, once in Dart if/when the mobile track resumes. That cost is accepted knowingly,
not overlooked.

**Library substitutions** — each mobile-track dependency that was ML-Kit- or Flutter-specific
gets a web equivalent:

| Concern | Mobile track (paused) | Web track (new) | Verification |
|---|---|---|---|
| Printed-text OCR (DR-003) + handwriting (DR-006) | `google_mlkit_text_recognition` 0.17.1 | **Tesseract.js** v7.0.0, WASM, fully client-side | `[VERIFIED: npm — current version, WASM core, no server call]` |
| Image processing (DR-002) | Pure-Dart `image` package, hand-written algorithms | Hand-written TS over Canvas `ImageData`, same projection-profile / connected-component approach | `[INFERRED: same reasoning as DR-002 — the form is fully ruled, so it doesn't need a CV library]` |
| Image processing fallback | `opencv_core` if Component 3 fails | **OpenCV.js** (official WASM build) if WT-3 fails | `[UNKNOWN — maturity not yet verified; check only if the hand-written approach fails, same trigger condition as DR-002]` |
| .docx parsing (Component 2) | Not yet built | **mammoth.js** (`.convertToHtml` / `.extractRawText`) for table structure | `[VERIFIED: npm/GitHub — supports tables in docx-to-HTML conversion]` |
| Excel writing | Not yet chosen | **ExcelJS** — writes formulas (construct means) and cell fill styling (flagged-cell highlighting), free | `[VERIFIED: npm — read/write + formulas + styling, no server]`. SheetJS considered; its free tier has weaker styling support, needed for flagged cells. |
| Local storage (SQLite equivalent) | Not yet chosen | **IndexedDB**, via a thin wrapper (e.g. Dexie.js) | `[INFERRED: standard browser persistence choice]` |
| Camera capture | Not yet built | **Two separate inputs**, per Q13's "camera or gallery, both options" requirement: (a) a file input with the `capture` attribute, opens the camera app directly on both iOS Safari and Android Chrome; (b) a plain file input with no `capture` attribute, opens the normal photo/file picker on both platforms | `[VERIFIED: MDN + web.dev — capture attribute works on iOS and Android to launch the camera; caniuse reports ~97% mobile coverage; ignored on desktop, where both inputs just open a file picker]` |
| Distribution | APK/IPA (DR-007, paused) | Static deploy to GitHub Pages or Netlify free tier | `[VERIFIED: both have zero-cost static-hosting tiers]` |

**Deployment mechanism, decided:** **GitHub Pages**, not Netlify — the repo already exists at
`github.com/shruti9805/research-app` `[VERIFIED: git remote -v]`, so Pages needs no new account
or third-party service, just a setting on the existing repo. A GitHub Actions workflow
(`actions/upload-pages-artifact` + `actions/deploy-pages`) builds the Vite app and deploys `dist/`
automatically on every push to the branch it's configured for. `[VERIFIED: current GitHub Actions
docs/examples]` The site will be reachable at `https://shruti9805.github.io/research-app/` — this
requires setting Vite's `base` config and `homepage` to that subpath, not root, since it's a
project site rather than a `<username>.github.io` repo. Built at WT-1 (first bare-bones deploy,
to prove the pipeline) and finalized at WT-8.

**Camera-capture caveats, verified while researching the row above:**
- On Android, the camera-preference hint (`capture="environment"` for back camera specifically)
  is not reliably honored — only the bare `capture` attribute reliably opens *a* camera app.
  `[VERIFIED: MDN browser-compat-data issue]` Not a blocker, but the plan shouldn't claim a
  guaranteed rear-camera default.
- There is a documented Android 14/15 + Chrome regression where the camera option can disappear
  from a file input depending on the exact `accept` value used, with a known workaround.
  `[VERIFIED]` Exactly the kind of platform behavior CLAUDE.md says to check, not recall — **WT-5
  must verify capture on a real, current Android device**, not assume the baseline holds.
- iOS Safari requires the input to be triggered by a direct, synchronous user gesture (tap →
  immediate `.click()` on the input, no `await` in between) or the camera won't open.
  `[VERIFIED: Apple developer forums + web.dev]`

**DR-006 stands, with a heightened risk named plainly.** The user chose to keep handwriting
recognition for school/district/class rather than fall back to batch metadata. Tesseract.js is
reported weaker than ML Kit specifically at handwriting and at Devanagari conjuncts.
`[VERIFIED: search results — "Hindi language recognition accuracy is quite low even for the
printed text... conjunct character combinations... not easily separable"]` WT-4 measures the
real number, same honest-measurement discipline as mobile Component 4 — no invented figures, no
tuning the flagger to hide a bad number.

**§14.5 reinterpreted, not redefined.** "Fully on-device, no network calls" was written for a
phone with local storage. A static-hosted web app has no "device" of its own — the host only
serves app code. Restated for this context: **no respondent data (photos, OCR output, Excel)
ever leaves the browser it was captured in.** The static host never receives or touches that
data. This is the same privacy property, stated in the vocabulary that applies to a browser.

**A property to preserve, and a new risk to name honestly.** CLAUDE.md requires the parser to be
testable outside the UI. In Dart this meant a plain CLI with no Flutter dependency. In TS, the
docx-model and confidence/flagging logic can stay pure and unit-testable the same way (e.g. with
Vitest, no browser). But grid detection and OCR are Canvas/WASM-dependent and **cannot run in
plain Node without a headless-browser or a `node-canvas` shim** — a real difference from the Dart
CLI story. WT-1 verifies which testing approach actually works before WT-3 depends on it.

**What we give up:** a second implementation of the same parsing logic to maintain if the mobile
track resumes, and a browser environment that's harder to unit-test than a plain Dart CLI.

**What would change this:** if the mobile track becomes testable again (Mac/Xcode access
restored) and the web track's numbers (WT-3, WT-4) come back materially worse than what ML Kit
would likely give, that's a reason to deprioritize the web track back to "reference only" rather
than keep maintaining two parsers.

**Confidence:** High on the substitutions being workable in principle (all are shipped, verified
libraries). Unknown on Tesseract.js's real accuracy on Devanagari handwriting — same posture as
DR-006 always had, just with a different library underneath.

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
| 1 | Walking skeleton | Toolchain and the iOS unknown (DR-007) surface on day one, not week six | Blank Flutter app builds, runs on a real Android phone from clean checkout; `flutter build ipa` succeeds on your Mac; DR-007's unknown answered in writing | **Partially done — see note below** |
| 2 | docx → questionnaire model → Excel template | Deterministic, no images, fully verifiable against your real file; unblocks everything downstream | Parses `Student_Survey_Bilingual.docx` to exactly 71 items with correct codes and both languages; emits an Excel that opens in Excel with working construct formulas | Not started |
| 3 | **Grid + row anchoring spike** | **The riskiest thing in the project.** Resolves DR-002 and DR-003 while the plan is still cheap to change | Runs as a plain Dart CLI over all 6 sample pages; reports code-column recall and cell-boundary accuracy with a rendered overlay to eyeball | Not started |
| 4 | Mark detection + **handwriting recognition** + labelled measurement harness | Where S1–S3 are proven or disproven, and where DR-006's real accuracy surfaces | Hand-labelled ground truth for all 71×6 cells **and the four text fields**; harness reports accuracy, flagger recall and signed bias **separately for marks and for handwriting**; S1–S3 met or a written explanation of why not | Not started |
| 5 | Capture flow | First user-facing piece; safe now that parsing is understood | Camera and gallery both work; 6 pages assembled into one response; add-one-at-a-time with explicit done | Not started |
| 6 | Identity + review screen | Implements DR-008 and makes flags actionable | Device-prefixed auto-ID assigned and displayed for writing on the form; printed codes stored when present; code-vs-handwriting cross-check flags disagreement; flagged items listed with the page image cropped to the row; correction writes through | Not started |
| 7 | Store + Excel writer + merge | Turns parsed data into the thing you actually use | 300 responses round-trip; workbook opens in Excel; two device files concatenate without collision | Not started |
| 8 | Packaging | Ship | Signed release APK installs on a non-developer Android phone; IPA built; distribution reality documented | Not started |

**Component 1 status note (2026-09-12).** Built and verified in a cloud Linux sandbox, which is not
the `Mac with Xcode` build machine assumed in §2. That environment has no Android SDK and cannot
run Xcode at all (Apple's toolchain requires macOS). This is an execution-environment fact, not a
code defect:

| Done-when item | Result |
|---|---|
| Scaffold builds, deps resolve | ✅ Verified — `flutter create` + `flutter pub add` succeeded |
| `flutter analyze` clean | ✅ Verified — real output, see session log |
| `flutter build apk --release` | ❌ **Not achievable in this sandbox** — fails with "No Android SDK found." The Android SDK can only be fetched from `dl.google.com`, which this session's network egress policy blocks (confirmed via the proxy status endpoint, not a config issue). `flutter analyze`/`pub get` don't need it; `build apk` does. |
| APK installs on a real Android device, 4 health checks pass on screen | ❌ Not attempted — no device attached to this sandbox, and no APK was produced to install |
| `flutter build ipa` | ❌ **Not achievable in this sandbox, or in any Linux environment** — Apple's iOS build toolchain (Xcode) only runs on macOS |
| DR-007 answered in writing | ✅ Done — see DR-007 above, verified against Apple's own docs |
| PLAN.md updated, work committed | ✅ This edit |

**What this means:** the code is ready, but the last two build/install verifications require your
Mac.

**Handoff — run this on your Mac to finish Component 1:**

```bash
git pull                      # get this commit
cd app
flutter doctor -v              # confirm Android SDK + Xcode are both found
flutter build apk --release    # -> build/app/outputs/flutter-apk/app-release.apk
# install app-release.apk on a real Android phone (adb install, or copy + open the file)
# and confirm all four health checks show green on screen.

# In Xcode: open ios/Runner.xcworkspace, set
#   Runner > Build Settings > Excluded Architectures > Any iOS SDK -> armv7
# then:
flutter build ipa              # -> build/ios/ipa/
```

Come back and tell me the results (paste the real output) — if all six Done-when items pass, I'll
mark Component 1 Done and we move to Component 2. If anything fails on your Mac, paste the error
and I'll fix it before we proceed.

**Component 3 is the gate.** If projection profiles can't find the grid reliably on real scans,
DR-002 flips to `opencv_core` and the toolchain requirement changes. Better to learn that in
week one.

**Component 4 is the honest one.** It's where we find out whether 99% is reachable on your actual
handwriting. If it isn't, you'll get the real number and the real flag rate, not a tuned-down
flagger that looks good.

---

## 6.1 Web track (WT) component build order — DR-009

Parallel, stopgap track. Same risk-first ordering as §6, same one-component-at-a-time discipline.
Runs in a browser, so every component here is testable on the Mac immediately — no SDK, no
Xcode, no device.

| # | Component | Why here | Done when | Status |
|---|---|---|---|---|
| WT-1 | Web walking skeleton | Proves the toolchain and hosting before any real work | Vite+React+TS scaffold deploys to a free static host; Tesseract.js loads and recognizes a trivial string in-browser; IndexedDB read/write works; ExcelJS produces a downloadable `.xlsx` that opens correctly — all four verified with real output on the Mac | **Done — 2026-09-13. Live at https://shruti9805.github.io/research-app/** |
| WT-2 | docx → questionnaire model → Excel template | Same reasoning as mobile Component 2 | Parses `Student_Survey_Bilingual.docx` to exactly 71 items with correct codes and both languages via mammoth.js; emits an Excel with working construct formulas | **Done — 2026-09-13** |
| WT-3 | Grid + row anchoring spike | The riskiest thing in the web track, same as mobile Component 3 | Runs against all 6 sample pages in-browser; reports code-column recall and cell-boundary accuracy with a rendered overlay | Not started |
| WT-4 | Mark detection + handwriting recognition + labelled measurement harness | Where DR-006's real web-track accuracy surfaces | Same Definition of Done as mobile Component 4 — accuracy and flagger recall reported separately for marks/handwriting and ticks/dots; real Tesseract.js Devanagari number, not assumed | Not started |
| WT-5 | Capture flow | First user-facing piece | File-input camera capture and gallery pick both work, tested on a phone browser and a desktop browser | Not started |
| WT-6 | Identity + review screen | Implements DR-008 in the browser | Browser-prefixed auto-ID assigned and displayed; flagged items listed with the page image cropped to the row; correction writes through | Not started |
| WT-7 | Store + Excel writer + merge | Turns parsed data into the thing actually used | IndexedDB persistence round-trips; ExcelJS export opens in Excel; multiple browsers'/devices' exports concatenate without collision, same device-tag approach as §5.2 | Not started |
| WT-8 | Deploy | Ship | Static site live on GitHub Pages or Netlify; confirmed reachable and functional from a phone browser and a desktop browser, not just the Mac | Not started |

**WT-1 is the immediate priority** — it directly answers "I can't test mobile app currently,"
verifiable with `npm run dev` and a browser tab, no native toolchain.

**WT-2 status note (2026-09-13).** Built and verified against the real `samples/Student_Survey_Bilingual.docx`, not a synthetic fixture:

| Done-when item | Result |
|---|---|
| Parses to exactly 71 items with correct codes | ✅ Verified — inspected the real mammoth-converted HTML directly first (2 tables: an 8-row demographics table, a 72-row items table with header), confirmed the exact construct breakdown matches PRODUCT.md §11.1 (`ER:6 RE:6 EO:7 EM:6 DI:6 TC:6 DP:6 DS:6 PS:7 AS:5 IR:5 PC:5`, sum 71, zero duplicate codes) *before* writing the parser, then wrote `parseQuestionnaireDocx` (`web/src/lib/questionnaire.ts`) to match that verified shape and throw rather than guess if a future docx doesn't match it (wrong construct count, duplicate code, missing line break between English/Hindi). |
| Both languages captured correctly | ✅ Verified — English/Hindi split on the single `<br>` mammoth emits per item (confirmed present in all 71 rows, zero exceptions, before relying on it); spot-checked against the real ER_1 text in a test. |
| Emits an Excel with working construct formulas | ✅ Verified three ways: a Vitest unit test on a small hand-built questionnaire (checks the formula string references the exact right column range), a real run against the actual 71-item file (`ER_mean` → `AVERAGE(A2:F2)`, `PC_mean` → `AVERAGE(BO2:BS2)`, both correct for 6- and 5-item constructs), and a real browser upload + download via Playwright producing a valid 83-column `.xlsx` (`file` confirms "Microsoft Excel 2007+"). |
| Testable outside the UI | ✅ Mostly holds — parsing logic itself is pure, but needs a DOM (`DOMParser`) to walk mammoth's HTML output, so tests run under Vitest's `jsdom` environment rather than plain Node (unlike WT-1's OCR/Excel checks). A real, separate finding surfaced getting this working: see below. |
| Verified in an actual browser | ✅ Added a small UI section (upload docx → parse → download template) to the WT-1 health-check page; drove it with Playwright uploading the real questionnaire file — parsed 71/12 correctly, downloaded a valid `.xlsx`, zero console errors. |
| Deployed and verified live | ✅ Pushed, workflow ran automatically (push already touched `web/**`, no workflow-file changes needed this time — no PAT issue). Re-ran the same Playwright upload against `https://shruti9805.github.io/research-app/` in production: identical result — 71 items, 12 correct constructs, valid downloaded `.xlsx`, zero console errors. |

**Real finding: jsdom 30 doesn't run on this Mac.** Adding jsdom for DOM-dependent tests hit the exact same pattern as Vite 8 in WT-1 — a just-released major version (jsdom 30) requires Node `^22.22.2 || ^24.15.0 || >=26.0.0`, and its dependency chain (`html-encoding-sniffer` → `@exodus/bytes`, an ESM-only package required via CommonJS) breaks outright on this Mac's Node 20.18.0 with `ERR_REQUIRE_ESM`. Pinned to **jsdom 26.1.0** instead (`node: ">=18"`), same DR-002-style reasoning as before: prefer the version that actually runs over the newest one. **This is now the second time a brand-new major version has broken on this machine's Node** — worth upgrading Node itself at some point rather than continuing to pin around it version by version.

**WT-1 status note (2026-09-13).** Built and verified locally; not yet deployed (pending your
go-ahead to commit/push, since that's a shared, visible action):

| Done-when item | Result |
|---|---|
| Vite+React+TS scaffold builds | ✅ Verified — `npm run build` succeeds. **Real finding:** the scaffold's default `npm create vite@latest` pulled **Vite 8.3.0**, whose new default bundler (Rolldown, a Rust/WASM replacement for Rollup) failed to load its native binding on this Mac (`Cannot find native binding` — a known npm optional-dependency bug). Pinned to **Vite 7.3.6** instead (classic Rollup/esbuild pipeline, no native-binding risk) — same reasoning as DR-002's stance on WIP tooling. TypeScript pinned to `^7.0.2` (current stable; the scaffold's default `~5.7.2` guess in DR-009 was wrong — TypeScript's own version numbering has moved to major version 7). |
| Tesseract.js loads and recognizes text | ✅ Verified two ways: (1) under plain Node/Vitest, against a real fixture image (`src/fixtures/eng_bw.png`, Tesseract.js's own public OCR test image) — read the printed text at 92% confidence with zero browser involved; (2) in a real headless-Chromium browser (Playwright), OCR against a canvas-drawn "RESEARCH APP" string — read correctly at 96% confidence. **Real finding:** Tesseract.js downloads its ~5 MB language-data file (`eng.traineddata`) to the working directory at runtime by default — added to `.gitignore`; production will need an explicit `langPath`/cache strategy, not the default. |
| IndexedDB read/write works | ✅ Verified in the real browser — round-tripped a record via `idb`. Browser-only by nature; not unit-tested under Node. |
| ExcelJS produces a working `.xlsx` | ✅ Verified three ways: Node round-trip test (formula + cell fill both survive a re-read), `file`/`unzip` confirm a real OOXML archive, and an actual browser-triggered download (via Playwright) produces the same valid file. |
| **Testability property (the open question DR-009 flagged)** | ✅ **Resolved, better than expected.** Tesseract.js and ExcelJS both run under plain Node/Vitest with no headless-browser shim and no `node-canvas` — stronger than the Dart CLI story mobile had. The caveat still stands for WT-3's own hand-written Canvas grid-detection code, which does need a DOM `<canvas>` (browser or a jsdom+canvas shim) — that's a separate, still-open question for WT-3. |
| UI renders correctly | ✅ Verified via a real Playwright screenshot, not just build success — caught and fixed one real bug in the process: `index.css`'s inherited `line-height` (computed from the 18px root font) made the 56px `<h1>` overlap itself. Fixed by setting an explicit `line-height` on `h1`. |
| Deployed to a free static host | ✅ **Done.** Live at `https://shruti9805.github.io/research-app/`, verified with a real Playwright run against the production URL — same three checks pass (OCR 96% confidence, IndexedDB round-trip, valid `.xlsx`), zero console errors. |

**Deployment saga, recorded because it was a real, non-obvious obstacle:** the app code pushed
cleanly, but GitHub rejected any push touching `.github/workflows/*` from a PAT lacking the right
scope — twice, with two different token configurations, before landing on the actual cause:
fine-grained PATs need **both** `Contents: Read and write` **and** `Workflows: Read and write`
permissions to push a workflow-file change; having only one is not enough. `[VERIFIED:
github.com/orgs/community/discussions/26254]` Worked around by committing the workflow file
**separately from** the app code (so the app-code push never touched that path and succeeded with
the existing credential), then adding the workflow file itself through GitHub's web UI, which
isn't subject to PAT scope restrictions at all.

Separately, the first deploy run failed with `Failed to create deployment ... Ensure GitHub Pages
has been enabled` even after the workflow ran successfully — a known first-time race where the
workflow can run before **Settings → Pages → Source: GitHub Actions** has actually registered.
Re-running the same (already-green) workflow run, after confirming that setting, succeeded. Worth
knowing if WT-8's final deploy hits the same thing.

**What this means:** WT-1 is fully **Done** — built, verified locally (Node + real browser), and
verified in production (real browser against the live URL), all with real command output at every
step. WT-2 (docx → questionnaire model → Excel template) is next.

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
| **Web OCR (Tesseract.js) weaker than ML Kit on Devanagari handwriting** | **Medium-high** | **High — same four fields at greater risk than on mobile** | WT-4 numbers | Same flag/review path as mobile; DR-009 reversible on measurement, same as DR-006 |
| Parser logic must eventually be re-implemented in Dart if the mobile track resumes | High if mobile resumes | Medium — maintenance cost, not a correctness risk | N/A — known at decision time | Accepted in DR-009 as the cost of testing now instead of waiting |

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
| 2026-09-12 | **Component 1 built and partially verified.** Flutter 3.47.4 scaffold created, dependencies added, `lib_main.dart` copied in and verified correct against installed package source (no changes needed — DR-003/DR-006 ML Kit usage matches the real 0.17.1 API). Fixed a real bug in `setup.sh`: its iOS deployment-target step targeted `ios/Podfile`, which current `flutter create` no longer generates at scaffold time, so the step silently no-op'd; rewritten to set `IPHONEOS_DEPLOYMENT_TARGET` directly in `project.pbxproj`. Replaced the stale default `test/widget_test.dart` (referenced the template's `MyApp`/counter, not `CaptureApp`). `flutter analyze` and `flutter test` both pass clean. DR-007 answered and cited. **Not verified:** `flutter build apk --release` (fails — no Android SDK; this session's network policy blocks `dl.google.com`, the only source for it) and `flutter build ipa` (impossible on any Linux host — requires Xcode/macOS). Both require your Mac; see the handoff note. Component 1 is not marked Done. |
| 2026-09-13 | **WT-2 built and verified against the real questionnaire file.** Inspected the real mammoth-converted HTML first (not assumed) to confirm table structure and the exact 12-construct/71-item breakdown from PRODUCT.md §11.1, then wrote `parseQuestionnaireDocx` to match it and throw rather than silently mis-parse if it doesn't. Verified three ways: unit tests against the real docx (71 unique items, correct construct counts, correct English/Hindi split), a real-data Excel-template check (`ER_mean`/`PC_mean` formulas reference the exact right column ranges), and a real browser upload-and-download via Playwright. Hit the same "brand-new major version breaks on this Mac's Node" pattern as WT-1's Vite issue — jsdom 30 requires Node ≥22.22, pinned to jsdom 26.1.0 instead. WT-2 is Done; WT-3 (grid + row anchoring spike) is next. |
| 2026-09-13 | **WT-1 deployed and verified in production.** Live at https://shruti9805.github.io/research-app/, confirmed via a real Playwright run against the production URL (same three checks pass, zero console errors). Getting there surfaced a real, non-obvious obstacle: pushing the GitHub Actions workflow file required a PAT with **both** `Contents` and `Workflows` write permissions (fine-grained tokens split these; having only one fails with a misleading error). Worked around by committing the workflow file separately from the app code and adding it through GitHub's web UI instead. Also hit a known first-deploy race (`Ensure GitHub Pages has been enabled`) — resolved by confirming Settings → Pages → Source is GitHub Actions, then re-running the workflow. WT-1 is fully Done; WT-2 is next. |
| 2026-09-13 | **WT-1 built and verified locally.** Vite+React+TS scaffold created; pinned Vite to 7.3.6 and TypeScript to ^7.0.2 after the default `npm create vite@latest` pulled Vite 8.3.0, whose new Rolldown bundler failed to load its native binding on this Mac (a known npm optional-dependency bug) — chose the mature Rollup/esbuild pipeline instead, same posture as DR-002. Built and verified, with real output at each step: Tesseract.js OCR (Node + real browser, both passed, 92–96% confidence), IndexedDB round-trip (browser), ExcelJS workbook with a live formula and a filled cell (Node round-trip + real browser download, both valid `.xlsx` files). Found and fixed one real CSS bug (`h1` line-height) caught via an actual Playwright screenshot, not just a successful build. Resolved the open testability question from DR-009: Tesseract.js and ExcelJS both run under plain Node/Vitest with no browser shim — WT-3's own Canvas-based grid detection still needs one, that question stays open for WT-3. Not yet deployed — a GitHub Actions → GitHub Pages workflow is written and ready, pending the user's go-ahead to commit/push. |
| 2026-09-13 | **DR-009 added — web stopgap track.** User cannot currently test mobile builds (no Mac/Xcode/Android SDK access in this session). Rather than replace the mobile plan, added a **parallel, paused-not-deleted** web track: plain TypeScript (Vite+React), not Flutter Web, because ML Kit — load-bearing for DR-003 and DR-006 — has no web build at all `[VERIFIED]`. Confirmed with the user: (1) stopgap, not replacement — DR-001 and DR-007 status changed to Paused; (2) plain TS/React over Flutter Web; (3) DR-006 handwriting recognition stands, with the heightened Tesseract.js-vs-Devanagari risk named explicitly; (4) deploy to a free static host (GitHub Pages/Netlify) rather than local-only. Library substitutions recorded in DR-009 (Tesseract.js, hand-written Canvas TS with OpenCV.js as an unverified fallback, mammoth.js, ExcelJS, IndexedDB). New §6.1 web-track (WT-1..WT-8) component table added, mirroring §6's risk-first order. Two new risks added to §7: Tesseract.js's weaker Devanagari-handwriting accuracy, and the accepted cost of eventually re-implementing the parser in Dart if the mobile track resumes. No code written yet — WT-1 is the next component, to be built and verified separately. |
