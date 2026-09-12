# Project context

Mobile app (Flutter, Android + iOS) that reads photographed paper questionnaires and writes
responses into Excel. Solo builder, zero budget, all processing on-device.

## Read these before doing anything

- `PLAN.md` — the approved plan, decision records DR-001..008, component status. **Start here.**
- `PRODUCT.md` — requirements, §11 findings measured from the samples, §14 settled decisions.
- `ONDEVICE-OPTIONS.md` — verified research on ML Kit and on-device processing.
- `.claude/skills/mobile-app-builder/SKILL.md` — the process. Use this skill.
- `samples/` — the real blank `.docx` and one real filled response. Every §11 finding came from
  these two files.

If `PLAN.md` shows a component in progress, you are resuming. Go to that component. Do not
restart the process.

## How to work here

**Build one component at a time, in the order in `PLAN.md` §6.** Finish it to the Definition of
Done before starting the next. Stop and report after each. Never begin component N+1 while N is
incomplete.

**Never proceed past an approval gate without explicit approval.** "Looks good, but…" is
feedback, not approval.

**Label every non-obvious factual claim** `[VERIFIED: source + date]`, `[INFERRED: reasoning]`,
or `[UNKNOWN]`. Version numbers, API signatures, platform policies and library capabilities are
never stable — check them, don't recall them. A library's installed `.dart` file is ground truth;
memory of its API is not.

**Paste real command output.** Don't describe what a command would do. If you haven't run it,
say so. Never mark something Done you haven't seen work.

**"I don't know" beats a confident guess.** A wrong fact caught now costs a message; caught in
week six it costs a rewrite.

**When reality contradicts the plan:** stop, say what you found with evidence, name the decision
record it affects, propose an amendment, get approval, then append to the `PLAN.md` changelog.
Never deviate silently — a plan that doesn't match the code is worse than no plan.

## Things that are settled — do not relitigate

| | |
|---|---|
| Framework | Flutter, stable channel (DR-001) |
| Image processing | Pure-Dart `image` package first; `opencv_core` only if Component 3 fails (DR-002) |
| Row anchoring | ML Kit Latin on the printed code column (DR-003) |
| Questionnaire input | `.docx` only. No OCR of blank forms (§14.3) |
| Response input | Combined PDF or a series of photos (§14.4) |
| Processing | Fully on-device. No cloud, no network calls (§14.5) |
| Demographics | Read from handwriting. User rejected manual entry (DR-006) |
| Identity | App-generated, device-prefixed: `A-0001`, `B-0001` (DR-008) |
| Duplicate detection | Not built. Operator prevents duplicates (DR-008) |
| Paper form | Cannot be changed in v1. No registration marks, no QR (§14.7) |

## Two properties this project depends on

**The parser must be a pure Dart library with no Flutter dependency.** It takes image bytes and
returns a structured result. This lets it run as a CLI on the Mac against `samples/`, which is the
difference between iterating in seconds and iterating in minutes. Do not couple it to widgets.

**Flagger recall matters more than accuracy.** 99% per-item accuracy across 71 items means ~51% of
responses carry at least one error (0.99^71 = 0.49). The user reviews only what the app flags, so
the number that protects the data is *what fraction of wrong values get flagged*. A missed flag
corrupts data invisibly; a false flag costs a glance. Optimise accordingly, and report both
numbers.

## Measurement is not optional

Form changes are unavailable in v1, so the tick bias and dot-versus-speck ambiguity must be
handled entirely in software. The only evidence the parser is safe for real research data is
Component 4's numbers against a hand-labelled sample.

Report accuracy **separately for marks and handwriting, and separately for ticks and dots**. An
aggregate figure hides a rightward tick bias behind good dot performance, and weak Devanagari
behind strong mark detection.

If a target isn't reachable, report the real number. Do not tune the flagger down to make the
accuracy look better.

## Known trap

Checkmarks overflow rightward — the stroke crosses into the next column while the vertex stays in
the intended one. A centroid or max-ink detector biases answers toward "Agree" systematically,
invisibly, across every response. Anchor by mark type (DR-004).
