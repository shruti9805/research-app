# Prompts

Copy-paste prompts for running the build. Stage 1 is complete — `PLAN.md` exists and is approved.
**Component 1 is next.**

## Where things live

```
research-app/
├── .claude/skills/mobile-app-builder/SKILL.md   the process
├── CLAUDE.md                                    persistent project context
├── PRODUCT.md                                   what to build — yours
├── ONDEVICE-OPTIONS.md                          verified tech research
├── PLAN.md                                      the approved plan + current status
├── KICKOFF.md                                   this file
├── setup.sh                                     Component 1 scaffold script
├── lib_main.dart                                Component 1 source (UNCOMPILED draft)
├── questionnaire_output.xlsx                    Component 2 target
├── samples/                                     the .docx and the filled .pdf
└── app/                                         created by setup.sh
```

Open Claude Code **in the repo root**, not in `app/`. It needs to read the docs.

---

## 1. Component 1 — walking skeleton

First message in a new Claude Code session:

```
Read PRODUCT.md, ONDEVICE-OPTIONS.md and PLAN.md, then use the
mobile-app-builder skill.

APPROVED — Stage 1. Begin Stage 2 with Component 1 only: the walking
skeleton.

Starting point: setup.sh and lib_main.dart are in the repo root. They
were written without a Flutter SDK available and have never been
compiled. Treat them as a draft, not as correct. Before relying on any
API in them, check it against the installed package source in
app/.dart_tool or the pubspec-resolved version — the installed .dart
files are ground truth, the draft is not. Fix whatever is wrong and
say what you changed.

Component 1 is done only when all of these hold:
- flutter build apk --release succeeds from a clean checkout
- the APK installs on a real Android device and all four health checks
  pass on screen
- flutter build ipa succeeds
- flutter analyze is clean
- DR-007's [UNKNOWN] has a written answer in PLAN.md: can an IPA be
  installed on another person's iPhone without a paid Apple Developer
  account? Verify against current Apple documentation and record the
  source URL and the date you checked it.
- PLAN.md status updated and the work committed

Evidence rules apply. Paste the actual output of every command you run
rather than describing it. If you have not run something, say so
plainly. Do not mark anything Done that you have not seen work.

Then stop and report: what was built, what you verified and how, what
you did NOT verify, anything you learned that changes the remaining
plan, and what is next. Do not start Component 2.
```

**Why the draft warning is in there.** Uncompiled code that reads confidently is the easiest thing
to build on top of without checking, and one wrong API signature propagates through everything
after it.

---

## 2. Between components

```
APPROVED — Component <n>. Proceed to Component <n+1>. Same loop:
verify assumptions against installed sources first, build to the
Definition of Done, update PLAN.md, then stop and report.
```

---

## 3. Resuming in a new session

Context doesn't persist between sessions. The files do — that is the whole reason the plan lives
on disk.

```
Read PRODUCT.md, ONDEVICE-OPTIONS.md and PLAN.md, then use the
mobile-app-builder skill. Tell me where we are and what's next.
Don't start work until I confirm.
```

---

## 4. Component-specific additions

Append these to the standard "proceed to Component n" prompt when you reach them.

**Component 2 — docx → questionnaire model → Excel**

```
questionnaire_output.xlsx in the repo root is the verified target. It
was generated from the real samples/Student_Survey_Bilingual.docx and
its formulas were checked against hand-calculated construct means.

Match it exactly: 10 columns, one row per question (8 demographic + 71
items = 79 rows per response), question text in both languages, a
single answer column holding 1-5 for Likert items and text for
demographics, and blank reasons written into that same answer column.

This is a matching exercise, not a design one. Verify by generating a
workbook and diffing it against the target.
```

**Component 3 — grid + row anchoring spike**

```
Build this as a plain Dart command-line program first, runnable on the
Mac against samples/ — not inside the app. Iterating a parser through
a phone rebuild is the difference between seconds and minutes.

Output a rendered overlay image showing detected grid lines and row
anchors so the result can be eyeballed, plus code-column recall as a
number.

This resolves DR-002 and DR-003. If projection profiles can't find the
grid reliably on the real pages, say so plainly and propose the
opencv_core fallback rather than tuning until it looks acceptable.
```

**Component 4 — mark detection + measurement harness**

```
This is the component that decides whether the product works.

Hand-label ground truth for all 71x6 sample cells and the four text
fields. Report accuracy, flagger recall, and signed column-error mean
SEPARATELY for marks and for handwriting, and separately for ticks and
for dots. An aggregate number would hide a rightward tick bias behind
good dot performance, and hide weak Devanagari behind strong mark
detection.

Report the real numbers. If 99% is not reachable, say so and give me
the actual figure and the actual flag rate. Do not tune the flagger
down to make the accuracy look better.
```

---

## 5. Prompts worth having on hand

**When a claim feels too smooth**

```
Go back through that and label every factual claim [VERIFIED] with a
source and date, [INFERRED], or [UNKNOWN]. Anything you can't source,
say so.
```

**When a recommendation feels like a default rather than a conclusion**

```
Argue the strongest case for the option you rejected. If it's genuinely
weaker that'll be obvious — and if it isn't, I want to know now.
```

**When "done" arrives suspiciously fast**

```
Walk me through the Definition of Done item by item. For each, show me
the actual command output. What did you not verify?
```

**Before a plan change hardens**

```
Which decision record does this affect, and has its "what would change
this" condition triggered? Propose the amendment and the changelog
entry before you write any code.
```

---

## 6. Two habits worth keeping

**Spot-check the verification.** Open three `[VERIFIED]` links and confirm they say what's
claimed. If they hold up, the rest probably does. The labels exist to make errors findable, and
that only works if someone occasionally looks.

**Insist on measurement over argument.** Form changes are unavailable in v1, so the tick bias and
the dot ambiguity have to be handled entirely in software. The only evidence the parser is safe
for real research data is Component 4's numbers against a hand-labelled sample. A plan step that
produces a paragraph instead of a number hasn't been done.
