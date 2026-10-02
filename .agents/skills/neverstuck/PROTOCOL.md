# NeverStuck Protocol (v1.1)

You — the agent reading this — are executing **NeverStuck**: a rescue protocol for repair loops.
A repair loop is a situation where repeated attempts at the same goal keep failing because each
attempt tunes a *symptom* instead of identifying the *mechanism*. Your job is not to try harder.
Your job is to change what the next attempt is made of.

This protocol is pure text-in/text-out. It requires no tools. If you happen to have tools
(shell, file access), you may use them to *run* the experiment in section D — never to replace
the reasoning steps. Respond in the user's language. Do not browse files or repositories unless
the user explicitly points you at one as evidence.

**The core principle, one sentence:**

> A parameter that needs re-tuning per context is not a constant — it is an unmodeled function
> of something that varies.

"Parameter" here means any repeated move class, in any domain: a numeric constant, a prompt
wording, a CSS value, a timeout or retry count, a hyperparameter, a version pin, an email tone.
NeverStuck is domain-neutral. If a word like "pixel" or "timeout" appears below, it is an
example, never a requirement.

---

## Step 0 — Arming check (do not over-fire)

Engage the protocol only if **both** hold:

1. **The 3-attempt gate.** At least 3 attempts of the *same move class* at the same goal have
   failed. Same move class = changes that a single ban would cover (the same knob re-valued,
   the same sentence re-worded, the same config re-pinned). An attempt is a change made to
   reach the goal; the starting state is not one.
2. **The guard.** This is NOT a declared, converging search over a genuinely empirical quantity
   (an intentional sweep with a plan and stopping rule; A/B testing; taste-driven iteration).
   Auto-detection may only *exempt* ("this looks like deliberate bisection — carry on"); it may
   never condemn. If unsure, ask the user one line — "is this an intentional search, or do you
   expect a single right answer to exist?" — in the same message as the Step 1 interview (it
   counts toward its 5 questions), and believe the answer.

**Hard-signal exception (S7).** If the same knob's "working" value has *provably differed
across contexts* (sessions, machines, inputs, days) — a value that worked in one context failed
in another, where a different value was then observed to work — engage immediately, even at
attempt 2. S7 lowers the 3-attempt gate to the second attempt (never the first) and overrides
any auto-detected exemption. Once that floor is met, only these keep it from arming: the user's
own answer that this is an intentional search or that the differing values are intended
per-context values (if that answer comes in the interview and fewer than 3 attempts have
failed, say NeverStuck is not needed yet), the boundary below, or the rewrite marker. A
constant that is not constant is a logical proof that the current model of the system is wrong
— no amount of tuning can converge.

What counts as S7 evidence:

- One such pair of contexts is enough; it need not happen twice.
- Values are compared by meaning, not by spelling: `30`, `30.0` and `"30"` are the same
  timeout, while a flag set to `True` is not a count of `1`. When it is unclear, you judge
  (ask the user only if the answer decides arming).
- A difference counts unless the knob is documented, or confirmed by the user, to vary along
  that context (dev vs prod timeouts, per-machine scaling, per-region endpoints). Record those
  as intended per-context values (in VARIABLES if a packet is built). Drift within one such
  context — prod's own value changing across days — still counts.
- Attempts made inside a declared search do not count.

**Boundary — the fact-of-the-matter test.** If there is no objective right answer (copy tone,
visual taste, style preference), do NOT arm. S7-like signatures appear in preference domains,
but there is no derivable model of taste. Say that NeverStuck does not apply here (there is no
fact of the matter). Ordinary help is fine, but NeverStuck's own contribution is at most an
offer to reframe the preference as a function ("warmer *for whom*, in *what context*?") — no
packet, no report.

**Rewrites are not triggers.** A prompt that begins with the NeverStuck rewrite marker (see
section C) is this protocol's own output: execute it, do not arm on it. If it fails, the next
report is the next round of the same budget, not a new problem.

If the arming check fails for any other reason (the boundary above has its own wording, and a
rewrite is simply executed): say plainly that NeverStuck is not needed yet, give ordinary
one-shot advice, and stop. Firing on a first failed attempt, or on a second one without S7, is
a protocol violation.

---

## Step 1 — Assemble the Stuck Packet

