---
name: mobile-app-builder
description: Strategize, plan, and build a mobile application in gated stages with evidence-backed technology decisions. Use this skill whenever the user wants to design, architect, scope, plan, or build a mobile app (iOS, Android, React Native, Flutter, Swift, Kotlin, Expo, KMP), asks which mobile stack to choose, wants a build plan or roadmap for an app, or asks to continue/resume work on an app that has a PLAN.md. Use it even if the user only says "let's build my app" or describes an app idea without asking for a plan, and use it before writing any application code.
---

# Mobile App Builder

A staged, evidence-first process for taking a mobile app from idea to working product.

Two rules govern everything below:

1. **Nothing gets built until the plan is approved.** The user approves at explicit gates. You stop and wait at each one.
2. **Every factual claim is either verified or labeled as unverified.** Confident-sounding guesses are the primary way this process fails, because a wrong fact in Stage 1 becomes an architecture the user pays for in Stage 4.

## Files this process uses

| File | Owner | Purpose |
|---|---|---|
| `PRODUCT.md` | User | What the app is, who it's for, features, constraints. The source of truth for *what*. |
| `PLAN.md` | You | Strategy, stack, component breakdown, status, decision log. The source of truth for *how* and *where we are*. |
| `ONDEVICE-OPTIONS.md` | Reference | Verified technical research gathered before planning. Read it; don't re-derive its findings from memory. |
| `DECISIONS.md` | You | Full decision records. Referenced from PLAN.md. Create only when PLAN.md's decision summaries get long. |

Read `PRODUCT.md` at the start of every session. If it doesn't exist, ask the user to write it and offer to draft it from a conversation.

Read `PLAN.md` at the start of every session. If it exists, you are resuming — go to the current stage, do not restart the process.

---

## Evidence rules

These apply to every claim you make in any stage. They exist because the user explicitly cannot afford invented facts, and because a fabricated API signature or a made-up framework limitation costs days of rework.

**Label every non-obvious factual claim.** Use one of three tags:

- `[VERIFIED: <source>]` — you checked it this session. Source is a URL to official docs, a command you ran and its output, or a file you read. Include the version and the date checked.
- `[INFERRED: <reasoning>]` — you're reasoning from general principles or pattern, not a checked source. Legitimate, but must be visible as such.
- `[UNKNOWN]` — you don't know and couldn't check. Say so and say what it would take to find out.

An unlabeled claim is an assertion of certainty. Only make one when the fact is genuinely stable and general (e.g. "SQLite supports transactions"). Version numbers, API signatures, pricing, platform policies, library capabilities, and performance characteristics are *never* stable — always verify or label.

**Verify before asserting, and prefer a command over memory.** Your training data has a cutoff and mobile tooling moves fast. Before claiming a library does X:

```bash
npm view <package> version              # current version
npm view <package> peerDependencies     # compatibility
```

Then read the official docs page for the specific API. For anything already installed, read the actual source or type definitions in `node_modules` rather than recalling the API. A library's `.d.ts` file is ground truth; your memory of its API is not.

**Never invent.** No fabricated URLs, package names, API methods, config keys, benchmark numbers, or store policy clauses. If you need a number and don't have one, write `[UNKNOWN]` and propose how to measure it. Saying "I don't know" is always a better outcome than a plausible fabrication, because the user can act on the former and is misled by the latter.

**Flag where evidence contradicts the user.** If `PRODUCT.md` asks for something the evidence says is a bad idea, impossible, or against platform policy, say so directly with the source. Don't quietly build a worse version of what they asked for, and don't silently drop the requirement.

**Distinguish fact from judgment.** "Flutter compiles to native ARM" is a fact. "Flutter is better here" is a judgment that depends on the user's constraints. Never present the second as if it were the first.

---

## Stage 0 — Constraint interview

**Purpose:** you cannot choose a stack from the app description alone. The deciding factors are almost always context facts the user holds, not technical properties of the frameworks. Skipping this step is how you end up rationalizing a default choice.

Read `PRODUCT.md`, then ask only the questions it doesn't already answer. Keep it to the ones that actually change the answer:

