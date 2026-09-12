# Setup and prompts

## Where each piece lives

```
your-app/
├── .claude/
│   └── skills/
│       └── mobile-app-builder/
│           └── SKILL.md          ← the process. Stable, rarely edited.
├── PRODUCT.md                    ← what you want. You write this.
├── PLAN.md                       ← created by Claude at Stage 1, updated continuously.
└── src/                          ← the app, from Stage 2 onward.
```

The split matters. The skill is *how to work* and shouldn't change between projects. `PRODUCT.md` is *what to build* and is yours. `PLAN.md` is *current state* and belongs to Claude. Collapsing these into one prompt means re-pasting everything every session and watching the app description drift as you edit it in-place.

**Setup:**

1. `mkdir -p .claude/skills/mobile-app-builder` and put `SKILL.md` there.
2. Copy `PRODUCT.md` to your project root and fill it in. Spend real time here — it's the highest-leverage hour in the project.
3. `git init` if you haven't. The staged process depends on commits as checkpoints.

---

## Kickoff prompt

Paste this once, at the start:

```
Read PRODUCT.md and ONDEVICE-OPTIONS.md, then use the mobile-app-builder skill.

The decisions in PRODUCT.md §14 are settled — treat them as constraints, not
suggestions. The findings in §11 were measured from the two sample files in
samples/; don't re-derive them from memory, and don't generalise beyond what a
single filled response can support.

Stage 0: ask me anything in §12 I haven't answered, all at once.

Stage 1: produce PLAN.md.

Apply the evidence rules strictly. Every version number, library capability, API
signature and platform policy claim gets verified against official docs or a
command you actually ran, with source and date. Anything unverifiable gets
labelled [INFERRED] or [UNKNOWN] — I would much rather see "I don't know" than a
confident guess I discover is wrong in week four.

For each technology decision, write the criteria before you look at the options,
evaluate the candidates you expect to lose, and tell me what we give up and what
would make this the wrong call.

The plan must include a measurement step: parse accuracy on a hand-labelled
sample of real responses, reported per mark type, demonstrating that residual
error is not directionally biased. Form changes are unavailable in v1, so this
test is the only evidence the parser is safe for research data.

Do not write any code, create any scaffold, or install anything until I approve
the plan. Stop after presenting it.
```

## Approval

When the plan is right:

```
APPROVED — Stage 1. Begin Stage 2 with component 1 only.
Build it to the Definition of Done, update PLAN.md, then stop and report.
```

If it isn't right, say what's wrong. The skill treats anything short of clear approval as feedback, so "looks good, but I'm not sure about the state management" will get you a revision rather than a build.

## Between components

```
APPROVED — component <n> looks good. Proceed to component <n+1>. Same loop:
verify assumptions first, build to Done, update PLAN.md, stop and report.
```

## Resuming in a new session

Context doesn't persist, but the files do. This is the whole reason the plan lives on disk:

```
Read PRODUCT.md, ONDEVICE-OPTIONS.md and PLAN.md, then use the
mobile-app-builder skill. Tell me where we are and what's next.
Don't start work until I confirm.
```

---

## Prompts worth having on hand

**When a claim feels too smooth:**
```
Go back through that and label every factual claim [VERIFIED] with a source and
date, [INFERRED], or [UNKNOWN]. Anything you can't source, say so.
```

**When a recommendation feels like a default rather than a conclusion:**
```
Argue the strongest case for the option you rejected. If it's genuinely weaker,
that'll be obvious — and if it isn't, I want to know that now.
```

**When "done" arrives suspiciously fast:**
```
Walk me through the Definition of Done item by item. For each, show me the actual
command output. What did you not verify?
```

**Before the plan hardens:**
```
What's most likely to make this plan wrong by week three? Rank the risks by how
expensive they'd be to fix late, not by how likely they are.
```

---

## Honest note on hallucination

No prompt makes a model incapable of being wrong. What this setup does is narrower and more useful: it forces every claim to carry a source, so wrong claims become *checkable* rather than invisible. The failure mode you're defending against isn't really "the model states a falsehood" — it's "the model states a falsehood in a register indistinguishable from a verified fact." Labeling separates those two, and the labeling is worth spot-checking. If you check three `[VERIFIED]` sources and they're real and say what they're claimed to say, the rest is probably fine. If one is fabricated, stop and re-verify the plan.

The other real defense is the gates. A wrong fact caught at Stage 1 costs a conversation. The same fact caught in Stage 3 costs a rewrite.