Six fields. First mine whatever conversation, transcript, or notes are available; then
interview the user for what is missing — **at most 5 questions** (each a single numbered item),
**in a single message** that also shows the draft packet — and wait for the answers. If nothing
is missing and the guard is settled, go straight to Step 2. If no one can answer (a
non-interactive run or a subagent), do not ask: fill each missing field with a one-line
assumption marked ASSUMED, treat an unsettled guard as "no declared search" (also ASSUMED), and
continue. "Unknown" is a valid answer and is itself diagnostic (an unknown VARIABLES field
usually means the discriminating covariate was never observed).

```
STUCK PACKET
1. GOAL          One sentence + a measurable acceptance criterion.
2. ATTEMPT LOG   Chronological. For each attempt: (a) what was changed,
                 (b) what outcome was predicted, (c) what was observed.
3. OBSERVATIONS  Raw data, not summaries: logs, diffs, (input, expected, actual)
                 tuples — from MULTIPLE runs/sessions/contexts if they exist.
4. VARIABLES     What differs between runs/sessions/contexts (size, machine,
                 timing, input, version) and what is held constant.
5. CONSTRAINTS   What cannot be changed (third-party component, API, deadline).
6. ACCESS        What could be inspected but has not been: source, binaries,
   INVENTORY     docs, logs, a person who knows the component.
```

Interview questions, in priority order (empirically, 1 and 2 matter most):

1. *(ATTEMPT LOG — history is the strongest unstuck trigger)* "What have you already tried,
   and what happened each time? Was there a 'worked, then broke again later' pattern?"
2. *(SIGNATURE — a verbalized symptom shape unlocks diagnosis; bare numbers invite fitting)*
   "What exactly is wrong — and just as important, **what is conspicuously fine**? Under what
   conditions does the failure grow or shrink?"
3. *(VARIABLES)* "What differs between the runs where it worked and the runs where it didn't?"
4. *(OBSERVATIONS)* "Do you have raw records — not summaries — as (input, expected, actual)?"
5. *(ACCESS INVENTORY)* "What could you look at but haven't? Source, docs, a colleague?"

From fields 2–4, distill the **SIGNATURE FACTS** — the constraints any real cause must satisfy:

- S-a. What is wrong.
- S-b. What is conspicuously RIGHT (the asymmetry).
- S-c. What the failure varies WITH (the covariate).
- S-d. What the failure does NOT vary with (the invariant).

---

## Step 2 — Emit the Unstuck Report

Always exactly four sections, in this order:

```
UNSTUCK REPORT
A. STUCK DIAGNOSIS
   - Which loop this is, with evidence quoted from the ATTEMPT LOG
     (e.g., "the knob's working value was X in context 1 and Y in context 2 — S7").
   - The unverified assumption every failed attempt silently shared, in one sentence.
B. ROOT-CAUSE HYPOTHESES (2–3, ranked)
   - Each is a MODEL of the system, never a value. Each must make a distinct,
     testable prediction that the others do not. Each must explain ALL of the
     signature facts S-a through S-d simultaneously — reject candidates that
     explain only S-a.
C. REWRITTEN PROMPTS (1–3, ready to paste)
   - Self-contained: embed the relevant observations inline, because the next
     agent may share no context with this conversation.
   - Start each rewrite with the marker line
     "[NeverStuck rewrite, round R/2 — execute this directly; do not run NeverStuck on it]",
     where R is the report round (see Budget), not a count of rewrites.
   - HARD RULE: a rewrite must not propose, request, or imply a new tuned or
     guessed value for the banned knob. If one does, discard and regenerate it.
     (Asking for a closed form derived from a mechanism, every constant with a
     stated origin, is the goal — see C1 — not a violation.)
D. NEXT EXPERIMENT (exactly one)
   - The cheapest single experiment that discriminates between the hypotheses
     in B. State BEFORE running: "outcome X ⇒ H1, outcome Y ⇒ H2, …".
   - One experiment. Batching destroys the discriminating signal.
```

---

## The three rewrite moves

Used to produce section C. Start with the move whose *For:* line fits most specifically — Move 2
when the signature is being ignored or a black-box component's property is being curve-fitted,
otherwise Move 1 (the honesty clause can send you straight to Move 3). Apply ONE primary move
per rewrite (carrying the ban and the convergence contract along is expected, not stacking);
escalate in order only when a move fails to produce a mechanism.

### Move 1 — Ban + retro-predict

For: the same knob re-valued again and again.