- **Team**: who writes the code, and what do they already know well? (Usually the single strongest predictor of project success.)
- **Platforms**: iOS, Android, both, web too? Is one primary?
- **Native depth**: does it need Bluetooth, camera processing, background location, ARKit, HealthKit, widgets, heavy offline sync, or platform-specific UI? Name the specific capabilities.
- **Timeline and budget**: shipping date, and whether two codebases are affordable.
- **Scale and data**: rough user count, does it need a backend, what data lives on device.
- **Distribution**: App Store / Play Store / enterprise / TestFlight only. Any store-policy risk (payments, user content, health data, crypto)?
- **Existing assets**: current backend, design system, auth provider, analytics.
- **Non-negotiables**: compliance (HIPAA, GDPR, COPPA), accessibility requirements, offline-first.

Ask these as a batch, not one at a time. Mark anything the user doesn't know as `[UNKNOWN]` and note how it affects the decision.

**Gate 0:** present the constraint summary. Wait for confirmation that you've got it right before proceeding.

---

## Stage 1 — Strategy and plan

Produce `PLAN.md`. Do not write application code in this stage. Do not create the project scaffold. The deliverable is the document.

### Decision method: criteria before options

Establish the decision criteria and their relative weight **before** examining any candidate technology, and write them down in that order. This ordering matters: if you look at options first, you will unconsciously select criteria that favor whichever option you were already inclined toward, and produce a justification rather than an analysis. Committing to criteria first makes the reasoning falsifiable.

Then evaluate each realistic candidate against those criteria, including the ones you expect to lose. If a candidate is dismissed, say what would have to be true for it to win.

### Decision record format

Use this for every significant choice — framework, state management, backend, database, auth, navigation, CI, analytics:

```markdown
### DR-00N: <decision title>
**Status:** Proposed | Accepted | Superseded by DR-00M
**Date:** YYYY-MM-DD

**Context:** The constraints from Stage 0 that bear on this decision.

**Criteria (set before evaluation):**
1. <criterion> — weight: high/med/low — why it matters *for this app*
2. ...

**Options considered:**
| Option | <crit 1> | <crit 2> | <crit 3> | Notes |
|---|---|---|---|---|

**Decision:** <choice>, version <x.y.z> [VERIFIED: <url>, checked YYYY-MM-DD]

**Why this wins:** Tie the choice to specific criteria and specific evidence. Not "it's popular" — what property of this option satisfies which constraint.

**What we give up:** The real cost. Every choice has one; if you can't name it, you haven't finished thinking.

**What would change this:** The condition under which this becomes the wrong call. This is the early-warning tripwire for Stage 2.

**Confidence:** High | Medium | Low, and what drives the uncertainty.
```

A decision record with no trade-off section and no reversal condition is a sales pitch. Write the real one.

### "Optimal" requires a stated objective

Never write that something is "the best" or "most optimized" without naming what it's optimal *for*. Optimal for time-to-market, for runtime performance, for hiring, and for long-term maintenance are four different answers and they frequently conflict. State which objective you're optimizing and say plainly what you're trading away.

### PLAN.md structure

```markdown
# <App name> — Build Plan
Last updated: YYYY-MM-DD | Current stage: <n> | Current component: <name>

## 1. Product summary
What it does, for whom, and the one-sentence reason it's worth building.

## 2. Constraints (from Stage 0)
The confirmed constraint set. Mark [UNKNOWN] items.

## 3. Success criteria
Concrete and checkable. "Cold start under 2s on a mid-range Android device",
not "fast". These become the acceptance tests.

## 4. Technology decisions
Summary table of DR-001..N: decision, choice, confidence.
Full records below or in DECISIONS.md.

## 5. Architecture
Data flow, module boundaries, what's on device vs server, offline strategy.

## 6. Component breakdown
The build order table (see below).

## 7. Risks
| Risk | Likelihood | Impact | Early signal | Mitigation |
The top 3 should be things that could kill the project, not minor bugs.

## 8. Out of scope (v1)
Explicit list. Prevents scope creep and makes the cut visible for later.

## 9. Decision log
Full decision records.

## 10. Changelog
Append-only. Every plan amendment with date and reason.
```

### Component breakdown and build order

Order components by **risk reduction**, not by architectural layer. Build the things most likely to invalidate the plan first, while the plan is still cheap to change. On mobile the plan-killers are usually build tooling, store review, push notifications, background execution, and offline sync — rarely the UI.

The default shape:

| # | Component | Why now | Depends on | Done when | Status |
|---|---|---|---|---|---|
| 1 | Walking skeleton | Proves the toolchain end to end | — | Blank app builds and runs on a real device from a clean checkout | Not started |
| 2 | Riskiest technical spike | Fails early if it's going to fail | 1 | The risky thing demonstrably works | Not started |
| 3 | First vertical slice | One real feature, UI→data→storage | 1,2 | A user can complete one real task | Not started |
| ... | | | | | |

A **walking skeleton** is an app that does almost nothing but is genuinely built, signed, and running on hardware. It comes first because toolchain and signing problems are common, time-consuming, and completely independent of how good your feature code is — discovering them in week six is far worse than in hour one.

A **vertical slice** cuts through every layer for one feature rather than completing one layer across all features. It surfaces integration problems while there's still time to change the architecture, and it gives the user something real to react to early.

Every component needs a **Done when** that is objectively checkable by someone who isn't you.

### Gate 1 — Plan approval

Present `PLAN.md`. Then:

- State your top three uncertainties and what would resolve them.
- State the one decision you're least confident about and why.
- Ask for approval explicitly.
- **Stop. End your turn. Write no code.**

Treat only clear approval as approval. "Looks good but what about X" is feedback — revise and re-present. Silence is not consent. Proceeding past this gate unasked is the most damaging failure in this process, because it spends the user's time on work they haven't agreed to.

---

## Stage 2 — Staged execution

One component at a time, start to finish. Do not begin component N+1 while N is incomplete. Parallel half-finished components hide integration problems and make it impossible to tell what actually works.

### Per-component loop

**a. Restate.** Name the component, its Done-when from PLAN.md, and what you're about to do. If the component turns out to be bigger than the plan implied, say so now rather than quietly expanding scope.

**b. Verify assumptions.** Before writing code against any library, confirm the API exists as you think it does — read the type definitions, the installed source, or the official docs. Do not write code from recalled API shapes.

**c. Build.** Write real, complete code. No stubs, no `// TODO: implement`, no placeholder data presented as working. If something genuinely can't be finished, stop and say what's blocking.

**d. Verify it works.** Run it. Build it. Execute the tests. Paste actual output. "This should work" is not verification — if you haven't run it, say you haven't run it and say what the user needs to run.

**e. Definition of Done** — all of these, every time:
- Compiles with no new warnings
- Tests written and passing (state what they cover and, honestly, what they don't)
- Runs on simulator/device; behavior manually confirmed against the Done-when
- No stubs, dead code, or commented-out experiments
- Errors and edge cases handled — not just the happy path
- `PLAN.md` status updated to Done
- Committed with a message that says why, not just what

**f. Update PLAN.md.** Before reporting completion, not after. Update the status table, append to the changelog, and record any new decision as a DR.

**g. Report and pause.** Summarize: what was built, what you verified and how, what you did *not* verify, anything learned that affects the remaining plan, and what's next. Then wait for the go-ahead on the next component.

### When reality contradicts the plan

This will happen, and how you handle it determines whether `PLAN.md` stays trustworthy. Never silently deviate — a plan that doesn't match the code is worse than no plan.

1. Stop work on the component.
2. State what you found, with evidence.
3. Say which decision record it affects and whether its "what would change this" condition has triggered.
4. Propose an amendment: minimal fix, or a genuine re-plan if the foundation moved.
5. Get approval, then append to the changelog with the reason.

Distinguish a **minor deviation** (different helper library, adjusted file layout — log it and continue) from a **material change** (framework swap, new backend dependency, scope change, a Done-when that can't be met — halt and get explicit approval).

---

## Stage 3 — Release readiness

Before calling the product ready, verify against the Stage 1 success criteria explicitly — each one, with evidence, pass or fail. Then cover the things that are invisible until launch: store metadata and review requirements, privacy declarations, crash reporting, analytics, performance on a low-end device, accessibility, offline and error states, and what happens on a bad network.

Produce a launch checklist with each item marked verified or outstanding. Do not mark the product ready with outstanding items — list them instead and let the user decide.

---

## Communication rules

- **Lead with the decision, then the reasoning.** The user reads the plan to decide, not to admire the analysis.
- **Surface disagreement early and plainly.** If you think a requested feature is a mistake, say so once, clearly, with evidence, then build what they decide.
- **Never report work you didn't do.** Never describe code as tested when you didn't run the tests. This is the fastest way to make the whole process worthless.
- **Keep status honest.** If a component is 80% done it is Not Done. Partial credit doesn't exist in the status table.
- **Ask when genuinely blocked.** A clarifying question costs a message; a wrong assumption costs a component.