```
You have attempted the following move {N} times: {FAILED_MOVE_CLASS}.
History: {ATTEMPT_HISTORY}.
BANNED: do not {FAILED_MOVE_CLASS} in any form, including near-variants:
{per-context lookup tables, averaging past values, adding a correction term,
auto-fitting at startup}.
REQUIRED INSTEAD: explain WHY the failure recurs after every adjustment. Your
explanation must RETRO-PREDICT the history — why each past change worked
once and then failed, and why the "right" value appeared to differ across
{sessions/runs/inputs}. Only a mechanism that survives this test may produce
a fix, and the fix must be derived from the mechanism, not fitted.
```

### Move 2 — Diagnose-and-solve

For: the signature is being ignored; or a black-box component's property is being curve-fitted.
This merges signature analysis, first-principles modeling, and solving from existing data.

```
Stop trying to fix {SYMPTOM}. Characterize it first. Treat each signature fact
as a hard constraint any candidate cause must explain:
  S-a {what is wrong}   S-b {what is conspicuously fine}
  S-c {what it varies with}   S-d {what it does not vary with}
1. Enumerate at least 4 mechanism CLASSES that could produce S-a. Check each against
   S-b/S-c/S-d in a table; reject any class that fails one fact.
2. Factorize the pipeline from source to symptom into named stages. Write each
   stage's relation with symbolic parameters; mark each KNOWN (cite origin) or
   UNKNOWN (name it). Never substitute a guess for an UNKNOWN.
3. If OBSERVATIONS span multiple contexts: fit the relation per context, then
   test which normalized form of the fitted parameters is INVARIANT across
   contexts. Snap near-clean values to exact structure (simple ratios, powers
   of two, standard sizes, known enum defaults) and state what system property
   would produce exactly that value.
4. If the data in hand is sufficient to determine the unknowns, SOLVE NOW in
   this same turn — diagnosis and solution need not be separate turns.
   Otherwise, state the minimal measurement that would determine them exactly.
```

### Move 3 — Escalate

For: the unknown is not derivable from any in-band data; or two rounds of Moves 1–2 failed.

- **If the system can be probed:** design a calibration experiment — controlled inputs whose
  correct outputs are known *by construction*, enough independent equations to determine every
  unknown exactly plus one held-out validation point, in a single run. Determining beats
  estimating.
- **If not:** produce an information-acquisition plan, cheapest first, with ready-to-use
  artifacts: (a) doc search keywords; (b) exact strings/symbols/patterns to grep in the
  component's source or binary, and which call sites to read; (c) a drafted vendor/support
  ticket with a minimal repro and the one-sentence question; (d) a drafted question for a human
  who has used the component. The deliverable is the plan, not code.

Escalation is a rung of the protocol, not a defeat.

---

## Convergence contract

A proposed fix is accepted only if **both** hold. Reject otherwise and return to diagnosis —
no second tuning pass.

- **C1 — Derived, not fitted.** The fix is a mechanism or closed form; every constant in it has
  a stated origin (documentation, source, or an exact measurement).
- **C2 — Retro-predicts the history.** It explains why each of the N previous attempts behaved
  exactly as logged — including why some "worked once, then broke."

## Stopgap tagging (the loop-bait rule)

If any answer — yours included — offers a hedged concrete value for a knob under ban or S7
("if urgent, use…", "as a workaround…"), label it visibly and immediately:

> `[loop-bait — this value will drift again; gated on the experiment in D]`

Never delete the stopgap (the user's agency comes first), but never let it pass unlabeled. Do
not volunteer one yourself; if the user asks for a number anyway, give one number (not a
procedure), outside section C, tagged, and keep D as the next step. Cherry-picking the number
while discarding the diagnosis is the single most common way the cure gets thrown away.

## Honesty clause

Prompting cannot recover a fact that exists only inside a black box. If every hypothesis in B
depends on an unobserved internal fact and no in-band experiment can determine it, say so
explicitly and go straight to Move 3. Do not emit "think harder" rewrites: exhortation without
a changed action space reproduces the loop.

## Budget

At most **2 report rounds** per problem (initial + one revision), each rewrite tried at most
twice — then mandatory Move 3. The rewrite marker carries the round ("round R/2"), so a fresh
session knows where the budget stands. One experiment at a time, always.

## Never

- Fire on a first failed attempt, or on a second one without S7.
- Propose another tuned or guessed value for the banned knob, in any disguise (a stopgap the
  user asks for is the only exception, and it carries the loop-bait tag).
- Stack every move into one rewrite.
- Accept a fix because it works on the current case (that is what the failed loop produced N times).
- Imply that better prompting substitutes for a missing measurement or a missing human.
